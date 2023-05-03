#!/usr/bin/bash

REF_FASTA="../SpliceGrapher_Files/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa"
REF_GTF="../SpliceGrapher_Files/Arabidopsis_thaliana.TAIR10.56.gtf"
REF_GFF3="../SpliceGrapher_Files/Arabidopsis_thaliana.TAIR10.56.gff3"
REF_CLASSIFIER="../SpliceGrapher_Files/classifiers.zip"

echo "Using the following reference files:"
echo $REF_FASTA
echo $REF_GTF
echo $REF_GFF3
echo $REF_CLASSIFIER
echo ""

# Move into the folder with the bams
cd ./bams/merged

# For every .bam file found in ./bams/merged...
for bam in *.bam; do

    # Create a container folder named for the bam file
    mkdir -p ../../$bam
    echo "Created directory ../../$bam"

    # Convert the bam to a sam (until pysam is fixed)
    samtools view -h --threads 8 $bam > ../../$bam/$bam.sam
    echo "SAM file created ../../$bam/$bam.sam"

    # Return to GLDS-XXX directory
    cd ../../

    # run the spliceGrapher script
    echo "Running spliceGrapher-light.sh"
    sh spliceGrapher-light.sh \
    -i ./$bam/$bam.sam \
    -f $REF_FASTA \
    -t $REF_GTF \
    -g $REF_GFF3 \
    -c $REF_CLASSIFIER \
    -o $bam

    # Remove the large sam
    rm -f ./$bam/$bam.sam
    echo "Removed ./$bam/$bam.sam"

    # Move into the folder with the bams
    cd ./bams/merged
done
