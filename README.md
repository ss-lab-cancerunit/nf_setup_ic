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
salmon index -i index/GRCh38_salmon -t ref_data/Homo_sapiens.GRCh38.cdna.chr22.fa
salmon quant -i index/GRCh38_salmon --libType A -r fastq/ERR732901_sub.fastq.gz -o quant/ERR732901
```

Our pipeline is already quite short and is running on a small dataset, but can already take a little while to run and is using several pieces of software. The pipeline has been written in a linear fashion, so that each step must be completed in order. If our salmon alignment code needed to be changed we would have to re-run all the QC. This is not a huge problem here, but could be quite inefficient for a more-realistic dataset.

We also have a number of options for how to proceed with quantifying the remaining samples. The simplest approach copy-and-paste the `salmon quant` line with different sample names

```{bash}
salmon quant -i index/GRCh38_salmon --libType A -r fastq/ERR732902_sub.fastq.gz -o quant/ERR732902
salmon quant -i index/GRCh38_salmon --libType A -r fastq/ERR732903_sub.fastq.gz -o quant/ERR732903
###etc....

```

This is not particularly satisfactory as it is prone to typos or other errors. An alternative might be to employ a *for loop*, which you might have [come across previously](https://datacarpentry.org/shell-genomics/04-redirection/index.html) or take advantage of parallelisation options on a HPC. 

# Why do we need a workflow manager?

As we have discussed, there are a number of options to extend our pipeline to multiple samples. These require more programming knowledge than we might be comfortable with. There are a few other issues with the script that we have created.

- As pipeline steps have to be re-run in sequence; even if the initial pipeline steps ran sucessfully they will still be re-run every time
  - Sample 2 is processed only once Sample 1 is completed etc
- There is no error-checking. 
  - We need to check that Sample 1 actually completed sucessfully
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

## Distributing software using "Containerisation"

![](programmerhumor-io-programming-memes-2fda9abcc7dc92e.jpe)

Installing software on a HPC is **hard**, Containers offer an approach to capture and isolate entire computing environments. At their core, a container is built from an image, which is a lightweight, stand-alone, executable software package. This image is comprehensive, bundling everything necessary to run the piece of software consistently, regardless of the underlying infrastructure.

## Running a nf-core pipeline

In our opinion, nextflow is solution to running pipelines particular appealing as many popular Bioinformatics pipelines have already been written using nextflow and have been distributed as part of the nf.core project

- [nf.core homepage](https://nf-co.re/)

We will start by getting a small "demo" pipeline running, before progressing to the RNA-seq one

- [nf-core demo pipeline](https://nf-co.re/demo/1.1.0/)

![](https://raw.githubusercontent.com/nf-core/demo/1.1.0//docs/images/nf-core-demo-subway.png)


- [nf.core RNA-seq pipeline](https://nf-co.re/rnaseq)

![](https://raw.githubusercontent.com/nf-core/rnaseq/3.24.0//docs/images/nf-core-rnaseq_metro_map_grey_animated.svg)








A minimal number of options required to run an nf.core pipeline such as RNA-seq are:-

```{bash}
nextflow run nf-core/rnaseq \
                  --input samplesheet.csv \
                  --outdir <OUTDIR> \
                  --genome GRCh37 \
                  -profile docker\
```

where:-

- `nf-core/rnaseq` is a reference to the pipeline that we want to run
- `--input` is the location of a samplesheet defining the raw data to be processed
- `--outdir` is a directory that will contain the final results of the pipeline
- `genome` is the shorthand name for the genome to be used as a reference
- `profile` defines how software included in the pipeline is to be downloaded/installed (**See later**)

We have customised some of the options of the pipeline so run a reduced number of steps are run for the workshop, and using a custom genome containing a single chromosome.

```{bash}
cat run_nextflow.sh
```

The particular steps that we have modified are as follows:-

```
##use a particular pipeline version
-r 3.8.1 \
## Skip aligning to the whole genome
--skip_alignment \
## Skip trimming read sequences
--skip_trimming \
## use the salmon quantification tool
--pseudo_aligner salmon \
## Use our own set of references rather than downloading
--fasta ref_data/Homo_sapiens.GRCh38.dna_rm.chromosome.22.fa \
--transcript_fasta ref_data/Homo_sapiens.GRCh38.cdna.chr22.fa \
--gtf ref_data/Homo_sapiens.GRCh38.108.chr22.gtf \
--salmon_index index/GRCh38_salmon \
## restrict the amount of memory requested \
--max_memory 2GB
```

The files that we want to analyse are defined in a sample sheet. The format of the sheet is checked by the pipeline as one of the first steps. The column names have to match *exactly* what the pipeline expects.

```{bash}
cat nf_samplesheet.csv
```


We can run the pipeline as follows

```{bash}
bash run_nextflow.sh
```


The output from the workflow will be written to a directory `nf_results`, which doesn't need to exist before the pipeline has been run. You should also see that a `work` directory is created.


## Exercise
<div class="exercise">
**Exercise**
Run the script `run_nextflow.sh` (around ~5 to 10 minutes) and afterwards look at the output in the `nf_results` folder and familiarise yourself with the outputs. What extra steps have been performed in addition to the script that we created earlier?
</div>

## What software does nextflow use in it's pipeline?

You should notice that the nf.core pipeline has produced quantification files for each sample, and also combined the `salmon` outputs into a single file. It also run some QC plots from the DESeq2 R package. However, R is not part of our software environment. We can see this by running the following commands which would usually report the path that R is located at, or run the command-line R.


```
which R
R
```

nextflow has it's own way of installing and running software which does not depend on the operating system that is being used to run the pipeline. This is specified by this part of the run script.

- [nf.core profile options](https://nf-co.re/rnaseq/3.9/usage#profile)

```
-profile singularity 
```

In fact, we could have run the pipeline if we didn't have `salmon` and `fastqc` installed. The implication of this being that you can re-run the pipeline on your own machine or HPC environment with minimal software installation. The only dependancies are `nextflow` itself (which in turn requires `java`) and some *containerisation* or package management software such as `singularity`, `docker` or `conda`. This is a significantly easier requirement to fulfill than having to install each piece of software individually.

<div class="information">
If you are using a HPC environment you will probably want to keep the singularity option in the profile. 
</div>

## Re-running the pipeline

<div class="exercise">
**Exercise**
There are two fastq files in our `fastq` folder that have not yet been analysed; `ERR732908` and `ERR732909`. Use the `nano` editor to modify the samplesheet `nf_samplesheet.csv` to include `ERR732908`, and re-run the pipeline. What do you notice about the time taken to run the pipeline?
</div>


The pipeline should be quicker this time around. This is because we had all the software downloaded and installed from the previous run. However, it still re-analysed the first seven samples from the samplesheet - which is not ideal. If we want a report on what analyses have been performed and how long they took we can look at a report from the command-line

```
## You will have to use auto-complete and choose the most-recent report
cat nf_results/pipeline/execution_trace
```
There is also a HTML version of the report that we can view through the file system.

## Resuming a pipeline

Ideally, we would like the pipeline to detect what jobs have been run successfully and not repeat those jobs. The option `-resume` in nextflow will allow you to do this. (note the single `-` when adding this option). Modify the nextflow script with `nano` to contain the following lines at the top

```
nextflow run nf-core/rnaseq -profile singularity \
-resume \
-r 3.8.1 \
....

```

We can now edit the samplesheet again to process the sample `ERR732909` 

```
sample,fastq_1,fastq_2,strandedness
ERR732901,fastq/ERR732901_sub.fastq.gz,,unstranded
ERR732902,fastq/ERR732902_sub.fastq.gz,,unstranded
ERR732903,fastq/ERR732903_sub.fastq.gz,,unstranded
ERR732904,fastq/ERR732904_sub.fastq.gz,,unstranded
ERR732905,fastq/ERR732905_sub.fastq.gz,,unstranded
ERR732906,fastq/ERR732906_sub.fastq.gz,,unstranded
ERR732907,fastq/ERR732907_sub.fastq.gz,,unstranded
ERR732908,fastq/ERR732908_sub.fastq.gz,,unstranded
ERR732909,fastq/ERR732909_sub.fastq.gz,,unstranded
```


and re-run the pipeline. 

```
bash run_nextflow.sh
```

The pipeline now runs significantly quicker because it detects that all the analyses have been completed and *cached*. If we check the `execution_trace` text file for this latest run it should say that most tasks were `CACHED` - meaning that the results from the previous analysis was used.