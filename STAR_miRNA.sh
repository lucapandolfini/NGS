#!/bin/bash

## Usage:
## ./STAR_miRNA.sh targetDirectory threads genome 2>&1 | tee mapping_report.log
## Version 1.0 (Osiris)
## 8 May 2017

red='\033[0;31m'
nc='\033[0m'
gr='\033[0;32m'

cd $1
THR=$2
HOMEDIR=/home/lp471
GENOME=$3 ## either mm10 or hg38

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
java -jar $HOMEDIR/bin/Trimmomatic-0.35/trimmomatic-0.35.jar SE -threads $THR -phred33 $NAME.fastq.gz $NAME"_clipped".fastq ILLUMINACLIP:$HOMEDIR/bin/Trimmomatic-0.35/adapters/adapter.fa:2:30:10 MINLEN:10

###################################################################################################################################################################

echo -e "${gr}\nMapping Reads with STAR...${nc}"

STAR --runMode alignReads --runThreadN $THR --genomeDir $HOMEDIR/Genomes/$GENOME/STAR50/ --sjdbOverhang 49 --readFilesIn $NAME"_clipped".fastq  --outFileNamePrefix $NAME"_" --outSAMtype BAM Unsorted --outSAMattributes All --outFilterMismatchNoverLmax 0.17 --outFilterMatchNmin 15 --outFilterScoreMinOverLread 0  --outFilterMatchNminOverLread 0 --alignIntronMax 1

###################################################################################################################################################################

#echo -e "${gr}\nFiltering unique mapping reads... $NAME.bam ${nc}"				## Normally disable multimapper filtering for miRNA (iso-mirs)

#samtools view -@ $THR -q 255 -b $NAME"_Aligned.out.bam" > $NAME.tmp
#samtools view -c $NAME.tmp

echo -e "${gr}\nSorting BAM File... $NAME.bam ${nc}"

samtools sort -@ $THR $NAME"_Aligned.out.bam" -o $NAME.bam

echo -e "${gr}\nIndexing BAM File... $NAME.bai ${nc}"

samtools index $NAME.bam

echo -e "${gr}\nCleaning up...${nc}"

rm *Aligned.out.bam $NAME"_clipped".fastq
rm *Log.out *Log.final.out *Log.progress.out *SJ.out.tab 					#$NAME.tmp

echo -e "${gr}\nCounting miRNA...${nc}"

featureCounts -M -T $THR -t miRNA -g Name -a  $HOMEDIR/Genomes/$GENOME/miRNA.gff3 -o $NAME.counts_mi.txt $NAME.bam

###################################################################################################################################################################

done

echo -e "${red}\nMerging miRNA counts...${nc}"
echo -e "${red}----------------------------------------------${nc}"

for i in *.counts_mi.txt
do
echo $i
cut -d $'\t' -f7 $i | sed 1d > $i.strip
cut -d $'\t' -f1 $i | sed 1d > annotation
done

paste -d $'\t' *.strip > tmp
paste -d $'\t' annotation tmp > merged_counts.miRNA.txt

rm *.strip
rm annotation
rm tmp
rm *.counts_mi.txt *counts_mi.txt.summary
