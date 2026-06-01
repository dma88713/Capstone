#! /bin/bash

# Align trimmed reads to E. coli and call variants

# #Download ref genome
 mkdir data/ref_genome
 curl -L -o data/ref_genome/ecoli_rel606.fasta.gz ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/017/985/GCA_000017985.1_ASM1798v1/GCA_000017985.1_ASM1798v1_genomic.fna.gz
 gunzip data/ref_genome/ecoli_rel606.fasta.gz 

# Index the reference genome
ml BWA/0.7.18-GCCcore-13.3.0
bwa index data/ref_genome/ecoli_rel606.fasta

#Make output directories
mkdir results2/sam results2/bam results2/bcf results2/vcf

ml BWA/0.7.18-GCCcore-13.3.0
ml SAMtools/1.21-GCC-13.3.0
for fwd in data/trimmed_fastq/*_1.trim.fastq.gz #do fwd and reveres files as a pair
 do
sample=$(basename $fwd _1.trim.fastq.gz) #Only print the beggining of the file name and script the end
 echo "Processing sample $sample"

#   #Align
  bwa mem data/ref_genome/ecoli_rel606.fasta \
   $fwd data/trimmed_fastq/${sample}_2.trim.fastq.gz \
> results2/sam/${sample}.sam

 # Convert to bam format
samtools view -S -b results2/sam/${sample}.sam \
 > results2/bam/${sample}.bam

#Sort & index the bam file

samtools sort -o results2/bam/${sample}.sorted.bam results2/bam/${sample}.bam
samtools index results2/bam/${sample}.sorted.bam
done

 #Variant calling
ml BCFtools/1.23.1-GCC-13.3.0
bcftools mpileup -O b -o results2/bcf/variants.bcf \
 -f data/ref_genome/ecoli_rel606.fasta results2/bam/*.sorted.bam
 bcftools call --ploidy 1 -m -v -o results2/vcf/variants.vcf results2/bcf/variants.bcf
vcfutils.pl varFilter results2/vcf/variants.vcf > results2/vcf/variants_filtered.vcf

