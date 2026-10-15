#!/usr/bin/env bash
# What the README promises, checked from inside the lab's own network: run by check.sh.
set -euo pipefail
: "${NET:?run through test/check.sh}"
: "${PROJECT:?run through test/check.sh}"
probe() { docker run --rm --network "$NET" hadoop-check-probe bash -c "$1"; }
box() { docker ps -aq --filter "label=com.docker.compose.project=$PROJECT" --filter "label=com.docker.compose.service=$1"; }
W=http://namenode:9870/webhdfs/v1

echo "- the NameNode and the ResourceManager answer, with one live DataNode and one NodeManager"
probe "curl -fs $W/?op=LISTSTATUS" | grep -q '"FileStatuses"'
probe 'curl -fs http://namenode:9870/jmx?qry=Hadoop:service=NameNode,name=FSNamesystemState' | grep -q '"NumLiveDataNodes" *: *1'
probe 'curl -fs http://resourcemanager:8088/ws/v1/cluster/nodes' | grep -q '"state":"RUNNING"'
probe 'curl -fsL http://namenode:9870/' | grep -qi hadoop
probe 'curl -fsL http://resourcemanager:8088/cluster' | grep -qi hadoop

echo "- the word count made when the lab started is in HDFS, and WebHDFS reads it back"
probe "curl -fsL '$W/user/lab/wordcount-out/part-r-00000?op=OPEN'" | tee /dev/stderr | awk -F'\t' '$1=="the" && $2==4 {f=1} END {exit !f}'
probe "curl -fs '$W/user/lab/wordcount-out?op=LISTSTATUS'" | grep -q '_SUCCESS'
probe 'curl -fs http://resourcemanager:8088/ws/v1/cluster/apps' | grep -q '"finalStatus":"SUCCEEDED"'

echo "- a file is put into HDFS with two curl requests, listed and read back"
probe "printf 'one fish two fish red fish blue fish\n' > /tmp/f.txt
  curl -fs -X PUT '$W/user/lab/mine?op=MKDIRS&user.name=lab' | grep -q true
  curl -fsL -X PUT -T /tmp/f.txt '$W/user/lab/mine/fish.txt?op=CREATE&user.name=lab&overwrite=true'
  curl -fs '$W/user/lab/mine?op=LISTSTATUS' | grep -q '\"pathSuffix\":\"fish.txt\"'
  curl -fs '$W/user/lab/mine/fish.txt?op=GETFILESTATUS' | grep -q '\"length\":36'
  curl -fsL '$W/user/lab/mine/fish.txt?op=OPEN' | grep -q 'one fish two fish red fish blue fish'"

echo "- the student runs a word count of their own file, and reads the answer"
docker exec "$(box client)" hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar wordcount /user/lab/mine /user/lab/mine-out >/dev/null 2>&1
probe "curl -fsL '$W/user/lab/mine-out/part-r-00000?op=OPEN'" | tee /dev/stderr | awk -F'\t' '$1=="fish" && $2==4 {f=1} END {exit !f}'

echo "- a file can be deleted with WebHDFS"
probe "curl -fs -X DELETE '$W/user/lab/mine?op=DELETE&recursive=true&user.name=lab'" | grep -q true
echo "  ok"
