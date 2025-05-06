#!/usr/bin/env nextflow

process BCFTOOLS_INDEX {
    tag "${meta.sampleID}-${meta.chr}"
    label "process_low"
    label "error_retry"
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'

    input:
      tuple val(meta), path(vcf)

    output:
      tuple val(meta), path('*.vcf.gz'), path('*.vcf.gz.csi'), emit: 'vcf' 
    script:

    """
    bcftools sort ${vcf} -o ${meta.sampleID}_${meta.chr}.vcf.gz -O z
    bcftools index ${meta.sampleID}_${meta.chr}.vcf.gz
    """
}
