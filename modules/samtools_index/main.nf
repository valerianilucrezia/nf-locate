#!/usr/bin/env nextflow

process SAMTOOLS_INDEX {
    tag "${meta.sampleID}-chr${meta.chr}-${meta.hp}"
    container 'https://depot.galaxyproject.org/singularity/samtools%3A1.9--h91753b0_8'

    input:
      tuple val(meta), path(bam)

    output:
      tuple val(meta), path(bam), path('*.bam.bai'), emit: 'bam' 
    script:

    """
    samtools index -@ 12 ${bam}
    """
}
