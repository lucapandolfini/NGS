#!/bin/bash
# 2017-09-07 ChIP Mapping Pipeline
#Usage ./bwa_ChIP.sh Threads target_dir 2>&1 | tee mapping_report.log

red='\033[0;31m'
nc='\033[0m'
gr='\033[0;32m'

THR=$1
cd $2
HOMEDIR=/home/lp471

for i in *.fq.gz
do

FILE=$i
NAME="${FILE/.fq.gz/}"

echo -e "${red}\n"
date
echo "PROCESSING $FILE..."
echo -e "${red}----------------------------------------------${nc}"

echo -e "${gr}\nClipping Adaptor Sequences...${nc}"
java -jar $HOMEDIR/bin/Trimmomatic-0.35/trimmomatic-0.35.jar SE -threads $THR -phred33 $NAME.fq.gz $NAME"_clipped".fastq ILLUMINACLIP:$HOMEDIR/bin/Trimmomatic-0.35/adapters/ChIP_Seq_Bioo.fa:2:30:10 MINLEN:40

echo -e "${gr}\nMapping with bwa...${nc}"
bwa aln -n 3 -k 2 -R 300 -t $THR ~/Genomes/hg38/hg38.fa $NAME"_clipped".fastq > $NAME.sai
bwa samse -n 3 ~/Genomes/hg38/hg38.fa $NAME.sai $NAME"_clipped".fastq > $NAME.sam

echo -e "${gr}\nFiltering unique mapping reads...${nc}"
samtools view -F 256 -O BAM -@ 14 $NAME.sam > $NAME.smap.bam

echo -e "${gr}\n Removing PCR duplicates...${nc}"
samtools rmdup -s $NAME.smap.bam $NAME.unsorted.bam

echo -e "${gr}\n Sorting .bam file...${nc}"
samtools sort -@ $THR $NAME.unsorted.bam > $NAME.bam

echo -e "${gr}\n Indexing .bam file...${nc}"
samtools index $NAME.bam

echo -e "${gr}\n Calculating coverage...${nc}"
scale_pos=$(samtools view -F 256 -c $NAME.bam)
scale_pos=$(echo "1000000/$scale_pos" | bc -l)
genomeCoverageBed -split -ibam $NAME.bam -bg -g ~/Genomes/hg38/hg38.chrom.sizes -trackline -trackopts "speciesOrder=hg38 db=hg38 visibility=full color=45,45,201 name=$NAME.Coverage description=$NAME-Coverage" -scale $scale_pos > $NAME.cov

echo -e "${gr}\n Creating .bigWig file...${nc}"
bedGraphToBigWig $NAME.cov ~/Genomes/hg38/hg38.chrom.sizes $NAME.bw

echo -e "${gr}\nCleaning up...${nc}"
rm $NAME"_clipped".fastq $NAME.sai $NAME.sam $NAME.smap.bam $NAME.unsorted.bam $NAME.cov

done
