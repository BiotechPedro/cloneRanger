rule create_seurat:
    input:
        cellranger_mtx = get_cellranger_mtx
    output:
        no_doublets = "results/02_createSeurat/seurat_{sample}_noDoublets.rds",
        raw         = "results/02_createSeurat/seurat_{sample}_raw.rds"
    params:
        subsample_names = lambda w: CELL_HASHING["assignments"][w.sample] if is_cell_hashing(w.sample) else "",
        cell_assign     = lambda w: "results/01_counts/{sample}/outs/multi/multiplexing_analysis/assignment_confidence_table.csv".format(sample = w.sample) if is_cell_hashing(w.sample) else "",
        is_cell_hashing = lambda w: "TRUE" if is_cell_hashing(w.sample) else "FALSE",
        is_larry        = "TRUE" if is_feature_bc() else "FALSE",
        min_cells_gene  = config["preprocessing"]["min_cells_gene"],
        min_cells_larry = config["preprocessing"]["min_cells_larry"],
        mito_pattern    = config["preprocessing"]["mito_pattern"],
        ribo_pattern    = config["preprocessing"]["ribo_pattern"],
        sample_path     = lambda w: "results/01_counts/{sample}/outs/per_sample_outs/{sample}/count/sample_filtered_feature_bc_matrix".format(sample = w.sample)
    conda:
         "../envs/Seurat.yaml"
    threads:
        RESOURCES["create_seurat"]["cpu"]
    resources:
        mem_mb = RESOURCES["create_seurat"]["MaxMem"]
    log:
        "results/00_logs/create_seurat/{sample}.log"
    benchmark:
        "results/benchmarks/create_seurat/{sample}_benchmark.txt"
    script:
        "../scripts/R/create_seurat.R"


rule barcode_summary:
    input:
        "results/02_createSeurat/seurat_{sample}_noDoublets.rds"
    output:
        html = "results/05_barcode-exploration/{sample}_barcode_filtering.html"
    params:
        molecule_info = lambda w: "results/01_counts/{sample}/outs/multi/count/raw_molecule_info.h5".format(sample = w.sample),
    conda:
         "../envs/Seurat.yaml"
    threads:
        RESOURCES["barcode_filtering"]["cpu"]
    resources:
        mem_mb = RESOURCES["barcode_filtering"]["MaxMem"]
    log:
        "results/00_logs/barcode_filtering/{sample}.log"
    benchmark:
        "results/benchmarks/barcode_filtering/{sample}_benchmark.txt"
    script:
        "../scripts/R/barcode_summary.Rmd"


rule barcode_filtering:
    input:
        "results/02_createSeurat/seurat_{sample}_noDoublets.rds"
    output:
        "results/02_createSeurat/seurat_{sample}_noDoublets-larry-filt.rds"
    params:
        reads_cutoff  = config["feature_bc_config"]["reads_cutoff"],
        umi_cutoff    = config["feature_bc_config"]["umi_cutoff"],
        molecule_info = lambda w: "results/01_counts/{sample}/outs/multi/count/raw_molecule_info.h5".format(sample = w.sample),
    conda:
         "../envs/Seurat.yaml"
    threads:
        RESOURCES["barcode_filtering"]["cpu"]
    resources:
        mem_mb = RESOURCES["barcode_filtering"]["MaxMem"]
    log:
        "results/00_logs/barcode_filtering/{sample}.log"
    benchmark:
        "results/benchmarks/barcode_filtering/{sample}_benchmark.txt"
    script:
        "../scripts/R/barcode_filtering.R"


rule merge_seurat:
    input:
        get_seurat_rds
    output:
        seurat = "results/03_mergeSeurat/seurat_merged.rds",
    conda:
         "../envs/Seurat.yaml"
    threads:
        RESOURCES["merge_seurat"]["cpu"]
    resources:
        mem_mb = RESOURCES["merge_seurat"]["MaxMem"]
    log:
        "results/00_logs/merge_seurat/log"
    benchmark:
        "results/benchmarks/merge_seurat/benchmark.txt"
    script:
        "../scripts/R/merge_seurat.R"


rule RNA_exploration:
    input:
        "results/03_mergeSeurat/seurat_merged.rds"
    output:
        html = "results/04_RNA-exploration/RNA_exploration.html"
    params:
        marker_genes  = config["preprocessing"]["marker_genes"],
        species       = config["species"],
        cluster_degs  = "results/04_RNA-exploration/cluster_degs.tsv",
        sample_degs   = "results/04_RNA-exploration/sample_degs.tsv"
    conda:
         "../envs/Seurat.yaml"
    threads:
        RESOURCES["RNA_exploration"]["cpu"]
    resources:
        mem_mb = RESOURCES["RNA_exploration"]["MaxMem"]
    log:
        "results/00_logs/RNA_exploration/log"
    benchmark:
        "results/benchmarks/RNA_exploration/benchmark.txt"
    script:
        "../scripts/R/RNA_exploration.Rmd"


rule barcode_exploration:
    input:
        "results/03_mergeSeurat/seurat_merged.rds"
    output:
        html = "results/05_barcode-exploration/barcode_exploration.html"
    params:
        barcodes = LARRY_COLORS
    conda:
         "../envs/Seurat.yaml"
    threads:
        RESOURCES["barcode_exploration"]["cpu"]
    resources:
        mem_mb = RESOURCES["barcode_exploration"]["MaxMem"]
    log:
        "results/00_logs/barcode_exploration/log"
    benchmark:
        "results/benchmarks/barcode_exploration/benchmark.txt"
    script:
        "../scripts/R/barcode_exploration.Rmd"