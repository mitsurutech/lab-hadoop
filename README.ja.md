# Docker Compose で動かす Hadoop HDFS と MapReduce のラボ：HDFS にファイルを置き、自分専用のコピーで単語を数える

[English](README.md) | [Français](README.fr.md) | [日本語](README.ja.md) | [Español](README.es.md)

[![check](https://github.com/mitsurutech/lab-hadoop/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-hadoop/actions/workflows/check.yml)

授業でそのまま使える **Hadoop ラボ**です。学校や学校法人が、生徒一人ひとりにデータベース、コンテナー、ブラウザー上のターミナルを用意できる [MitsuruTech ラーニングプラットフォーム](https://mitsurutech.co.uk/ja/learning)から提供しています。生徒はそれぞれ、小さな専用の **Hadoop クラスター**を使います。分散ファイルシステムの **HDFS**（NameNode と DataNode）と、**MapReduce** のジョブを動かす **YARN**（ResourceManager と NodeManager）です。生徒は **HDFS にファイルを置き、一覧を表示し、読み戻して、付属の単語カウントを実行**します。操作は `curl` による HTTP と、NameNode 自身の Web ページで行います。データ、クラウド、分散システムの単元で、ビッグデータの保存と処理を初めて体験するのに向いています。何もインストールする必要がなく、誰かのマシンに影響が及ぶこともありません。

ファイルは `docker-compose` ファイル 1 つ、`compose.yaml` だけです。自分のマシンでもプラットフォームでも同じように動きます。プラットフォームでは、生徒ごとに専用のコピーが用意され、インターネットへの出口はありません。

## 中身

| サービス | イメージ | メモリ | 役割 |
| --- | --- | --- | --- |
| `namenode` | [`apache/hadoop:3.4.1`](https://hub.docker.com/r/apache/hadoop) | 384 MB | HDFS のファイル一覧と、各ファイルのブロックの場所を管理します。WebHDFS と、ポート 9870 の Web ページを提供します |
| `datanode` | `apache/hadoop:3.4.1` | 256 MB | ファイルのブロックを保存します |
| `resourcemanager` | `apache/hadoop:3.4.1` | 384 MB | YARN のスケジューラーです。ポート 8088 にジョブの一覧があります |
| `nodemanager` | `apache/hadoop:3.4.1` | 512 MB | ジョブのタスクを実行します |
| `client` | `apache/hadoop:3.4.1` | 320 MB | クラスターの起動後に単語カウントを一度実行し、そのまま残るので、`docker exec` で 2 回目も実行できます |

制限の合計は 1,856 MB で、プラットフォームが 1 つのコピーに与える 2 GB に収まります。5 つのサービスは同じイメージを使うので、ダウンロードは 1 回だけです。待機中の 1 コピーは約 820 MB を使い、一般的な Intel または AMD のマシンでは、最初の単語カウントも含めて約 1 分で正常に動き始めます。初回の起動ではイメージ（圧縮で約 1.2 GB）をダウンロードします。

イメージは Apache Hadoop プロジェクト自身のものを、変更せずにバージョンを固定して（`latest` は使いません）実行します。そのため、レッスンとレッスンの間でラボが変わることはありません。ここでは何もビルドせず、このリポジトリのものがイメージの中に配布されることもありません。設定は各サービスのエントリポイントが compose ファイルから書き出すので、ほかにダウンロードするものはありません。ヒープを極端に絞り、ジョブを小さな「uber」ジョブとして実行しているので、コピーは小さく済みます。そのため、これは教育用のクラスターであり、実際のデータを処理する場所ではありません。

## プラットフォームで使う

[MitsuruTech ラーニングプラットフォーム](https://mitsurutech.co.uk/ja/learning)では、生徒一人ひとりがブラウザー上で、ターミナルを横に置いたラボの専用コピーを使えます。

**試すには：**[コンテナーのページ](https://mitsurutech.co.uk/ja/container)を開き、**サンプルラボ**からこのラボを選んで「起動」を押します。試すだけならアカウントは不要です。このラボのマニュアルのページは [Hadoop ラボ](https://mitsurutech.co.uk/ja/help/lab-hadoop)で、レッスン **Hadoop Basics** で一通り体験できます。

**クラスの課題として出すには：**

1. モジュールで、種類が**ラボ**の課題を作り、**GitHub リポジトリ**を選びます。
2. `https://github.com/mitsurutech/lab-hadoop` とブランチ `main` を指定します。compose ファイルは既定の `compose.yaml` です。ファイルを変更したい場合は、先にリポジトリをフォークしてください。
3. 公開します。生徒のコピーはどれも、公開した時点のコミットから始まるので、あとでここを変更しても、すでに出したラボは変わりません。
4. 何を提出するかを課題に書き（[教員の方へ](#教員の方へ)を参照）、ほかの課題と同じように配布します。

マニュアルの[コンテナーラボのガイド](https://mitsurutech.co.uk/ja/help/labs)に、そのほかのことが載っています。compose ファイルに書けること、コピーが使えるメモリの量、教員が生徒のコピーを開いて見て採点する方法などです。

学校のアカウントはまだありませんか？[最初の 1 年は無料](https://mitsurutech.co.uk/ja/pricing)で、生徒 50 人まで使えます。[登録](https://mitsurutech.co.uk/ja/signup)にはメールアドレスだけが必要です。

## 自分のマシンで動かす

Compose プラグイン付きの Docker と、割り当てられるメモリ約 2 GB が必要です。初回の起動では、サイズの大きいイメージをダウンロードします。

```bash
docker compose -f compose.yaml -f local.yaml up
```

NameNode は <http://localhost:9870>、ResourceManager は <http://localhost:8088> で開きます。クラスターが起動してから単語カウントが実行されます。初回は数分かかります。`local.yaml` が公開するのはこの 2 つのポートだけで、しかも `127.0.0.1` に限られるので、ラボには自分のコンピューターからしかアクセスできません。`Ctrl-C` で止め、`docker compose -f compose.yaml -f local.yaml down -v` で削除します。

イメージは Intel と AMD のプロセッサー（`amd64`）向けにしか作られていません。Apple Silicon の Mac では Docker がエミュレーションで実行します。動きますが、起動はずっと遅くなります。

## 進め方

ラボのターミナルには `hadoop` コマンドがないので、HDFS の HTTP インターフェースである **WebHDFS** を `curl` で使います。アドレスはすべて `http://namenode:9870/webhdfs/v1` で始まります。

1. **クラスターが数えてくれたファイルを見ます。** `curl 'http://namenode:9870/webhdfs/v1/user/lab/input?op=LISTSTATUS'` でフォルダーの一覧が表示されます。NameNode の Web ページでは、同じものが **Utilities, Browse the file system** にあります。クラスターの起動時に、あるサービスが `/user/lab/input/sentence.txt` に対して Hadoop の単語カウントを実行し、結果を `/user/lab/wordcount-out` に残しています。
2. **結果を読みます。** `curl -L 'http://namenode:9870/webhdfs/v1/user/lab/wordcount-out/part-r-00000?op=OPEN'` を実行すると、単語ごとに 1 行、単語とその出現回数が表示されます。`-L` は重要です。NameNode は、データを持つ DataNode へのリダイレクトで応答するからです。
3. **自分のファイルを HDFS に置きます。** `curl -X PUT 'http://namenode:9870/webhdfs/v1/user/lab/mine?op=MKDIRS&user.name=lab'` でフォルダーを作り、`curl -L -X PUT -T mytext.txt 'http://namenode:9870/webhdfs/v1/user/lab/mine/mytext.txt?op=CREATE&user.name=lab'` でファイルを書き込みます。書き込みは内部では 2 つのリクエストです。NameNode が DataNode を選び、DataNode がデータを受け取ります。これがこの演習のねらいです。
4. **一覧を表示し、読み戻します。** 上と同じように `op=LISTSTATUS` と `op=OPEN` を使います。
5. **それに対して MapReduce を実行します。** `docker exec client hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar wordcount /user/lab/mine /user/lab/mine-out` で、単語カウントが YARN のジョブとして実行されます。ResourceManager のページか `curl http://resourcemanager:8088/ws/v1/cluster/apps` で、そのジョブを確認できます。`/user/lab/mine-out/part-r-00000` を手順 2 と同じように読みます。

ラボを止めると、何も保存されません。HDFS はデータをコンテナーの中に持っていて、次は空の状態から始まり、最初の単語カウントがやり直されます。ここでは何も保護されておらず、どんなユーザー名も受け付け、権限は無効です。自分専用のコピーならこれで問題ありませんが、実際のクラスターには向きません。

## 教員の方へ

このラボには自動採点がありません。生徒が証拠を提出し、教員が、ほかのラボと同じように採点します。

**証拠は 2 つに分けて求めてください。**1 つ目は作業の証拠です。HDFS に置いたファイルのパス、そのファイルから MapReduce が作った単語カウントの行、そしてジョブが完了したことを示す ResourceManager のページ、またはジョブ一覧の出力です。2 つ目は理解です。NameNode が何を持ち、DataNode が何を持つか、なぜファイルの読み取りに 2 つのリクエストが必要か、なぜ実際のクラスターではブロックごとに 3 つのコピーを持つのか、です。生徒はそれぞれ自分のテキストを選ぶので、答えは一人ひとり違い、写した答えは見分けがつきます。

**コースでの位置づけ。**データ、クラウド、ビッグデータ、システムの単元で、分散ストレージと MapReduce を初めて体験するのに向いています。正確な表現は、ご自身の認定団体の単元でご確認ください。ここでは引用していません。

**誰が何を見られるか。**コピーは、起動した生徒だけのものです。そのモジュールを教えている教職員は、生徒の作業内容を確認するためにコピーを開けます。生徒の作業を開いたことはアクセスログに記録され、生徒はそれを読めます。

## ラボでできないこと

ラボにはインターネットへの出口がないので、何もダウンロードできません。DataNode と NodeManager は 1 つずつなので、Hadoop の構成は分かりますが、マシンの故障に耐える仕組みや、大きなジョブの高速化は体験できず、レプリケーションは 1 に設定されています。ファイルの内容を表示するブラウザーのページは、ブラウザーを DataNode に向かわせますが、コピーでは DataNode を開いていないので、ファイルの内容は `curl` で読みます。NodeManager と DataNode 自身のページも開いていません。ジョブの実行には、ラボのターミナルで `docker exec` コマンドが必要です。ラボを止めると何も保存されません。Hive、Spark、HBase は含まれていません。

## ラボの検証

`test/check.sh` は、プラットフォームのランナーがすべてのサービスを起動するのと同じ条件（すべてのケーパビリティを削除、`no-new-privileges`、プロセス数の制限、メモリの制限、インターネットへの出口なし）でラボを起動し、そのネットワークの内側から、このページの内容を確認します。すべてのサービスが正常であること、クラスターが実行した単語カウントが HDFS にあって WebHDFS で読めること、ファイルが 2 つのリクエストで入り、読み戻せること、生徒自身の MapReduce ジョブが実行されてその結果が正しいこと、ResourceManager がジョブを一覧することです。Docker が必要で、push のたびに実行されます。ページ上部のバッジがそれです。

```bash
test/check.sh
```

## バージョンとライセンス

[Apache Hadoop](https://hadoop.apache.org) は Apache License 2.0 でライセンスされています。独自の公開イメージ `apache/hadoop:3.4.1` を変更せずに実行しており、ここでは配布していません。

中のアプリケーションは、それぞれのプロジェクトのライセンスに従います。

## ライセンス

この作品は [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) でライセンスされています。Mitsuru Technologies Ltd のクレジットを表示し、商用に使わず、これをもとに作ったものを同じライセンスで共有するなら、学習と授業のために共有・改変できます。全文は `LICENSE` ファイルにあります。

## この演習について

[Mitsuru Technologies](https://mitsurutech.co.uk) が、[MitsuruTech ラーニングプラットフォーム](https://mitsurutech.co.uk/ja/learning)のために作りました。学校向けに、Python、Java、Go、Node、SQL、Linux をブラウザーで使えるようにし、コンテナーラボ、GitHub から公開する Web アプリ、自動採点されるクイズも備えています。アカウントなしでコードを試せる[プレイグラウンド](https://mitsurutech.co.uk/ja/playground)もあります。すべてのラボは[マニュアル](https://mitsurutech.co.uk/ja/help/labs)に一覧があります。

同じ提供元のほかのラボ：[lab-juice-shop](https://github.com/mitsurutech/lab-juice-shop)、[lab-dvwa](https://github.com/mitsurutech/lab-dvwa)、[lab-webgoat](https://github.com/mitsurutech/lab-webgoat)、[lab-mysql-phpmyadmin](https://github.com/mitsurutech/lab-mysql-phpmyadmin)、[lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea)、[lab-observability](https://github.com/mitsurutech/lab-observability)、[lab-sample](https://github.com/mitsurutech/lab-sample)。
