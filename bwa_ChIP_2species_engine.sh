#!/bin/bash
# 2018-06-15 ChIP Mapping Pipeline
# This run is invocated internally by bwa_ChIP_2species.sh to allow parallel execution of single-threaded tasks.

FILE=$1
NAME="${FILE/.unsorted.bam/}"

red='\033[0;31m'
nc='\033[0m'
gr='\033[0;32m'

echo -e "${gr}$NAME: Splitting reads...${nc}"

bamtools split -in $NAME.unsorted.bam -reference
mkdir $NAME"_spikein"
mv $NAME*_mouse.bam $NAME"_spikein"/
samtools merge -O SAM $NAME.mouse.sam $NAME"_spikein"/*
cat <(grep "@" $NAME.mouse.sam | grep "_mouse") <(grep -v "@" $NAME.mouse.sam) > $NAME.mouse.tmp.sam
sed -i -e 's/_mouse//g' $NAME.mouse.tmp.sam

mkdir $NAME"_human"
mv $NAME*.REF_* $NAME"_human"/
rm $NAME"_human"/*REF_unmapped.bam
samtools merge -O SAM $NAME.human.sam $NAME"_human"/*
grep -v "@PG" $NAME.human.sam | grep -v "_mouse" > $NAME.human.tmp.sam

echo -e "${gr}$NAME: Sorting .bam files...${nc}"
samtools sort $NAME.mouse.tmp.sam > $NAME.mouse.bam
samtools sort $NAME.human.tmp.sam > $NAME.human.bam

echo -e "${gr}$NAME: Indexing .bam files...${nc}"
samtools index $NAME.mouse.bam
samtools index $NAME.human.bam

echo -e "${gr}$NAME: Calculating coverage...${nc}"

scale_pos_human=$(samtools view -F 256 -c $NAME.human.bam)
scale_pos_human=$(echo "1000000/$scale_pos_human" | bc -l)
genomeCoverageBed -split -ibam $NAME.human.bam -bg -g ~/Genomes/hg38/hg38.chrom.sizes -trackline -trackopts "speciesOrder=hg38 db=hg38 visibility=full color=45,45,201 name=$NAME.human.Coverage description=$NAME.human-Coverage" -scale $scale_pos_human > $NAME.human.cov

scale_pos_mouse=$(samtools view -F 256 -c $NAME.mouse.bam)
scale_pos_mouse=$(echo "1000000/$scale_pos_mouse" | bc -l)
genomeCoverageBed -split -ibam $NAME.mouse.bam -bg -g ~/Genomes/mm10/mm10.chrom.sizes -trackline -trackopts "speciesOrder=mm10 db=mm10 visibility=full color=45,45,201 name=$NAME.human.Coverage description=$NAME.mouse-Coverage" -scale $scale_pos_mouse > $NAME.mouse.cov

echo -e "${gr}$NAME: Creating .bigWig file...${nc}"
bedGraphToBigWig $NAME.human.cov ~/Genomes/hg38/hg38.chrom.sizes $NAME.human.bw
bedGraphToBigWig $NAME.mouse.cov ~/Genomes/mm10/mm10.chrom.sizes $NAME.mouse.bw

echo -e "${gr}$NAME: Cleaning up...${nc}"
#rm $NAME"_clipped".fastq $NAME.smap.bam $NAME.unsorted.bam $NAME.mouse.sam $NAME.human.sam $NAME.mouse.tmp.sam $NAME.human.tmp.sam $NAME.mouse.cov $NAME.human.cov
#rm $NAME.sai $NAME.sam
rm -rf $NAME"_spikein"/ $NAME"_human"/
