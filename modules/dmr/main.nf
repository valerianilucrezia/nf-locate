#!/usr/bin/env nextflow

process DMR {
    tag "${meta.sampleID}-${meta.chr}"
    container 'https://depot.galaxyproject.org/singularity/ont-modkit%3A0.3.1--h5c23e0d_1'

    input:
      tuple val(meta), path(h1), path(h1_index), path(h2), path(h2_index), path(ref_genome), path(ref_fai) 

    output:
      tuple val(meta), path('*_dmr'), emit: 'dmr' 
      tuple val(meta), path('*_segment'), emit: 'seg' 
      tuple val(meta), path('*.log'), emit: 'log'

    script:

    """

    modkit dmr pair \
            -a ${h1} \
	    --index-a ${h1_index} \
            -b ${h2} \
	    --index-b ${h2_index} \
            -o ${meta.sampleID}_${meta.chr}_dmr \
            --segment ${meta.sampleID}_${meta.chr}_segment \
            --ref ${ref_genome} \
            --base C \
            --threads 24 \
            --log-filepath ${meta.sampleID}_${meta.chr}_dmr.log
      
    """
}
