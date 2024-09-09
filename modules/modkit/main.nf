#!/usr/bin/env nextflow

process MODKIT {
    tag "${name}"
    container 'https://depot.galaxyproject.org/singularity/ont-modkit%3A0.3.1--h5c23e0d_1'

    input:
      tuple val(name), path(bam), path(bai), path(ref_genome), path(ref_fai) 

    output:
      tuple val(name), path('*_summary.bed'), emit: 'bed_summary' 
      tuple val(name), path('*_bystrand.bed'), emit: 'bed_bystrand' 
      tuple val(name), path('*.log'), emit: 'log'

    script:
    """
    modkit pileup "${bam}" "${name}_summary.bed" --ignore h --ref "${ref_genome}" --cpg --combine-strands --log-filepath "${name}_pileup_summary.log" -t 12
    """
}
