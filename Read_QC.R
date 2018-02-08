
## R script for Read_QC.sh 
## Rscript ReadQC.R folder/
## Version 1.0 (Osiris)
## 15 Mar 2017

library(ggplot2)
library(reshape2)
library(gridExtra)

multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)

  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)

  numPlots = length(plots)

  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                    ncol = cols, nrow = ceiling(numPlots/cols))
  }

 if (numPlots==1) {
    print(plots[[1]])

  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))

    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))

      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

args <- commandArgs(TRUE)
setwd(args[1])
feats<-read.csv('genomic_targets_distrib.txt', sep="\t", header=T, row.names=1)
featsraw<-feats
feats<-sweep(feats,2,colSums(feats),`/`)
feats<-100*feats
feats<-feats[rowSums(feats > 0.5) != 0,]
featsraw<-featsraw[rownames(feats),]
feats["Other",]<-100-colSums(feats)
newfeats<-melt(feats)
newfeats$feat<-rep(rownames(feats), ncol(feats))
colnames(newfeats)<-c("Sample","Counts","Features")

plt1<-ggplot(newfeats, aes(x=Sample, y=Counts, fill=Features)) + geom_bar(stat="identity") + theme(axis.text.x = element_text(angle = 90, hjust = 0))

summary<-read.csv('genomic_targets_summary.txt', sep="\t", header=F, row.names=1)
summary<-summary[c("Assigned", "Unassigned_Ambiguity", "Unassigned_NoFeatures"),]
colnames(summary)<-colnames(feats)
tot_counts<-colSums(summary)
summary<-sweep(summary,2,colSums(summary),`/`)
summary<-100*summary
newsummary<-melt(summary)
newsummary$feat<-rep(rownames(summary), ncol(summary))
colnames(newsummary)<-c("Sample","Counts","Type")
plt2<-ggplot(newsummary, aes(x=Sample, y=Counts, fill=Type)) + geom_bar(stat="identity") + theme(axis.text.x = element_text(angle = 90, hjust = 0))

tot_counts<-as.data.frame(tot_counts)
tot_counts<-cbind(tot_counts, rownames(tot_counts))
colnames(tot_counts)<-c("Counts", "Samples")
plt3<-ggplot(tot_counts, aes(x=Samples, y=Counts, fill="Raw_counts")) + geom_bar(stat="identity") + theme(axis.text.x = element_text(angle = 90, hjust = 0))

pdf("Mapping_QC.pdf", width=15, height=8)
multiplot(plt3, plt2, plt1, cols=3)
grid.arrange(tableGrob(featsraw))
dev.off()

