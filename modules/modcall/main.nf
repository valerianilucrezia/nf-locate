#!/usr/bin/env nextflow

process MODCALL {
    tag "${meta.sampleID}-${meta.type}-${meta.chr}"
    container 'https://depot.galaxyproject.org/singularity/longphase%3A1.7.3--hf5e1c6e_0'

    input:
      tuple val(meta), path(bam), path(bai), path(ref_genome), path(ref_fai) 

    output:
      tuple val(meta), path('*.vcf'), emit: 'vcf' 

    script:

    """

    longphase modcall \
    -b ${bam} \
    -r ${ref_genome} \
    -t 48 \
    -o "${meta.sampleID}_${meta.chr}_modcall"
      
    """
}
