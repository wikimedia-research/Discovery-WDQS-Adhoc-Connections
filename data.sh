#!/bin/bash

mkdir wdqs_requests

for day in {1..28}
do
  hive -S -hiveconf day=${day} -f data.hql > wdqs_requests/${day}.tsv
  gzip wdqs_requests/${day}.tsv
done
