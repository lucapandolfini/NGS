#!/bin/bash
# 2018-06-15 ChIP Mapping Pipeline
# This run is invocated internally by bwa_ChIP_2species.sh to allow parallel execution of single-threaded tasks.

FILE=$1
NAME="${FILE/.unsorted.bam/}"

red='\033[0;31m'
nc='\033[0m'
gr='\033[0;32m'

echo -e "${gr}$NAME: Sorting .bam files...${nc}"
samtools sort $NAME.unsorted.bam > $NAME.bam

echo -e "${gr}$NAME: Indexing .bam files...${nc}"
samtools index $NAME.bam

echo -e "${gr}$NAME: Calculating coverage...${nc}"

scale_pos_human=$(samtools view -F 256 -c $NAME.bam)
scale_pos_human=$(echo "1000000/$scale_pos_human" | bc -l)
genomeCoverageBed -split -ibam $NAME.bam -bg -g ~/Genomes/hg38/hg38.chrom.sizes -trackline -trackopts "speciesOrder=hg38 db=hg38 visibility=full color=45,45,201 name=$NAME.coverage description=$NAME.human-Coverage" -scale $scale_pos_human > $NAME.cov

echo -e "${gr}$NAME: Creating .bigWig file...${nc}"
bedGraphToBigWig $NAME.cov ~/Genomes/hg38/hg38.chrom.sizes $NAME.bw

echo -e "${gr}$NAME: Cleaning up...${nc}"
#rm $NAME"_clipped".fastq $NAME.smap.bam $NAME.unsorted.bam $NAME.cov
#rm $NAME.sai $NAME.sam

