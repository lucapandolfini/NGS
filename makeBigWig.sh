#!/bin/bash

red='\033[0;31m'
nc='\033[0m'

CHR_SIZE=$1
FILE=$2
NAME="${FILE/.bam/}"

echo -e "${red}\n"
date
echo "PROCESSING $FILE..."
echo -e "${red}----------------------------------------------${nc}"

scale_pos=$(samtools view -F 256 -c $NAME.bam)
scale_pos=$(echo "1000000/$scale_pos" | bc -l)
genomeCoverageBed -split -ibam $NAME.bam -bg -g $CHR_SIZE -trackline -trackopts "speciesOrder=hg38 db=hg38 visibility=full color=45,45,201 name=$NAME.Coverage description=$NAME-Coverage" -scale $scale_pos > $NAME.cov
bedGraphToBigWig $NAME.cov $CHR_SIZE $NAME.bw
rm $NAME.cov
