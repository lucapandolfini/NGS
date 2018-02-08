#!/bin/bash
#
#
#
#   SampleSheet.csv:
#
#   FCID,Lane,Sample_ID,SampleRef,Index,Description,Control,Recipe,Operator,SampleProject
#   000000000-A8JAP,1,p0ant,no_ref,TGACCA,NA,N,NA,NA,NA
#   000000000-A8JAP,1,p0post,no_ref,ACAGTG,NA,N,NA,NA,NA
#   000000000-A8JAP,1,e12,no_ref,GCCAAT,NA,N,NA,NA,NA
#   000000000-A8JAP,1,div16,no_ref,CAGATC,NA,N,NA,NA,NA
#   000000000-A8JAP,1,div20,no_ref,ACTTGA,NA,N,NA,NA,NA
#
#
#   RunInfo.xml:
#
#   Remove Numbers= da <reads> and place file RunInfo.xml one level above the folder containing "Data", "intensities", ecc..
#
#
#

BPATH=/home/ngsuser/Bcl_files/2014.04.05_miRNA_marco
OUT_FASTQ_NAME=2014.04.05_miRNA_marco

/usr/local/bin/configureBclToFastq.pl --input-dir $BPATH/Intensities/BaseCalls --output-dir /home/ngsuser/Fastq/baseCalled --sample-sheet $BPATH/Intensities/BaseCalls/SampleSheet.csv --no-eamss --adapter-sequence /usr/local/share/bcl2fastq-1.8.4/adapters/TruSeq_r2.fa --use-bases-mask Y50,I6 --fastq-cluster-count 0

cd /home/ngsuser/Fastq/baseCalled

time nohup make -j 11

mkdir /home/ngsuser/Fastq/$OUT_FASTQ_NAME

cd /home/ngsuser/Fastq/baseCalled/Project_NA

cp Sample_*/*.gz /home/ngsuser/Fastq/$OUT_FASTQ_NAME/

rm -r /home/ngsuser/Fastq/baseCalled/
