if config["10x_pipeline"] == "GEX":

    # No conda env used as cellranger cannot be installed in one
    rule cellranger_count:
        input:
            fq = lambda w: expand(
                                "data/clean/{sample}_{lib_type}_S1_L001_{read}_001.fastq.gz", 
                                sample   = w.sample,
                                lib_type = SAMPLE_LIB_DICT[w.sample],
                                read     = ["R1", "R2"]
                            ),
            multi_ref = "data/feature_bc_libraries/{sample}_library_multi.csv"
        output:
            directory("results/01_counts/{sample}/outs/per_sample_outs/"),
        params:
            mem_gb = config["cellranger_count"]["mem"]
        log:
            "results/00_logs/counts/{sample}.log",
        benchmark:
            "results/benchmarks/counts/{sample}.txt"
        threads:
            RESOURCES["cellranger_count"]["cpu"]
        resources:
            mem_mb = RESOURCES["cellranger_count"]["MaxMem"]
        container: 
            config["cellranger_rna_sif"]
        shell:
            """
            cellranger multi \
            --id={wildcards.sample} \
            --csv={input.multi_ref} \
            --localcores {threads} \
            --localmem {params.mem_gb} \
            &> {log} && \
            # a folder in results/counts/{wildcards.sample} is automatically created due to the output declared, which 
            # is a problem to move the cellranger output files. The workaround of deleting that folder fixes that.
            rm -r results/01_counts/{wildcards.sample} && \
            mv {wildcards.sample} results/01_counts/{wildcards.sample}
        """


elif config["10x_pipeline"] == "ATAC":
   rule cellranger_count:
        input:
            lambda w: expand("data/clean/{{sample}}_ATAC_S1_L001_{read}_001.fastq.gz", read=["R1", "R2"])
        output:
            mtx  = "results/01_counts/{sample}/outs/filtered_feature_bc_matrix.h5",
            html = report(
                "results/01_counts/{sample}/outs/web_summary.html",
                caption     = "../reports/counts.rst",
                category    = "Cellranger Counts",
                subcategory = "{sample}",
            ),
        params:
            genome  = config["genome_refrerence_arc"],
            mem_gb  = config["cellranger_count"]["mem"],
            extra_p = config["cellranger_count"]["extra_parameters_atac"]
        log:
            "results/00_logs/counts/{sample}.log",
        benchmark:
            "results/benchmarks/counts/{sample}.txt"
        threads:
            RESOURCES["cellranger_count"]["cpu"]
        resources:
            mem_mb = RESOURCES["cellranger_count"]["MaxMem"]
        container: 
            config["cellranger_atac_sif"]
        shell:
            """
            cellranger-atac count \
            {params.extra_p} \
            --id {wildcards.sample} \
            --reference {params.genome} \
            --fastqs data/clean \
            --localcores {threads} \
            --localmem {params.mem_gb} \
            &> {log} && \
            # a folder in results/counts/{wildcards.sample} is automatically created due to the output declared, which 
            # is a problem to move the cellranger output files. The workaround of deleting that folder fixes that.
            rm -r results/01_counts/{wildcards.sample} && \
            mv {wildcards.sample} results/01_counts/{wildcards.sample}
        """

elif config["10x_pipeline"] == "ARC":
    rule cellranger_count:
        input:
            fq_gex  = expand(
                            "data/clean/{sample}_GEX_S1_L001_{read}_001.fastq.gz", 
                            sample = SAMPLES,
                            read   = ["R1", "R2"]
                        ),
            fq_atac = expand(
                            "data/clean/{sample}_ATAC_S1_L001_{read}_001.fastq.gz", 
                            sample = SAMPLES,
                            read   = ["R1", "R2", "R3"]
                        ),
            libraries   = "data/feature_bc_libraries/{sample}_library.csv"
        output:
            mtx  = "results/01_counts/{sample}/outs/filtered_feature_bc_matrix.h5",
            html = report(
                "results/01_counts/{sample}/outs/web_summary.html",
                caption     = "../reports/counts.rst",
                category    = "Cellranger Counts",
                subcategory = "{sample}",
            ),
        params:
            introns = convert_introns(),
            genome  = config["genome_refrerence_arc"],
            mem_gb  = config["cellranger_count"]["mem"],
            extra_p = config["cellranger_count"]["extra_parameters_atac"]
        log:
            "results/00_logs/counts/{sample}.log",
        benchmark:
            "results/benchmarks/counts/{sample}.txt"
        threads:
            RESOURCES["cellranger_count"]["cpu"]
        resources:
            mem_mb = RESOURCES["cellranger_count"]["MaxMem"]
        container: 
            config["cellranger_multiome_sif"]
        shell:
            """
            cellranger-arc count \
            {params.introns} \
            {params.extra_p} \
            --id {wildcards.sample} \
            --reference {params.genome} \
            --libraries {input.libraries} \
            --localcores {threads} \
            --localmem {params.mem_gb} \
            &> {log} && \
            # a folder in results/counts/{wildcards.sample} is automatically created due to the output declared, which 
            # is a problem to move the cellranger output files. The workaround of deleting that folder fixes that.
            rm -r results/01_counts/{wildcards.sample} && \
            mv {wildcards.sample} results/01_counts/{wildcards.sample}
            """