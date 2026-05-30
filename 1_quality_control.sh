# #! /bin/bash

# # Perform basic quality control on our FASTQ files

# # Run FASTQC

#module load FastQC/0.12.1-Java-11 
#fastqc data/untrimmed_fasta/*.fastq.gz

#Move FASTQC result to appropriate results folder
#mkdir results2
#mkdir results2/untrimmed_fastqc
#mv data/untrimmed_fasta/*.zip results2/untrimmed_fastqc
#mv data/untrimmed_fasta/*html results2/untrimmed_fastqc

# #Combine FASTQC reports with multiQC
# module load MultiQC/1.28-foss-2024a
 #multiqc results2/untrimmed_fastqc -o results2/untrimmed_multiqc

# #Trim FASTQ files with trimmomatic
# ml Trimmomatic/0.39-Java-17
 #mkdir data/trimmed_fastq
 #for fwd in data/untrimmed_fasta/*_1.fastq.gz
 #do
#sample=$(basename $fwd _1.fastq.gz)
#echo "Processing $sample"
#trimmomatic PE data/untrimmed_fasta/${sample}_1.fastq.gz data/untrimmed_fasta/${sample}_2.fastq.gz \
#                data/trimmed_fastq/${sample}_1.trim.fastq.gz data/trimmed_fastq${sample}_1un.trim.fastq.gz \
 #                data/trimmed_fastq/${sample}_2.trim.fastq.gz data/trimmed_fastq${sample}_2un.trim.fastq.gz \
  #               SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:data/NexteraPE-PE.fa:2:40:15
 #done

# Run FASTQC on trimmed

# module load FastQC/0.12.1-Java-11 
# fastqc data/trimmed_fastq/*.fastq.gz

#Move trimmed FASTQC result to appropriate results folder
#mkdir results2/trimmed_fastqc
#mv data/trimmed_fastq/*.zip results2/trimmed_fastqc
#mv data/trimmed_fastq/*html results2/trimmed_fastqc

#Combine trimmed FASTQC reports with multiQC
#module load MultiQC/1.28-foss-2024a
#multiqc results2/trimmed_fastqc -o results2/trimmed_multiqc









