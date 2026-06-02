#! /bin/bash

#Data should hold all orginal and raw/major intermediate files
#Results holds all the analytical outcomes & figures
#  mkdir data2 results2

# Retrieve raw data files

mkdir data2/untrimmed_fastq
cd data2/untrimmed_fastq
mv NexteraPE-PE.fa data2

curl -O ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_1.fastq.gz
curl -O ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/003/SRR2584863/SRR2584863_2.fastq.gz
curl -O ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/006/SRR2584866/SRR2584866_1.fastq.gz
curl -O ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/006/SRR2584866/SRR2584866_2.fastq.gz
curl -O ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/004/SRR2589044/SRR2589044_1.fastq.gz
curl -O ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR258/004/SRR2589044/SRR2589044_2.fastq.gz
cd ../../


# Perform basic quality control on our FASTQ files

# Run FASTQC

module load FastQC/0.12.1-Java-11 
fastqc data2/untrimmed_fastq/*.fastq.gz

#Move FASTQC result to appropriate results folder
mkdir results2/untrimmed_fastqc
mv data2/untrimmed_fastq/*.zip results2/untrimmed_fastqc
mv data2/untrimmed_fastq/*html results2/untrimmed_fastqc

#Combine FASTQC reports with multiQC
module load MultiQC/1.28-foss-2024a
 multiqc results2/untrimmed_fastqc -o results2/untrimmed_multiqc

#Trim FASTQ files with trimmomatic
ml Trimmomatic/0.39-Java-17
 mkdir data2/trimmed_fastq
 for fwd in data2/untrimmed_fastq/*_1.fastq.gz
 do
sample=$(basename $fwd _1.fastq.gz)
echo "Processing $sample"
trimmomatic PE data2/untrimmed_fastq/${sample}_1.fastq.gz data2/untrimmed_fastq/${sample}_2.fastq.gz \
               data2/trimmed_fastq/${sample}_1.trim.fastq.gz data2/trimmed_fastq${sample}_1un.trim.fastq.gz \
                data2/trimmed_fastq/${sample}_2.trim.fastq.gz data2/trimmed_fastq${sample}_2un.trim.fastq.gz \
                SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:data2/NexteraPE-PE.fa:2:40:15
 done



# Run FASTQC on trimmed

module load FastQC/0.12.1-Java-11 
fastqc data2/trimmed_fastq/*.fastq.gz

#Move trimmed FASTQC result to appropriate results folder
mkdir results2/trimmed_fastqc
mv data2/trimmed_fastq/*.zip results2/trimmed_fastqc
mv data2/trimmed_fastq/*html results2/trimmed_fastqc

#Combine trimmed FASTQC reports with multiQC
module load MultiQC/1.28-foss-2024a
multiqc results2/trimmed_fastqc -o results2/trimmed_multiqc


# Align trimmed reads to E. coli and call variants

# #Download ref genome
 mkdir data2/ref_genome
 curl -L -o data2/ref_genome/ecoli_rel606.fasta.gz ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/017/985/GCA_000017985.1_ASM1798v1/GCA_000017985.1_ASM1798v1_genomic.fna.gz
 gunzip data2/ref_genome/ecoli_rel606.fasta.gz 

# Index the reference genome
ml BWA/0.7.18-GCCcore-13.3.0
bwa index data2/ref_genome/ecoli_rel606.fasta

#Make output directories
mkdir results2/sam results2/bam results2/bcf results2/vcf

ml BWA/0.7.18-GCCcore-13.3.0
ml SAMtools/1.21-GCC-13.3.0
for fwd in data2/trimmed_fastq/*_1.trim.fastq.gz #do fwd and reveres files as a pair
 do
sample=$(basename $fwd _1.trim.fastq.gz) #Only print the beggining of the file name and script the end
 echo "Processing sample $sample"

 #Align
  bwa mem data2/ref_genome/ecoli_rel606.fasta \
   $fwd data2/trimmed_fastq/${sample}_2.trim.fastq.gz \
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
 -f data2/ref_genome/ecoli_rel606.fasta results2/bam/*.sorted.bam
 bcftools call --ploidy 1 -m -v -o results2/vcf/variants.vcf results2/bcf/variants.bcf
vcfutils.pl varFilter results2/vcf/variants.vcf > results2/vcf/variants_filtered.vcf





# counting how many variants,reads, and aligned reads
ml SAMtools/1.21-GCC-13.3.0

echo "sample, raw_reads, trimmed_reads, variants, aligned_reads" > summary_stats.csv

for fwd in data2/untrimmed_fastq/*_1.fastq.gz
 do
sample=$(basename $fwd _1.fastq.gz)
raw_reads=$(echo "$(zcat data2/untrimmed_fastq/${sample}_1.fastq.gz | wc -l) / 4" | bc) 
trimmed_reads=$(echo "$(zcat data2/trimmed_fastq/${sample}_1.trim.fastq.gz | wc -l) / 4" | bc)
aligned_reads=$(samtools view -F 0x4 results2/bam/${sample}.sorted.bam | wc -l)
variants=$(grep -v -E "^#" results2/vcf/variants_filtered.vcf | wc -l)
echo "${sample},${raw_reads},${trimmed_reads},${variants},${aligned_reads}" >> summary_stats.csv
done



