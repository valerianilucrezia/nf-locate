#!/usr/bin/env nextflow

process MODKIT {
    tag "${meta.sampleID}-chr${meta.chr}"
    container 'https://depot.galaxyproject.org/singularity/ont-modkit%3A0.3.1--h5c23e0d_1'

    input:
      tuple val(meta), path(bam), path(bai), path(ref_genome), path(ref_fai) 

    output:
      tuple val(meta), path('*_summary.bed'), emit: 'bed_summary' 
      tuple val(meta), path('*.log'), emit: 'log'

    script:

    """
    modkit pileup ${bam} "${meta.sampleID}_chr${meta.chr}_summary.bed" --ignore h --ref ${ref_genome} --cpg --combine-strands --log-filepath "${meta.sampleID}_${meta.chr}_pileup_summary.log" -t 12
    """
}
