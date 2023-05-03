#!/bin/bash
# Usage function, needs to be declared before called
usage() {
        echo "Usage: spliceGrapher-Pipeline.sh -i sam_file -f reference_fasta_file -t reference_gtf_file -g reference_gff3_file -c species_classifer.zip_file 
-o output_base"
        echo "Arguments can be in any order, but all must be set"
}

# Get args
while getopts "f:t:o:i:g:c:h" flag
do
        case "${flag}" in
                f) FASTA=${OPTARG};;
                t) GTF=${OPTARG};;
                o) OUTPUT=${OPTARG};;
                i) INPUT=${OPTARG};;
                g) GFF=${OPTARG};;
                c) CLASSIFIER=${OPTARG};;
                h) usage;;
                *) usage;;
        esac
done

[ -z "$FASTA" ] && { echo "Reference fasta file not set"; usage;  exit 1; }
[ -z "$GTF" ] && { echo "Reference gtf file not set"; usage; exit 1; }
[ -z "$OUTPUT" ] && { echo "Output base not set"; usage; exit 1; }
[ -z "$INPUT" ] && { echo "Sam file not set"; usage; exit 1; }
[ -z "$GFF" ] && { echo "Reference gff3 file not set"; usage; exit 1; }
[ -z "$CLASSIFIER" ] && { echo "Species specific classifier.zip file not set"; usage; exit 1; }


# Make sure the files exist that need to
[ ! -f "$FASTA" ] && { echo "Reference fasta file $FASTA not found"; exit 1; }
[ ! -f "$GTF" ] && { echo "Reference gtf file $GTF not found"; exit 1; }
[ ! -f "$INPUT" ] && { echo "Sam file $INPUT not found"; exit 1; }
[ ! -f "$GFF" ] && { echo "Reference gff3 $GFF file not found"; exit 1; }
[ ! -f "$CLASSIFIER" ] && { echo "Species specific classifier.zip $CLASSIFIER file not found"; exit 1; }

# Now run the sam_filter.py
echo "Running sam_filter.py"
sam_filter.py "$INPUT" "$CLASSIFIER" -f "$FASTA" -m "$GTF" -o ./"$OUTPUT"/filtered.sam -F ./"$OUTPUT"/falsepositive.sam -r ./"$OUTPUT"/sam_filter_report.txt

# Sort the sam files. Could use samtools, but use sort in case it isn't installed
#sort -k 3,3 -k 4,4n filtered.sam > filtered_sorted.sam
echo "Running sort on filtered sam file"
samtools sort ./"$OUTPUT"/filtered.sam -o ./"$OUTPUT"/filtered_sorted.sam

# Generate depth file
echo "Generating depth file"
sam_to_depths.py ./"$OUTPUT"/filtered_sorted.sam -o ./"$OUTPUT"/sorted.depths

# Predict splice graphs
echo "Predicting splice graphs"
predict_graphs.py ./"$OUTPUT"/sorted.depths -m "$GTF" -d ./"$OUTPUT"/graphs_predicted

# Generate statistics
echo "Generating statistics"
cd ./"$OUTPUT"/graphs_predicted
for i in *; do
        find $PWD/$i/ -name "*.gff" > ./chr${i}.lis
        splicegraph_statistics.py -a ./chr${i}.lis -o ../chr${i}_stat
        genewise_statistics.py ./chr${i}.lis -C -o ../chr${i}_summary.csv
done
cd ../../

# Convert filtered_sorted.sam to bam
echo "Converting filtered_sorted.sam to bam"
samtools view --threads 8 -S -b ./"$OUTPUT"/filtered_sorted.sam > ./"$OUTPUT"/filtered_sorted.bam

# Create mpileup file to use for varscan
echo "Creating mpileup file"
samtools mpileup -f $FASTA ./"$OUTPUT"/filtered_sorted.bam > ./"$OUTPUT"/${OUTPUT}.mpileup

# Run varscan with the mpileup file
echo "Running varscan"
java -jar /nfs5/BPP/Jaiswal_Lab/bin/VarScan.v2.3.9.jar mpileup2snp ./"$OUTPUT"/${OUTPUT}.mpileup --min-reads2 20 --p-value 0.01 --output-vcf > ./"$OUTPUT"/${OUTPUT}_snp.vcf

# Remove the sams to save space
rm -f ./"$OUTPUT"/filtered_sorted.sam
rm -f ./"$OUTPUT"/filtered.sam

# Move leftovers into output dir
mv gt_don.* ./"$OUTPUT"/
mv gc_don.* ./"$OUTPUT"/
mv ag_acc.* ./"$OUTPUT"/
