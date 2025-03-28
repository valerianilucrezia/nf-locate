#!/usr/bin/env nextflow

process SNIFFLE {
    tag "${meta.sampleID}-${meta.type}"
    container 'https://depot.galaxyproject.org/singularity/sniffles%3A2.6.1--pyhdfd78af_0'

    input:
      tuple val(meta), path(bam), path(bai), path(ref_genome), path(ref_fai) 

    output:
      tuple val(meta), path('*.vcf'), emit: 'vcf' 

    script:

    """
    sniffles \
      -i ${bam}  \
      -v ${meta.sampleID}_SV.vcf \
      --reference ${ref_genome} \
      -t 8 \
      --output-rnames
    """
}
