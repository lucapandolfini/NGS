#!/bin/bash
# 2018-06-51 ChIP Mapping Pipeline
#Usage ./bwa_ChIP_2species.sh Threads target_dir 2>&1 | tee mapping_report.log

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
echo "MAPPING $FILE..."
echo -e "${red}----------------------------------------------${nc}"

echo -e "${gr}Clipping Adaptor Sequences...${nc}"
java -jar $HOMEDIR/bin/Trimmomatic-0.35/trimmomatic-0.35.jar SE -threads $THR -phred33 $NAME.fq.gz $NAME"_clipped".fastq ILLUMINACLIP:$HOMEDIR/bin/Trimmomatic-0.35/adapters/ChIP_Seq_Bioo.fa:2:30:10 MINLEN:40

echo -e "${gr}Mapping with bwa...${nc}"
bwa aln -t $THR -n 3 -k 2 -R 300 ~/Genomes/hg38_mm10_spikein/hg38_mm10.fa $NAME"_clipped".fastq > $NAME.sai

done

echo -e "${red}Parallel generation of aligments...${nc}"
parallel -j 5 bwa samse -n 3 ~/Genomes/hg38_mm10_spikein/hg38_mm10.fa {} {.}"_clipped".fastq -f {.}.sam ::: *.sai
# Do not change job number! Risk of SWAP!

echo -e "${red}Bam Generation and sort...${nc}"
parallel -j 5 'samtools sort -@ 14 -O BAM {} > {.}.smap.bam' ::: *.sam
# Do not change job number! Risk of SWAP!

for i in *.smap.bam
do
FILE=$i
NAME="${FILE/.smap.bam/}"
echo -e "${gr}$NAME: Removing PCR duplicates...${nc}"
java -jar ~/bin/picard2.18.jar MarkDuplicates INPUT=$NAME.smap.bam OUTPUT=$NAME.unsorted.bam METRICS_FILE=$NAME.dup.qc REMOVE_DUPLICATES=true ASSUME_SORTED=true VALIDATION_STRINGENCY=LENIENT MAX_SEQUENCES_FOR_DISK_READ_ENDS_MAP=50000 MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=8000 SORTING_COLLECTION_SIZE_RATIO=0.25 DUPLICATE_SCORING_STRATEGY=SUM_OF_BASE_QUALITIES OPTICAL_DUPLICATE_PIXEL_DISTANCE=100 VERBOSITY=INFO QUIET=false COMPRESSION_LEVEL=5 MAX_RECORDS_IN_RAM=500000 CREATE_INDEX=false CREATE_MD5_FILE=false
done

echo -e "${red}Parallel sample parsing...${nc}"
ls *.unsorted.bam | parallel -j 10 bwa_ChIP_2species_engine.sh {}
