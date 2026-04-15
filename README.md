# nf_core pipelines on the Imperial HPC

Walk through of setting-up nf-core workflows on the Imperial HPC

# Why do we need a pipeline? How might we create one?

We probably have learnt a few commands that, when joined together, can form the basis for a minimal analysis pipeline

- use `fastqc` to create QC reports for each sample
- use `multiqc` to combine the QC
- index a reference transcriptome using `salmon`
- produce a set of quantified genes using `salmon`

The next natural step would be to record these commands in a *script* so that we can document our analysis and re-run as required. We don't usually have a text editor in our Unix environment, such a script might start as follows:-

```{bash}
fastqc fastq/*.fastq.gz
mkdir -p qc/
mv fastq/*.html qc/
mv fastq/*.zip qc
multiqc -f -o qc/ qc
```

This will run through the QC steps of the pipeline. The next stage (for example) would be to add the steps for `salmon` quantification. Since we want the ability to re-run the whole pipeline from scratch if required, we need to add the step to create the salmon index

```{bash}
salmon index -i index/GRCh38_salmon -t ref_data/Homo_sapiens.GRCh38.cdna.fa
salmon quant -i index/GRCh38_salmon --libType A -r fastq/SAMPLE1.fastq.gz -o quant/SAMPLE1
```

Our pipeline is already quite short and is running on a small dataset, but can already take a little while to run and is using several pieces of software. The pipeline has been written in a linear fashion, so that each step must be completed in order. If our salmon alignment code needed to be changed we would have to re-run all the QC. This is not a huge problem here, but could be quite inefficient for a more-realistic dataset.

We also have a number of options for how to proceed with quantifying the remaining samples. The simplest approach copy-and-paste the `salmon quant` line with different sample names

```{bash}
salmon quant -i index/GRCh38_salmon --libType A -r fastq/SAMPLE2.fastq.gz -o quant/SAMPLE2
salmon quant -i index/GRCh38_salmon --libType A -r fastq/SAMPLE3.fastq.gz -o quant/SAMPLE3
###etc....

```

This is not particularly satisfactory as it is prone to typos or other errors. An alternative might be to employ a *for loop*, which you might have come across previously or take advantage of parallelisation options on a HPC. There is a better solution for tackling this, which also solves a lot of housekeeping tasks associated with processing large amounts of data.

# Why do we need a workflow manager?

As we have discussed, there are a number of options to extend our pipeline to multiple samples. These require more programming knowledge than we might be comfortable with. There are a few other issues with the script that we have created.

- As pipeline steps have to be re-run in sequence; even if the initial pipeline steps ran sucessfully they will still be re-run every time
  - Sample 2 is processed only once Sample 1 is completed etc
- There is no error-checking. 
  - We need to check that Sample 1 actually completed successfully
- A lot of temporary files will be created that can take up a lot of space
- The pipeline will not necessarily run on another environment as it will assume that the `fastqc`, `multiqc` and `salmon` tools can be found.


It wasn't that long ago that each institute, research group would have it's own pipeline, often covering the same steps, that had to be configured slightly differently for the nuances of their HPC setup. It was extremely challenging to *exactly* reproduce work from another lab even if you had all the same software installed. 

Unless you are doing something very novel or bespoke **we would recommend people re-using existing analysis pipelines rather than writing their own**. We will look at an example using the nextflow workflow manager, although similar tools such as snakemake are also popular in Bioinformatics.

- [nextflow](https://www.nextflow.io/)
- [snakemake](https://snakemake.readthedocs.io/en/stable/)

Fortunately, `nextflow` is available as a *module* on the Imperial HPC. Once you have logged-in in the usual fashion.

```
## Note the capitalisation of Nextflow
ml load Nextflow
nextflow
```


## Running a nf-core pipeline

In our opinion, nextflow is the prefered solution to running pipeline. It is particularly appealing as many popular Bioinformatics pipelines have already been written using nextflow and have been distributed as part of the nf-core project

- [nf.core homepage](https://nf-co.re/)

We will start by getting a small "demo" pipeline running, before progressing to the RNA-seq one

- [nf-core demo pipeline](https://nf-co.re/demo/1.1.0/)

![](https://raw.githubusercontent.com/nf-core/demo/1.1.0//docs/images/nf-core-demo-subway.png)


- [nf.core RNA-seq pipeline](https://nf-co.re/rnaseq)

![](https://raw.githubusercontent.com/nf-core/rnaseq/3.24.0//docs/images/nf-core-rnaseq_metro_map_grey_animated.svg)


The RNA-seq pipeline looks (and indeed is) a lot more complicated, but in fact the setup and running is not much more challenging than the demo pipeline

## Running the nf-core demo pipeline


After logging into the HPC, create a directory (`mkdir`) where you want to run the demo pipeline. You need to create two files. The first is a job submission script, which I have called `nf_run.sh`. There is a copy of the script also on the github repo

- [Link to submission script](nf_run.sh)

```{bash}
#!/bin/bash

#PBS -lwalltime=01:00:00
#PBS -lselect=1:mem=15gb
#PBS -o nf.log
#PBS -e nf.err
#PBS -N nf_test

module load Nextflow

#make sure a tmp folder required by singularity exists
mkdir -p /rds/general/user/${USER}/ephemeral/tmp/

cd $PBS_O_WORKDIR

nextflow run nf-core/demo \
		-profile imperial \
		--input demo_samplesheet.csv \
		--outdir nf_out 
```

The header of the script defines the HPC settings in the usual manner. I have picked a short runtime and low amount of RAM as this pipeline doesn't require much resource. A temporary folder also needs to be created where any temporary files required by the pipeline will be installed to. In particular it will download the software required for the pipeline.

We then have to load the Nextflow module and make sure that our working directory is set to the directory that the job is submitted from. 

The command to run and install the pipeline is `nextflow run` followed by the options for the particular pipeline that you want to use. The options shown here are quite typical to all nf-core pipelines and two are fairly self-explanatory:-

- `input`; pointing to a csv file defining the locations of the input files (i.e. your fastq)
- `outdir`; where the outputs of the pipeline will be written to

A short explanation of `profile` is that it tells nextflow how to behave on your institutes HPC. Users and institutes are able to create configuration files that can be distributed and reused and define things like what "containerisation" (see later) approach to use, and the job scheduler on the HPC. Fortunately we don't have to work these out for ourselves as someone has already created an imperial one. If you are curious you can see the contents on github

- [Imperial profile](https://github.com/nf-core/configs/blob/master/conf/imperial.config)

You will then need the sample sheet, a copy of which can also be found on the github repo

- [Link to sample sheet](demo_samplesheet.csv)

This is comma-separated and defines the locations on our input fastq files, plus a sample identifier used to name the outputs. The entries in the `fastq_1` and `fastq_2` (which can also be blank) can either point to files on the HPC or remote files. Be aware that some pipelines will have different requirements for the columns in this file, so it's recommended to check the documentation.

```{bash}
sample,fastq_1,fastq_2
SAMPLE1_PE,https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample1_R1.fastq.gz,https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample1_R2.fastq.gz
SAMPLE2_PE,https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample2_R1.fastq.gz,https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample2_R2.fastq.gz
SAMPLE3_SE,https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample1_R1.fastq.gz,
SAMPLE3_SE,https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/illumina/amplicon/sample2_R1.fastq.gz,
```

We can then submit, and wait

```{bash}
qsub nf_run.sh
```

When the pipeline is running, you can try a few different things to monitor the progress

- using the `qstat -u $USER` command to see what is currently running. As nextflow is utilising the HPC you should see several jobs being run at the same time. You might also notice that different RAM and time requirements are specified for different jobs. 
- the `nf_out/pipeline_info` folder (which may take a few moments to be created) contains an `execution_trace_` txt file which will be named with a time stamp. This is a log of what steps of the pipeline have been run.

The log and error files get written to your working folder after the pipeline finishes, and all outputs are written to `nf_out`. 

## Running an RNA-seq pipeline

When using an nf-core pipeline for the first time you have the option of using a small test dataset that has been compiled. This can be activated by adding `test` to the profile argument:-

```{bash}
#!/bin/bash

#PBS -lwalltime=01:00:00
#PBS -lselect=1:mem=15gb
#PBS -o nf.log
#PBS -e nf.err
#PBS -N nf_test

module load Nextflow

cd $PBS_O_WORKDIR

nextflow run nf-core/rnaseq \
		-profile test,imperial \
		--outdir nf_out
```

The run command was mostly the same as before, except we are using `nf-core/rnaseq` instead of the demo pipeline. We didn't need to specify a sample sheet, as it automatically downloaded a small test dataset. In real-life there are a few more options you might want to change, so lets look at this using a published dataset. A number of example files are available that you can use as a template

- [download.sh](rnaseq/download.sh)
- [nf_run_full.sh](rnaseq/nf_run_full.sh)
- [nf_samplesheet.csv](rnaseq/nf_samplesheet.csv)
- [rnaseq_human.yml](rnaseq/rnaseq_human.yml)

You can specify what reference data you want to use for alignment and annotation, and I have chosen to use Ensembl as my source. As I will want to re-use the same references I have created a small configuration file that points to the locations of these files. Having your parameters in a file such as this makes the job submission code a bit cleaner, and means you can re-analyse the same dataset with slightly different parameters by pointing to different config files. You can also reuse the same set of parameters on multiple projects.

I've also shown how to specify a particular alignment strategy (which is a bit redundant in this case as `star_salmon` is the default anyway) and in general you have quite a bit of flexibility with regards to the tools run at specific stages. If you need the results really quick, you can even turn off full genome alignment as use the `--skip_alignment` and `--pseudo-aligner salmon` options. For a full list of parameters you can consult the documentation:-

- [rnaseq pipeline parameters](https://nf-co.re/rnaseq/3.24.0/parameters/)

```{bash}
## rnaseq_human.yml
fasta: "ref_data/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa"
gtf: "ref_data/Homo_sapiens.GRCh38.115.gtf"
aligner: "star_salmon"
```



The job submission command is as follows. Notice that the RAM specification is still quite low. This resource refers to the `nextflow` command itself and **NOT** any of the subsequent jobs that it will submit. It is a good idea to keep this low (a few Gb) to keep the wait time for the pipeline to start to a minimum. The `walltime` might need to be quite long, as this refers to the total time taken to the run the pipeline, and not the time allocation of any specific tasks. 

```{bash}
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

```

I've added the `resume` flag to this pipeline run. This is a very good habit to get into if you are running longer pipelines and / or processing many samples. In the case of a pipeline error, which could be due to HPC downtime rather than something you did wrong, the next time you run the pipeline it will commence at the same stage the previous run failed. i.e. if the QC has already been completed it won't bother repeating the QC steps. This can be a huge time saver.


One important point to note is that the pipeline will perform QC using `DESeq2`, but does not do any kind of differential expression or downstream analysis. You will still need to use R for this ;) You do however get all the outputs you will need in the `nf_out/star_salmon` folder including txt and rds files that can be loaded directly into R.


### Tips for usage

- using a particular pipeline version; nextflow will automatically run the latest version of a pipeline that is available from github. This version is reported in the log file created by the pipeline. 
  + adding the flag `nextflow run nf-core/rnaseq -r 3.24.0` will make sure that the specific version 3.24.0 is used.
- working directory location; The work folder that nextflow creates can get rather large. There is a space quote on the home folders on Imperial HPC of 1Tb. This can get quickly used up. The contents on the work folder are not usually required once the pipeline has finished, so are ideal to be put in a temporary folder. For a dataset of around 100 samples I found I had to set a different location for the working directory to stop all my home drive being used up.
  + `-w ${EPHEMERAL}/work/rnaseq-aging`
- a shared location for reference genomes; 
- use version control (github); the configuration files, parameters and sample sheet used by nf-core are all really small and ideal for tracking with github for reproducibility. I also keep the execution traces and log files afterwards if needed. You can use the `.gitignore` file to make sure that large output files are excluded from github.
