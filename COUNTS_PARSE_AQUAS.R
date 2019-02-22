library(tidyverse)

system("ls *.fq.gz | parallel --progress -j 10 'echo \"1_RAW_READS\t\"{}\"\t\"$(($(zcat {} | wc -l ) / 4))' | sed -e \"s/.fq.gz//g\" >> COUNTS")

system("ls *.bam | grep -v nodup | parallel --progress -j 10 'echo -n \"2_MAPPING_READS\t\"{}\"\t\" & samtools view -F 4 -c {}' | sed -e \"s/.bam//g\" >> COUNTS")

system("ls *.nodup.bam | parallel --progress -j 10 'echo -n \"3_NODUP_MAPPING\t\"{}\"\t\" & samtools view -c {}' | sed -e \"s/.nodup.bam//g\" >> COUNTS")

counts <- read_tsv("COUNTS", col_names=c("Type","Sample","num")) %>%
	spread(key=Type, value=num) %>%
	mutate( Mappers = `2_MAPPING_READS` / `1_RAW_READS`, 
	 	PCRDup = 1 - (`3_NODUP_MAPPING` / `2_MAPPING_READS` ))

write_tsv(counts, path="COUNTS_AQUAS.xls")

system("rm COUNTS")
