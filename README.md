# Snakemake workflow: `10X GEX/ATAC + LARRY`

[![Snakemake](https://img.shields.io/badge/snakemake-≥8.4.7-brightgreen.svg)](https://snakemake.github.io)


A Snakemake workflow to process single-cell libraries generated with 10XGenomics platform (RNA, ATAC and RNA+ATAC) together with [LARRY barcoding](https://www.nature.com/articles/s41586-020-2503-6). The pipeline uses cellranger to generate the single cell matrices to import into R/Python.

**IMPORTANT**: To run this pipeline you need to have [snakemake](https://snakemake.github.io) installed. You can follow their [tutorial](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) for installing the software, it is very straightfoward. 

To run the pipeline some singularity images for cellranger are also required. You can read more about this in the [cellranger parameters](#configuration-of-pipeline-parameters-cellranger) section.

## Configuration files

To setup the pipeline for execution it is very simple, however there are some files in the folder `config` that need to be modified/adapted. These are the main configuration files and their contents:

* `config/samples/units.tsv`: Sample name information and paths to fastq files (see [units and sample_config](#samples-to-process-and-raw-data) section).
* `config/samples/sample_config.tsv`: Sample name information, UMI cutoff and forced number of cells.
* `config/config.yaml`: Main cellranger and configuration file such as cellranger settings, paths to singularity images, etc (see [cellranger params](#configuration-of-pipeline-parameters-cellranger)).
* `config/larry_config.yaml`: Parameters regarding larry barcode processing. **Important to check before running the pipeline**. The default behavior is to run the pipeline with LARRY processing activated. If you don't have larry barcodes but want to run the pipeline, switch it to off (see [Larry params](#larry-configuration)).
* `config/cellhash_config.yaml`: Reference file for cellhashing processing. No need to edit if cellhashing was not used to prepare the libraries (see [Cellhashing params](#cellhashing-configuration)).


## Samples to process and raw data

Paths to raw data (fastq files) are located in the file `config/samples/units.tsv`. The file has the following structure:

| sample_id | lane | lib_type | R1 | R2 | R3 |
|-----------|------|----------|----|----|----|
| name_of_sample | name_of_lane_or_resequencing | library type | path/to/forward.fastq.gz | path/to/reverse.fastq.gz | path/to/ATAC-R3.fastq.gz

* `sample_id`: The first field correspond to the sample name. This field has to be identical for all the fastqs corresponding to the same sample, idependently of the library type of the fastq. If a sample is split in 2 different library types (such as ATAC + RNA or RNA and LARRY), both of them must have the same sample_id.

* `lane`: The idea of this field is to group fastq files corresponding to the same sample (or to samples that have to be merged). For example, if 1 sample arrived in 2 different lanes from a PE experiment, in total there will be 4 fastqs (2 forward and 2 reverse). In this case, one should enter the same sample 2 times, putting in the `lane` field the corresponding lanes (lane1 and lane2, for example). Actually one can write any word in this field, the idea is to group fastqs from the same sample. All the entries with the same name in the `sample` field with different `lane` will be merged in the same fastq. Here an example of how it would be with 1 sample that arrived in 2 lanes:

    | sample_id | lane | lib_type | R1 | R2 | R3 |
    |-----------|------|----------|----|----|----|
    | foo | lane1 | GEX | path/to/forward_lane1.fastq.gz | path/to/reverse_lane1.fastq.gz | |
    | foo | lane2 | GEX | path/to/forward_lane2.fastq.gz | path/to/reverse_lane2.fastq.gz | |

    Usually I use lane1 and lane2 for consistency and making things more clear, but the following would also work:

    | sample_id | lane | lib_type | R1 | R2 | R3 |
    |-----------|------|----------|----|----|----|
    | foo | whatever | GEX | path/to/forward_lane1.fastq.gz | path/to/reverse_lane1.fastq.gz | |
    | foo | helloworld | GEX | path/to/forward_lane2.fastq.gz | path/to/reverse_lane2.fastq.gz | |

    The important thing is that if a sample is split in different pairs of fastq files (different pairs of R1 & R2 files) in the units file they must be inserted in 2 different rows, with the **same sample_id** and **different lane**.

* `lib_type`: corresponds to the type of library. Basically it can be one of 3: **GEX** (Gene expression), **ATAC** (Chromatin accessibility), **FB** (Feature barcoding, which has to be set for the LARRY fastqs) and **CH** (Fast files containing cellhashing data).

* `R1`, `R2` and `R3`: correspond to the paths to the fastq files. For RNA (GEX) `R1` is the FORWARD read and `R2` the REVERSE. Usually the cellular barcode is present in the R1 and the transcript in the R2, same for LARRY. In the case of the ATAC, `R2` corresponds to the dual illumina indexing and `R3` corresopnds to the reverse read (where the tn5 fragment is present).

Example of a units.tsv file with GEX, LARRY and Cellhashing:

| sample_id | lane | lib_type | R1 | R2 | R3 |
|-----------|------|----------|----|----|----|
| sample1 | lane1 | GEX | path/to/forward_GEX_lane1.fastq.gz | path/to/reverse_GEX_lane1.fastq.gz | |
| sample1 | lane2 | GEX | path/to/forward_lGEX_ane2.fastq.gz | path/to/reverse_GEX_lane2.fastq.gz | |
| sample1 | lane1 | FB | path/to/forward_LARRY_lane1.fastq.gz | path/to/reverse_LARRY_lane1.fastq.gz | |
| sample1 | lane1 | CH | path/to/forward_cellhashing_lane2.fastq.gz | path/to/reverse_cellhashing_lane2.fastq.gz | |

## Configuration of pipeline parameters (cellranger)

Cellranger parameters can be configured in `config/config.yaml`. Modify them as you wish. Check always that you are using the correct genome files corresponding to the version that you want to use. 

Inside the file, and also in the file `workflow/schema/config.schema.yaml` you can find what is controled by each tunable parameter.

Also you have to define the path to the cellranger singularity images and genomes that will be used by the pipeline. You can build your own images to download mine with the following commands:

```bash
singularity pull docker://dfernand/cellranger:7.1.0 # for GEX
singularity pull docker://dfernand/cellranger_arc:2.0.2 # for GEX+ATAC
singularity pull docker://dfernand/cellranger_atac:2.1.0 # for ATAC
```

Then just add the path of those files to `config/config.yaml` in their corresponding fields. For the genome annotation files, you can download them directly form [10XGenomics website](https://www.10xgenomics.com/).

## LARRY configuration

`config/larry_config.yaml` contains the parameters of LARRY processing:

* `feature_bc`: Does data contain barcodes? set `True` or `False`
* `read_feature_bc`: In which fastq (fw or rv) are located larry barcodes. Usually is the `R2`.
* `read_cellular_bc`: In which fastq (fw or rv) are located cellular barcodes. Usually is the `R2`. This is the opposite fastq than `read_feature_bc`.
* `hamming_distance`: The hamming distance that will be used to collapse larry barcodes. We have seen that for a barcode of 20 nucleotides in length, `3` or `4` are good values. 
* `reads_cutoff`: Number of minimum reads that a molecule needs to have in oprder to consider a UMI. Cellranger considers any molecule sequenced at least 1 time as a valid UMI. Since usually we sequence LARRY libraries at >90% saturation, most molecules should be sequenced way more than 1 time (we are sequencing many PCR duplicates). Setting this threshold `between 5 and 10` has helped us to reduce the number of false positive larry assignments in our datasets.
* `umi_cutoff`: Number of UMIs required to consider a LARRY barcode deteced in a cell when performing the barcode calling. This depends a lot on the expression of the barcode mRNA. For LARRY-v1 libraries this value could be increase easily at 5-10, however with LARRY-v2 the expression is lower. This can be easily re-executed by the user in R after running the pipeline. Default: `3`
* `bc_patterns`: The patterns of the larry barcodes integrated in the sequenced cells. **IMPORTANT**: Right now the pipeline **DOES NOT** allow to use underscores (`_`) in the larry barcode name (Sapphire, GFP, etc...). It has the following structure:

    ```yaml
    bc_patterns:
        "TGATTG....TG....CA....GT....AG...." : "Sapphire"
        "TCCAGT....TG....CA....GT....AG...." : "GFP"
    ```

## Cellhashing configuration

**How cellhashing data is processed:**
Cellhashing processing is performed using the function `hashedDrops` from the [DropletUtils package](https://bioconductor.org/packages/release/bioc/html/DropletUtils.html) with default parameters. `HTODemux` from [Seurat](https://satijalab.org/seurat/) is also performed and stored in the corresponding SeuratObject, but is not used for demultiplexing. If you desire to modify this behavior/settings, you can edit the script `workflow/scripts/R/create_seurat.R`. Also, since the cellhashing matrices are stored in the output SeuratObject, cellhashing can be re-processed again by the user. 

**Cellhashing configuration files**: `config/cellhashing_config.yaml` contains the parameters to process cellhashing data. You don't need to modify this file if cellhashing has not been used for library preparation. First you have to fill the sequences corresponding to the cellhashing antibodies, which has the following structure:

```yaml
barcodes:
    TotalSeqMouse1: ["R2", "5PNNNNNNNNNN(BC)", "ACCCACCAGTAAGAC"]
    TotalSeqMouse2: ["R2", "5PNNNNNNNNNN(BC)", "GGTCGAGAGCATTCA"]
    TotalSeqMouse3: ["R2", "5PNNNNNNNNNN(BC)", "CTTGCCGCATGTCAT"]
    TotalSeqMouse4: ["R2", "5PNNNNNNNNNN(BC)", "AAAGCATTCTTCACG"]
```

Basically you have to write the name of the totalseq Ab, in which read it is present, the pattern to locate the barcod in the read, and the sequence. This uses the syntax described by 10XGenomics in their [website](https://www.10xgenomics.com/support/software/cell-ranger/latest/analysis/running-pipelines/cr-feature-bc-analysis). By default you can find the standard totalseqmouse Abs and their sequences.

Then, you have to fill to which sample corresopnds every Ab and the subsample names:

```yaml
assignments:
  sample1:
    TotalSeqMouse1: "sample1-A"
    TotalSeqMouse2: "sample1-B"
    TotalSeqMouse3: "sample1-C"
  sample2:
    TotalSeqMouse1: "sample2-A"
    TotalSeqMouse3: "sample2-B"
    TotalSeqMouse4: "sample2-C"
```

## Resources configuration

`config/resources.yaml` contains the per rule resource parameters (ncpus, ram, walltime...). It can be modified as desired. Just be sure to respect the amount of CPUs and RAM that each rule required (the parameters set by default have been set based on trial and error and should be over what is actually required). The RAM and CPUs are also used by snakemake to calculate which and how many jobs it can run in parallel. If the rule actually uses more resources than those set, it can drive to running parallel jobs that exceed the computers RAM, which can force the abortion of jobs. 

## Snakemake profiles

In Snakemake 4.1 [snakemake profiles](https://github.com/Snakemake-Profiles) were introduced. They are supposed to substitute the classic cluster.json file and make the execution of snakemake more simple. The parameters that will be passed to snakemake (i.e: --cluster, --use-singularity...) now are inside a yaml file (`config.yaml`) inside the profile folder (in the case of this repository is `config/snakemake_profile`). The `config.yaml` inside `snakemake_profile` contains the parameters passed to snakemake. An important parameters that you have to adapt are:

```yaml
cores            : 120 # Define total amount of cores that the pipeline can use
resources        : mem_mb=128000 # Define total amount of ram that pipeline can use
default-resources: mem_mb=1000 # Set default ram for rules (cores is by default 1)
latency-wait     : 60
singularity-args : "--bind /stemcell"
```

Adapt `cores`, `resources` and `default-resources` to your computer hardware. Then adapt the path to bind in singularity from `singularity-args` to the folder in which you are running the pipeline form.

## Execution of the pipeline

Once you have all the configuration files as desired, it's time to execute the pipeline. For that you have to execute the `execute_pipeline.sh` script, followed by the name of the rule that you want to execute. If no rule is given it will automatically execute the rule `all` (which would execute the standard pipeline). Examples:

```bash
./execute_pipeline.sh all
```

is equivalent to 

```bash
./execute_pipeline.sh
```

If you want to add extra snakemake parameters without modifying `config/snakemake_profile/config.yaml`:

```bash
./execute_pipeline.sh --rerun-triggers mtime
```
