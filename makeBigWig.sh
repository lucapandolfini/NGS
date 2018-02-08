#!/bin/bash

red='\033[0;31m'
nc='\033[0m'

FILE=$1
NAME="${FILE/.bam/}"

echo -e "${red}\n"
date
echo "PROCESSING $FILE..."
echo -e "${red}----------------------------------------------${nc}"

scale_pos=$(samtools view -F 256 -c $NAME.bam)
scale_pos=$(echo "1000000/$scale_pos" | bc -l)
genomeCoverageBed -split -ibam $NAME.bam -bg -g ~/LAB/ANNOTATION/hg38.chrom.sizes -trackline -trackopts "speciesOrder=hg38 db=hg38 visibility=full color=45,45,201 name=$NAME.Coverage description=$NAME-Coverage" -scale $scale_pos > $NAME.cov
bedGraphToBigWig $NAME.cov ~/LAB/ANNOTATION/hg38.chrom.sizes $NAME.bw
rm $NAME.cov

