#!/usr/bin/env nextflow

process BCFTOOLS_BGZIP {
    tag "${meta.sampleID}-chr${meta.chr}"
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'

    input:
      tuple val(meta), path(vcf)

    output:
      tuple val(meta), path('*.bed.gz'), path('*.bed.gz.tbi'), emit: 'bed' 
    
    script:

    """
    bgzip -@ 24 ${vcf}
    tabix -f -p bed "${meta.hp}${meta.sampleID}_chr${meta.chr}_methylation.bed.gz"

    """
}
