
export SAMPLE=Pool1_TRMT5_1
export BASEDIR=/home/lp471/DATA/1000ChIPs/

bwa aln -q 5 -l 32 -k 2 -t 1 /home/lp471/AQUAS/genome_data/hg38/bwa_index/GRCh38_no_alt_analysis_set_GCA_000001405.15.fasta $BASEDIR/$SAMPLE.fq.gz > $BASEDIR/out/align/rep1/$SAMPLE.sai

bwa samse /home/lp471/AQUAS/genome_data/hg38/bwa_index/GRCh38_no_alt_analysis_set_GCA_000001405.15.fasta $BASEDIR/out/align/rep1/$SAMPLE.sai $BASEDIR/$SAMPLE.fq.gz | samtools view -Su - | samtools sort - $BASEDIR/out/align/rep1/$SAMPLE

samtools index $BASEDIR/out/align/rep1/$SAMPLE.bam
samtools flagstat $BASEDIR/out/align/rep1/$SAMPLE.bam > $BASEDIR/out/qc/rep1/$SAMPLE.flagstat.qc

sambamba sort -t 1 $BASEDIR/out/align/rep1/$SAMPLE.bam -n -o $BASEDIR/out/align/rep1/$SAMPLE.qnmsrt.bam;

samtools view -h $BASEDIR/out/align/rep1/$SAMPLE.qnmsrt.bam | $(which assign_multimappers.py) -k 0 | \
sambamba sort -t 1 /dev/stdin -o $BASEDIR/out/align/rep1/$SAMPLE.filt.bam;

rm -f $BASEDIR/out/align/rep1/$SAMPLE.qnmsrt.bam;

samtools view -F 1804 -q 30 -u $BASEDIR/out/align/rep1/$SAMPLE.bam | \
sambamba sort -t 1 /dev/stdin -o $BASEDIR/out/align/rep1/$SAMPLE.filt.bam;

java -Xmx32G -jar picard.jar MarkDuplicates INPUT=$BASEDIR/out/align/rep1/$SAMPLE.filt.bam OUTPUT=$BASEDIR/out/align/rep1/$SAMPLE.dupmark.bam METRICS_FILE=$BASEDIR/out/qc/rep1/$SAMPLE.dup.qc REMOVE_DUPLICATES=false ASSUME_SORTED=true VALIDATION_STRINGENCY=LENIENT MAX_SEQUENCES_FOR_DISK_READ_ENDS_MAP=50000 MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=8000 SORTING_COLLECTION_SIZE_RATIO=0.25 PROGRAM_RECORD_ID=MarkDuplicates PROGRAM_GROUP_NAME=MarkDuplicates DUPLICATE_SCORING_STRATEGY=SUM_OF_BASE_QUALITIES READ_NAME_REGEX=[a-zA-Z0-9]+:[0-9]:([0-9]+):([0-9]+):([0-9]+).* OPTICAL_DUPLICATE_PIXEL_DISTANCE=100 VERBOSITY=INFO QUIET=false COMPRESSION_LEVEL=5 MAX_RECORDS_IN_RAM=500000 CREATE_INDEX=false CREATE_MD5_FILE=false

samtools view -F 1804 -b $BASEDIR/out/align/rep1/$SAMPLE.dupmark.bam > $BASEDIR/out/align/rep1/$SAMPLE.nodup.bam

sambamba index -t 1 $BASEDIR/out/align/rep1/$SAMPLE.nodup.bam

sambamba flagstat -t 1 $BASEDIR/out/align/rep1/$SAMPLE.nodup.bam > $BASEDIR/out/qc/rep1/$SAMPLE.nodup.flagstat.qc

bedtools bamtobed -i $BASEDIR/out/align/rep1/$SAMPLE.dupmark.bam | \
awk 'BEGIN{mt=0;m0=0;m1=0;m2=0} ($1==1){m1=m1+1} ($1==2){m2=m2+1} {m0=m0+1} {mt=mt+$1} END{m1_m2=-1.0; if(m2>0) m1_m2=m1/m2; printf "%d\t%d\t%d\t%d\t%f\t%f\t%f\n",mt,m0,m1,m2,m0/mt,m1/m0,m1_m2}' > $BASEDIR/out/qc/rep1/$SAMPLE.nodup.pbc.qc

