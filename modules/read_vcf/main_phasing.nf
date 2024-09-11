#!/usr/bin/env nextflow

process READ_PHASING {
    tag "${meta.sampleID}-chr${meta.chr}"
    container 'docker://lvaleriani/long_reads:latest'


    input:
        tuple val(meta), path(vcf_N), path(vcf_T)

    output:
        tuple val(meta), path('*.RDS'), emit: 'chr_rds'

    script:
    """
        #!/usr/bin/env bash
        read_phasing.R "${meta.chr}" $vcf_N $vcf_T "${meta.sampleID}"

    """
}
