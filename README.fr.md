# Lab Hadoop HDFS et MapReduce avec Docker Compose : déposer un fichier dans HDFS et compter ses mots dans une copie privée

[English](README.md) | [Français](README.fr.md) | [日本語](README.ja.md) | [Español](README.es.md)

[![check](https://github.com/mitsurutech/lab-hadoop/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-hadoop/actions/workflows/check.yml)

Un **lab Hadoop** prêt à l’emploi pour la classe, issu de la [plateforme d’apprentissage MitsuruTech](https://mitsurutech.co.uk/fr/learning), où les écoles et les établissements donnent à chaque élève ses propres bases de données, conteneurs et terminal dans le navigateur. Chaque élève reçoit un petit **cluster Hadoop** privé : **HDFS**, le système de fichiers distribué, avec un NameNode et un DataNode, et **YARN** avec un ResourceManager et un NodeManager pour exécuter des jobs **MapReduce**. L’élève **dépose un fichier dans HDFS, le liste, le relit et lance le comptage de mots fourni** dessus, en HTTP avec `curl` et dans la page web du NameNode. C’est une bonne première approche du stockage et du traitement de données volumineuses dans une unité de données, de cloud ou de systèmes distribués, sans rien installer et sans risque pour la machine de quiconque.

Tout tient dans un seul fichier `docker-compose`, `compose.yaml`, qui fonctionne de la même façon sur votre propre machine et sur la plateforme, où chaque élève obtient une copie privée sans aucun accès à internet.

## Ce que vous y trouvez

| Service | Image | Mémoire | Ce que c’est |
| --- | --- | --- | --- |
| `namenode` | [`apache/hadoop:3.4.1`](https://hub.docker.com/r/apache/hadoop) | 384 Mo | l’annuaire des fichiers de HDFS et l’emplacement de leurs blocs, avec WebHDFS et la page web sur le port 9870 |
| `datanode` | `apache/hadoop:3.4.1` | 256 Mo | stocke les blocs des fichiers |
| `resourcemanager` | `apache/hadoop:3.4.1` | 384 Mo | l’ordonnanceur de YARN, avec la liste des jobs sur le port 8088 |
| `nodemanager` | `apache/hadoop:3.4.1` | 512 Mo | exécute les tâches d’un job |
| `client` | `apache/hadoop:3.4.1` | 320 Mo | lance le comptage de mots une fois le cluster démarré, puis reste actif pour qu’on puisse en lancer un second avec `docker exec` |

Cela fait 1 856 Mo de limites, sous les 2 Go que la plateforme accorde à une copie. Les cinq services utilisent une seule image, téléchargée une seule fois. Au repos, une copie utilise environ 820 Mo, et sur une machine Intel ou AMD ordinaire elle est opérationnelle en une minute environ, premier comptage de mots compris. Le premier démarrage télécharge l’image (environ 1,2 Go compressés).

L’image est celle du projet Apache Hadoop lui-même, exécutée sans modification et figée sur une version (jamais `latest`), de sorte que le lab ne change pas sous les pieds d’une classe d’une leçon à l’autre. Rien n’est construit ici et rien de ce dépôt n’y est distribué. La configuration est écrite par le point d’entrée de chaque service à partir du fichier compose, il n’y a donc rien d’autre à télécharger. Les tas mémoire sont réduits au minimum et le job s’exécute sous la forme d’un petit job « uber », ce qui explique qu’une copie soit légère, et que ce soit un cluster d’enseignement et non un endroit où traiter de vraies données.

## L’utiliser sur la plateforme

La [plateforme d’apprentissage MitsuruTech](https://mitsurutech.co.uk/fr/learning) donne à chaque élève sa propre copie d’un lab, dans le navigateur, avec un terminal à côté.

**Pour l’essayer :** ouvrez la [page des conteneurs](https://mitsurutech.co.uk/fr/container), trouvez ce lab dans **Laboratoires d’exemple** et appuyez sur Démarrer. Aucun compte n’est nécessaire pour en essayer un. La page du manuel qui lui est consacrée est [Lab Hadoop](https://mitsurutech.co.uk/fr/help/lab-hadoop), et la leçon **Hadoop Basics** le parcourt pas à pas.

**Pour le donner comme travail à une classe :**

1. Dans votre module, créez une tâche de type **Lab** et choisissez **Dans un dépôt GitHub**.
2. Indiquez `https://github.com/mitsurutech/lab-hadoop` avec la branche `main`. Le fichier compose est celui par défaut, `compose.yaml`. Faites d’abord un fork du dépôt si vous voulez modifier le fichier.
3. Publiez. La copie de chaque élève part du commit que vous avez publié, de sorte qu’une modification ultérieure ici ne change pas un lab déjà donné.
4. Précisez dans la tâche ce qu’il faut rendre (voir [Pour les enseignants](#pour-les-enseignants)), puis distribuez-la comme n’importe quelle autre tâche.

Le [guide des labs de conteneurs](https://mitsurutech.co.uk/fr/help/labs) du manuel couvre le reste : ce qu’un fichier compose peut contenir, la mémoire dont dispose une copie, et comment un enseignant ouvre, suit et note la copie d’un élève.

Pas encore de compte d’établissement ? [La première année est gratuite](https://mitsurutech.co.uk/fr/pricing) jusqu’à 50 élèves, et [l’inscription](https://mitsurutech.co.uk/fr/signup) ne demande qu’une adresse e-mail.

## L’exécuter sur votre propre machine

Il vous faut Docker avec le plugin Compose, et environ 2 Go de mémoire à lui consacrer. Le premier démarrage télécharge l’image, qui est volumineuse.

```bash
docker compose -f compose.yaml -f local.yaml up
```

Ouvrez <http://localhost:9870> pour le NameNode et <http://localhost:8088> pour le ResourceManager. Le cluster démarre, puis lance un comptage de mots, ce qui prend quelques minutes la première fois. `local.yaml` ne publie que ces deux ports et seulement sur `127.0.0.1`, de sorte que le lab n’est accessible que depuis votre ordinateur. Arrêtez-le avec `Ctrl-C` et supprimez-le avec `docker compose -f compose.yaml -f local.yaml down -v`.

L’image n’est construite que pour les processeurs Intel et AMD (`amd64`). Sur un Mac Apple Silicon, Docker l’exécute par émulation, ce qui fonctionne mais démarre bien plus lentement.

## Pas à pas

Le terminal du lab n’a pas de commande `hadoop`, il utilise donc **WebHDFS**, l’interface HTTP de HDFS, avec `curl`. Toutes les adresses commencent par `http://namenode:9870/webhdfs/v1`.

1. **Regardez le fichier que le cluster a compté pour vous.** `curl 'http://namenode:9870/webhdfs/v1/user/lab/input?op=LISTSTATUS'` liste le dossier, et la même chose dans la page web du NameNode se trouve sous **Utilities, Browse the file system**. Au démarrage du cluster, un service a lancé le comptage de mots de Hadoop sur `/user/lab/input/sentence.txt` et a laissé le résultat dans `/user/lab/wordcount-out`.
2. **Lisez le résultat.** `curl -L 'http://namenode:9870/webhdfs/v1/user/lab/wordcount-out/part-r-00000?op=OPEN'` affiche une ligne par mot, le mot et le nombre de fois où il apparaît. Le `-L` compte : le NameNode répond par une redirection vers le DataNode qui détient les octets.
3. **Déposez un fichier à vous dans HDFS.** Créez un dossier avec `curl -X PUT 'http://namenode:9870/webhdfs/v1/user/lab/mine?op=MKDIRS&user.name=lab'`, puis écrivez le fichier avec `curl -L -X PUT -T mytext.txt 'http://namenode:9870/webhdfs/v1/user/lab/mine/mytext.txt?op=CREATE&user.name=lab'`. Écrire demande en réalité deux requêtes, le NameNode choisissant un DataNode et le DataNode recevant les octets, ce qui est tout l’intérêt de l’exercice.
4. **Listez-le et relisez-le** avec `op=LISTSTATUS` et `op=OPEN`, comme ci-dessus.
5. **Lancez MapReduce dessus.** `docker exec client hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar wordcount /user/lab/mine /user/lab/mine-out` lance le comptage de mots comme un job YARN, et la page du ResourceManager, ou `curl http://resourcemanager:8088/ws/v1/cluster/apps`, le liste. Lisez `/user/lab/mine-out/part-r-00000` comme à l’étape 2.

Rien n’est conservé à l’arrêt du lab : HDFS garde ses données à l’intérieur des conteneurs et repart vide, le premier comptage de mots étant refait. Rien n’est sécurisé ici, tout nom d’utilisateur est accepté et les permissions sont désactivées, ce qui convient pour une copie qui n’est qu’à vous et ne convient pas pour un vrai cluster.

## Pour les enseignants

Rien dans ce lab n’est noté automatiquement. L’élève rend des preuves et vous les notez, comme pour n’importe quel autre lab.

**Demandez des preuves en deux parties.** D’abord, la preuve du travail : le chemin du fichier déposé dans HDFS, les lignes du comptage de mots que MapReduce en a tirées, et la page du ResourceManager ou la sortie de la liste des jobs montrant que le job est terminé. Ensuite, la compréhension : ce que garde le NameNode et ce que garde le DataNode, pourquoi un fichier se lit en deux requêtes, et pourquoi un vrai cluster conserve trois copies de chaque bloc. Comme chaque élève choisit son propre texte, les réponses diffèrent et une réponse copiée se voit.

**Sa place dans un cursus.** Il convient à une première approche du stockage distribué et de MapReduce dans une unité de données, de cloud, de big data ou de systèmes. Vérifiez l’unité de votre propre organisme de certification pour la formulation exacte ; aucune n’est citée ici.

**Qui voit quoi.** Une copie est privée pour l’élève qui l’a démarrée. Un membre du personnel qui enseigne le module peut l’ouvrir pour voir ce que l’élève a fait, et l’ouverture du travail d’un élève est inscrite dans le journal d’accès, que l’élève peut lire.

## Ce qui ne fonctionne pas dans un lab

Le lab n’a aucun accès à internet, rien ne peut donc y être téléchargé. Il n’y a qu’un DataNode et qu’un NodeManager : il montre comment Hadoop est organisé, mais pas comment il survit à la panne d’une machine ni comment il accélère un gros job, et la réplication est fixée à un. La page du navigateur pour le contenu d’un fichier renvoie le navigateur vers le DataNode, qui n’est pas ouvert dans une copie, le contenu des fichiers se lit donc avec `curl`. Les pages propres au NodeManager et au DataNode ne sont pas ouvertes non plus. Lancer un job demande la commande `docker exec` dans le terminal du lab. Rien n’est conservé à l’arrêt du lab. Hive, Spark et HBase n’en font pas partie.

## Vérifier le lab

`test/check.sh` démarre le lab comme le fait l’exécuteur de la plateforme pour chaque service (toutes les capacités retirées, `no-new-privileges`, une limite de processus, des limites de mémoire et aucun accès à internet), puis vérifie depuis l’intérieur de son réseau ce que cette page promet : chaque service est sain, le comptage de mots lancé par le cluster est dans HDFS et WebHDFS le lit, un fichier entre en deux requêtes et ressort, un job MapReduce de l’élève s’exécute et son résultat est juste, et le ResourceManager liste les jobs. Il demande Docker et s’exécute à chaque push, ce qui correspond au badge en haut de la page.

```bash
test/check.sh
```

## Versions et licences

[Apache Hadoop](https://hadoop.apache.org) est sous licence Apache 2.0. Il est exécuté sans modification à partir de sa propre image publique, `apache/hadoop:3.4.1`, et n’est pas distribué ici.

L’application qu’il contient garde la licence de son propre projet.

## Licence

Cette œuvre est sous licence [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Vous pouvez la partager et l’adapter pour apprendre et enseigner, à condition de citer Mitsuru Technologies Ltd, de ne pas l’utiliser commercialement et de partager tout ce que vous en tirez sous la même licence. Le texte complet est dans le fichier `LICENSE`.

## À propos

Réalisé par [Mitsuru Technologies](https://mitsurutech.co.uk) pour la [plateforme d’apprentissage MitsuruTech](https://mitsurutech.co.uk/fr/learning) : Python, Java, Go, Node, SQL et Linux dans le navigateur pour les écoles et les établissements, avec des labs de conteneurs, des applications web déployées depuis GitHub et des quiz qui se corrigent seuls. Essayez du code sans compte dans le [bac à sable](https://mitsurutech.co.uk/fr/playground). Le [manuel](https://mitsurutech.co.uk/fr/help/labs) liste tous les labs.

D’autres labs du même éditeur : [lab-juice-shop](https://github.com/mitsurutech/lab-juice-shop), [lab-dvwa](https://github.com/mitsurutech/lab-dvwa), [lab-webgoat](https://github.com/mitsurutech/lab-webgoat), [lab-mysql-phpmyadmin](https://github.com/mitsurutech/lab-mysql-phpmyadmin), [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea), [lab-observability](https://github.com/mitsurutech/lab-observability) et [lab-sample](https://github.com/mitsurutech/lab-sample).
