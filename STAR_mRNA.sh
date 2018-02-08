#!/bin/bash

## ./STAR_miRNA.sh targetDirectory threads 2>&1 | tee mapping_report.log
## Version 1.0 (Osiris)
## 17 Feb 2016

red='\033[0;31m'
nc='\033[0m'
gr='\033[0;32m'

cd $1
THR=$2

for i in *.fastq.gz
do

FILE=$i
NAME="${FILE/.fastq.gz/}"

echo -e "${red}\n"
date
echo "PROCESSING $FILE..."
echo -e "${red}----------------------------------------------${nc}"

###################################################################################################################################################################

echo -e "${gr}\nClipping Adaptor Sequences...${nc}"
java -jar /mnt/home/lp471/bin/Trimmomatic-0.35/trimmomatic-0.35.jar SE -threads $THR -phred33 $NAME.fastq.gz $NAME"_clipped".fastq ILLUMINACLIP:/mnt/home/lp471/bin/Trimmomatic-0.35/adapters/NexteraPE-PE.fa:2:30:10 SLIDINGWINDOW:5:30 MINLEN:20

###################################################################################################################################################################

echo -e "${gr}\nMapping Reads with STAR...${nc}"

STAR --runMode alignReads --runThreadN $THR --genomeDir ~/Genomes/GR38/STAR125/ --sjdbGTFfile ~/Genomes/GR38/GRCh38.p7.gtf --sjdbOverhang 124 --readFilesIn $NAME"_clipped".fastq --outFilterType BySJout --outFilterMultimapNmax 20 --alignSJoverhangMin 8 --alignSJDBoverhangMin 1 --outFilterMismatchNmax 999 --alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 --outFilterMatchNminOverLread 0.4 --outFileNamePrefix $NAME"_" --outSAMtype BAM Unsorted --outSAMattributes All --twopassMode Basic

###################################################################################################################################################################

echo -e "${gr}\nFiltering unique mapping reads...${nc}"

samtools view -H $NAME"_Aligned.out.bam" > $NAME.header.sam  # extract header only
samtools view -q 255 -b $NAME"_Aligned.out.bam" > $NAME.unique.bam
samtools view -c $NAME.unique.bam

echo -e "${gr}\nFiltering out PCR Duplicates...${nc}"

samtools rmdup -s $NAME.unique.bam $NAME.tmp
samtools reheader $NAME.header.sam $NAME.tmp > $NAME.unsorted.bam
samtools view -c $NAME.unsorted.bam

echo -e "${gr}\nSorting BAM File... $NAME.bam ${nc}"

samtools sort -@ $THR $NAME.unsorted.bam -o $NAME.bam

echo -e "${gr}\nIndexing BAM File... $NAME.bai ${nc}"

samtools index $NAME.bam

echo -e "${gr}\nCleaning up...${nc}"

rm *Aligned.out.bam $NAME"_clipped".fastq $NAME.unique.bam $NAME.header.sam $NAME.tmp $NAME.unsorted.bam
rm *Log.out *Log.progress.out *SJ.out.tab
rm -r *_STARgenome *_STARpass1 *_STARtmp

###################################################################################################################################################################

done
