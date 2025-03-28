#!/usr/bin/env nextflow

process DMR {
    tag "${meta.sampleID}-chr${meta.chr}"
    container 'https://depot.galaxyproject.org/singularity/ont-modkit%3A0.3.1--h5c23e0d_1'

    input:
      tuple val(meta), path(h1), path(h1_idx), path(h2), path(h2_idx), path(ref_genome), path(ref_fai) 

    output:
      tuple val(meta), path('*.dmr'), emit: 'dmr' 
      tuple val(meta), path('*.segment'), emit: 'seg' 
      tuple val(meta), path('*.log'), emit: 'log'

    script:

    """

    modkit dmr pair \
            -a ${h1} \
            -b ${h2} \
            -o ${meta.sampleID}_chr${meta.chr}_dmr \
            --segment ${meta.sampleID}_chr${meta.chr}_segment \
            --ref ${ref_genome} \
            --base C \
            --threads 24 \
            --log-filepath ${meta.sampleID}_chr${meta.chr}_dmr.log
      
    """
}
