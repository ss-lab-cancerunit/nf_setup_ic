#!/usr/bin/env bash

#make required directories
mkdir -p fastq
mkdir -p ref_data

## download from the URLs given by SRA explorer: https://sra-explorer.info
wget -P fastq ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR732/ERR732904/ERR732904.fastq.gz
wget -P fastq ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR732/ERR732908/ERR732908.fastq.gz
wget -P fastq ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR732/ERR732906/ERR732906.fastq.gz
wget -P fastq ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR732/ERR732902/ERR732902.fastq.gz
wget -P fastq ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR732/ERR732903/ERR732903.fastq.gz
wget -P fastq ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR732/ERR732901/ERR732901.fastq.gz
wget -P fastq ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR732/ERR732907/ERR732907.fastq.gz
wget -P fastq ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR732/ERR732905/ERR732905.fastq.gz
wget -P fastq ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR732/ERR732909/ERR732909.fastq.gz


## get the reference data of your choice
wget -P ref_data https://ftp.ensembl.org/pub/release-115/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz
gunzip ref_data/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz

wget -P ref_data  https://ftp.ensembl.org/pub/release-115/gtf/homo_sapiens/Homo_sapiens.GRCh38.115.gtf.gz
gunzip ref_data/Homo_sapiens.GRCh38.115.gtf.gz
