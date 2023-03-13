# genelab_analysis
files are placed in the GLDS_### directory
expects merged bam files to be located at ./bams/merged

submit run_splice.sh to qsub

run_splice.sh runs wrap_splicer.sh

wrap_splicer.sh takes the input for the refernce files and loops through the .bam files found at ./bams/merged
the loop creates a folder named for the bam file, 

calls samtools to expand the bam to sam, 

runs the spliceGrapher-light.sh, 

spliceGrapher-light.sh runs the splicegrapher protocol and then cleans up the extra sam files created,

finally the wrap_splicer.sh removes the expanded sam file and starts the loop again with the next bam file found in the ./bams/merged directory
