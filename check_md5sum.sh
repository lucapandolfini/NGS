#!/bin/bash
# 2018-06-01 CI FASTQ transfer check
# Chech md5sums

red='\033[0;31m'
nc='\033[0m'
gr='\033[0;32m'

for i in *.md5sums.txt
do

FILE=$i
NAME="${FILE/.md5sums.txt/}"

echo -e "${red}\n"
echo "PROCESSING $NAME..."
echo -e "${red}----------------------------------------------${nc}"
md5sum -c $FILE
done

