#!/usr/bin/env nextflow

process READ_SOMATIC {
    tag "${meta.sampleID}"
    container 'docker://lvaleriani/long_reads:latest'

    input:
        tuple val(meta), path(vcf), path(tbi)
        
    output:
        tuple val(meta), path('*.RDS'), emit: 'rds'

    script:
    """
    read_vcf_somatic.R "${vcf}"
    """
}
