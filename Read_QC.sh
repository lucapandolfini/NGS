#!/bin/bash

## Usage:
## ./Read_QC.sh targetDirectory threads gff3
## Version 1.0 (Osiris)
## 8 May 2017

## To generate unique Gencode annotation
## sed "s/gene_type=Pseudo_tRNA/gene_type=Ps-tRNA/g" '/home/luca/Desktop/gencode.v25.tRNAs.gff3' | sed "s/gene_type=[a-zA-Z0-9\(\)]\+_tRNA/gene_type=tRNA/g" | grep -v "#"  | sed "s/\ttRNA\t/\texon\t/g"> global.trna
## cat gencode.v25.annotation.gff3 global.trna > hg38_gencode.v25.annotation.gff3

red='\033[0;31m'
nc='\033[0m'
gr='\033[0;32m'

cd $1
THR=$2
GENOMEAnn=$3
RSCRIPTPath=~/Scripts/Read_QC.R

for i in *.bam
do

FILE=$i
NAME="${FILE/.bam/}"

echo -e "${red}\n"
date
echo "PROCESSING $FILE..."
echo -e "${red}----------------------------------------------${nc}"

featureCounts -M -a  $GENOMEAnn -o $NAME.counts.txt -t exon -g gene_type -s 1 -T $THR $NAME.bam  ## Count also multimappers

###################################################################################################################################################################

done

echo -e "${red}\nMerging Genomic counts...${nc}"
echo -e "${red}----------------------------------------------${nc}"

for i in *.counts.txt
do
echo $i
cut -d $'\t' -f7 $i | sed 1d > $i.strip
cut -d $'\t' -f1 $i | sed 1d > annotation
done

paste -d $'\t' *.strip > tmp
paste -d $'\t' annotation tmp > genomic_targets_distrib.txt

rm *.strip
rm annotation
rm tmp
rm *.counts.txt 

for i in *.counts.txt.summary
do
cut -d $'\t' -f2 $i | sed 1d > $i.strip
cut -d $'\t' -f1 $i | sed 1d > annotation
done

paste -d $'\t' *.strip > tmp
paste -d $'\t' annotation tmp > genomic_targets_summary.txt

rm *.strip
rm annotation
rm tmp
rm *.counts.txt.summary

echo -e "${red}\nRunning QC on .bam files...${nc}"
echo -e "${red}----------------------------------------------${nc}"

fastqc -t $THR *.bam

echo -e "${red}\nPlotting stats...${nc}"
echo -e "${red}----------------------------------------------${nc}"

Rscript $RSCRIPTPath $1

#rm genomic_targets_distrib.txt genomic_targets_summary.txt

mkdir Mapping_QC
mv *_fastqc.zip Mapping_QC/
mv *_fastqc.html Mapping_QC/
mv Mapping_QC.pdf Mapping_QC/
