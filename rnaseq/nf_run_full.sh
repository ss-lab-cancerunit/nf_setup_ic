#!/bin/bash

#PBS -lwalltime=12:00:00
#PBS -lselect=1:ncpus=1:mem=5gb
#PBS -o nf_rnaseq_full.log
#PBS -e nf_rnaseq_full.err
#PBS -N nf_rnaseq_full

module load Nextflow

cd $PBS_O_WORKDIR

nextflow run nf-core/rnaseq -profile imperial \
		--outdir nf_out \
		--input nf_samplesheet.csv \
		-params-file rnaseq_human.yml \
		-resume
