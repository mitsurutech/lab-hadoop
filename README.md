# Hadoop HDFS and MapReduce lab with Docker Compose: put a file in HDFS and count its words in a private copy

[![check](https://github.com/mitsurutech/lab-hadoop/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-hadoop/actions/workflows/check.yml)

A ready-made **Hadoop lab** for classrooms, from the [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning), where schools and colleges give every student their own databases, containers and terminal in the browser. Each student gets a small private **Hadoop cluster**: **HDFS**, the distributed file system, with a NameNode and a DataNode, and **YARN** with a ResourceManager and a NodeManager to run **MapReduce** jobs. They **put a file into HDFS, list it, read it back and run the bundled word count** on it, over plain HTTP with `curl` and in the NameNode's own web page. It suits a first look at big data storage and processing in a data, cloud or distributed systems unit, with nothing installed and no risk to anybody else's machine.

It is one `docker-compose` file, `compose.yaml`, and it runs the same on your own machine as it does on the platform, where every student gets a private copy with no way out to the internet.

## What is in it

| Service | Image | Memory | What it is |
| --- | --- | --- | --- |
| `namenode` | [`apache/hadoop:3.4.1`](https://hub.docker.com/r/apache/hadoop) | 384 MB | HDFS's directory of files and where their blocks are, with WebHDFS and the web page on port 9870 |
| `datanode` | `apache/hadoop:3.4.1` | 256 MB | stores the blocks of the files |
| `resourcemanager` | `apache/hadoop:3.4.1` | 384 MB | YARN's scheduler, with the list of jobs on port 8088 |
| `nodemanager` | `apache/hadoop:3.4.1` | 512 MB | runs a job's tasks |
| `client` | `apache/hadoop:3.4.1` | 320 MB | runs the word count once the cluster is up, then stays so a second can be run with `docker exec` |

That is 1,856 MB of limits, under the platform's 2 GB for a copy. The five services use one image, so it is downloaded once. Idle, a copy uses roughly 820 MB, and on an ordinary Intel or AMD machine it is healthy in about a minute, the first word count included. The first start downloads the image (about 1.2 GB compressed).

The image is the Apache Hadoop project's own, run unmodified and pinned to a version (never `latest`), so the lab does not change under a class between one lesson and the next. Nothing is built here and nothing from this repository is distributed in it. The configuration is written by each service's entrypoint from the compose file, so there is nothing else to download. The heaps are tuned right down and the job runs as one small "uber" job, which is why a copy is small, and why it is a teaching cluster and not a place to process real data.

## Using it on the platform

The [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning) gives every student their own copy of a lab, in the browser, with a terminal beside it.

**To try it:** open the [container page](https://mitsurutech.co.uk/container), find this lab in **Sample labs** and press Start. No account is needed to try one. The manual page for it is [Hadoop lab](https://mitsurutech.co.uk/help/lab-hadoop), and the lesson **Hadoop Basics** works through it.

**To set it as work for a class:**

1. In your module, make a task of type **Lab** and choose **In a GitHub repository**.
2. Give `https://github.com/mitsurutech/lab-hadoop` with the branch `main`. The compose file is the default, `compose.yaml`. Fork the repository first if you want to change the file.
3. Publish. Every student's copy starts from the commit you published, so a later change here does not alter a lab already set.
4. Say in the task what to hand in (see [For teachers](#for-teachers)), and assign it like any other task.

The help manual's [guide to container labs](https://mitsurutech.co.uk/help/labs) covers the rest: what a compose file may say, how much memory a copy gets, and how a teacher opens, watches and marks a student's copy.

No college account yet? [Your first year is free](https://mitsurutech.co.uk/pricing) for up to 50 students, and [signing up](https://mitsurutech.co.uk/signup) takes an email address.

## Running it on your own machine

You need Docker with the Compose plugin, and about 2 GB of memory to give it. The first start downloads the image, which is large.

```bash
docker compose -f compose.yaml -f local.yaml up
```

Open <http://localhost:9870> for the NameNode and <http://localhost:8088> for the ResourceManager. The cluster starts, then runs a word count, which takes a few minutes the first time. `local.yaml` publishes only those two ports and only on `127.0.0.1`, so the lab is reachable from your own computer and from nowhere else. Stop it with `Ctrl-C`, and remove it with `docker compose -f compose.yaml -f local.yaml down -v`.

The image is built for Intel and AMD processors (`amd64`) only. On an Apple Silicon Mac Docker runs it under emulation, which works but is much slower to start.

## Working through it

The lab's terminal has no `hadoop` command, so it uses **WebHDFS**, HDFS's HTTP interface, with `curl`. Every address starts `http://namenode:9870/webhdfs/v1`.

1. **Look at the file the cluster counted for you.** `curl 'http://namenode:9870/webhdfs/v1/user/lab/input?op=LISTSTATUS'` lists the folder, and the same page in the NameNode's web page is **Utilities, Browse the file system**. When the cluster started, a service ran the Hadoop word count over `/user/lab/input/sentence.txt` and left the answer in `/user/lab/wordcount-out`.
2. **Read the answer.** `curl -L 'http://namenode:9870/webhdfs/v1/user/lab/wordcount-out/part-r-00000?op=OPEN'` prints one line per word, the word and how many times it appeared. The `-L` matters: the NameNode answers with a redirect to the DataNode that holds the bytes.
3. **Put a file of your own into HDFS.** Make a folder with `curl -X PUT 'http://namenode:9870/webhdfs/v1/user/lab/mine?op=MKDIRS&user.name=lab'`, then write the file with `curl -L -X PUT -T mytext.txt 'http://namenode:9870/webhdfs/v1/user/lab/mine/mytext.txt?op=CREATE&user.name=lab'`. Writing is two requests under the hood, the NameNode choosing a DataNode and the DataNode taking the bytes, which is the point of the exercise.
4. **List it and read it back** with `op=LISTSTATUS` and `op=OPEN`, as above.
5. **Run MapReduce on it.** `docker exec client hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar wordcount /user/lab/mine /user/lab/mine-out` runs the word count as a YARN job, and the ResourceManager's page, or `curl http://resourcemanager:8088/ws/v1/cluster/apps`, lists it. Read `/user/lab/mine-out/part-r-00000` as in step 2.

Nothing is saved when the lab stops: HDFS keeps its data inside the containers, and starts empty again, the first word count running afresh. Nothing here is secured, any user name is accepted and permissions are off, which is right for a copy of your own and wrong for a real cluster.

## For teachers

Nothing in this lab is marked automatically. The student hands in evidence and you mark it, the way you mark any other lab.

**Ask for evidence in two halves.** First, proof of the work: the path of the file they put into HDFS, the lines of the word count MapReduce made from it, and the ResourceManager page or the output of the jobs list showing the job finished. Second, the understanding: what the NameNode keeps and what the DataNode keeps, why a file is read with two requests, and why a real cluster keeps three copies of every block. Because each student chooses their own text, the answers differ and a copied one shows.

**Where it sits in a course.** It suits a first look at distributed storage and MapReduce in a data, cloud, big data or systems unit. Check your own awarding body's unit for the exact wording; none is quoted here.

**Who sees what.** A copy is private to the student who started it. A member of staff who teaches the module can open it to see what the student has done, and opening a student's work is written to the access log, which the student can read.

## What does not work in a lab

The lab has no way out to the internet, so nothing can be downloaded into it. It is one DataNode and one NodeManager, so it shows how Hadoop is arranged but not how it survives a machine failing or how it speeds a big job up, and the replication is set to one. The browser's page for a file's contents sends the browser to the DataNode, which a copy does not open, so file contents are read with `curl`. The NodeManager's and DataNode's own pages are not opened either. Running a job needs the `docker exec` command in the lab's terminal. Nothing is saved when the lab stops. Hive, Spark and HBase are not part of it.

## Checking the lab

`test/check.sh` starts the lab the way the platform's runner starts every service (all capabilities dropped, `no-new-privileges`, a process limit, memory limits, and no way out to the internet) and then checks from inside its network what this page promises: every service is healthy, the word count the cluster ran is in HDFS and WebHDFS reads it, a file goes in with two requests and comes back, a MapReduce job of the student's own runs and its answer is right, and the ResourceManager lists the jobs. It needs Docker and runs on every push, which is the badge at the top.

```bash
test/check.sh
```

## Versions and licences

[Apache Hadoop](https://hadoop.apache.org) is licensed under the Apache License 2.0. It is run unmodified from its own public image, `apache/hadoop:3.4.1`, and is not distributed here.

The compose file, the tests and this documentation are MIT licensed, see [LICENSE](LICENSE): copy it, change it, teach with it. The application inside keeps the licence of its own project.

## About

Made by [Mitsuru Technologies](https://mitsurutech.co.uk) for the [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning): Python, Java, Go, Node, SQL and Linux in the browser for schools and colleges, with container labs, web apps deployed from GitHub, and quizzes that mark themselves. Try code with no account in the [playground](https://mitsurutech.co.uk/playground). The [help manual](https://mitsurutech.co.uk/help/labs) lists every lab.

More labs from the same place: [lab-juice-shop](https://github.com/mitsurutech/lab-juice-shop), [lab-dvwa](https://github.com/mitsurutech/lab-dvwa), [lab-webgoat](https://github.com/mitsurutech/lab-webgoat), [lab-mysql-phpmyadmin](https://github.com/mitsurutech/lab-mysql-phpmyadmin), [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea), [lab-observability](https://github.com/mitsurutech/lab-observability) and [lab-sample](https://github.com/mitsurutech/lab-sample).
