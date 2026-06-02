# counting how many variants,reads, and aligned reads
ml SAMtools/1.21-GCC-13.3.0

echo "sample, raw_reads, trimmed_reads, variants, aligned_reads" > summary_stats.csv # Creating csv file

for fwd in data2/untrimmed_fastq/*_1.fastq.gz
 do
sample=$(basename $fwd _1.fastq.gz)
raw_reads=$(echo "$(zcat data2/untrimmed_fastq/${sample}_1.fastq.gz | wc -l) / 4" | bc)  # counting raw reads
trimmed_reads=$(echo "$(zcat data2/trimmed_fastq/${sample}_1.trim.fastq.gz | wc -l) / 4" | bc) # counting trimmed reads
aligned_reads=$(samtools view -F 0x4 results2/bam/${sample}.sorted.bam | wc -l) #counting aligned reads
variants=$(grep -v -E "^#" results2/vcf/variants_filtered.vcf | wc -l) # counting variants. Not quite sure how to count per isolate. BCF tools maybe?
echo "${sample},${raw_reads},${trimmed_reads},${variants},${aligned_reads}" >> summary_stats.csv # Assigning outputs to variables 
done