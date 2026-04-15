#!/bin/bash

#PBS -lwalltime=01:00:00
#PBS -lselect=1:mem=15gb
#PBS -o nf.log
#PBS -e nf.err
#PBS -N nf_test

module load Nextflow

cd $PBS_O_WORKDIR

nextflow run nf-core/demo \
		-profile imperial \
		--input samplesheet.csv \
		--outdir nf_out 
