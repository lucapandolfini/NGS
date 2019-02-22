library(tidyverse)
args <- commandArgs(TRUE)

counts <- read_tsv(args[1], col_names=c("Type","Sample","num")) %>%
	spread(key=Type, value=num) %>%
	mutate( Adaptors = 1 - (`1_CLIPPED_READS` / `0_RAW_READS`), 
	 	SingleMappers = `3_SINGLE_MAPPING` / `2_MAPPING_READS`, 
	 	PCRDup = 1 - (`4_NODUP_MAPPING` / `3_SINGLE_MAPPING` ), 
	 	Spikein = `5_MOUSE` / (`5_HUMAN` + `5_MOUSE`))

write_tsv(counts, path="COUNTS.xls")
