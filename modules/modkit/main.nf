#!/usr/bin/env nextflow

process MODKIT {
    tag "${name}"
    publishDir "${workflow.launchDir}/results/modkit/", mode: 'copy'
    container 'https://depot.galaxyproject.org/singularity/ont-modkit%3A0.3.1--h5c23e0d_1'
    cpus 12
    memory '100 GB'
    time '12h'

    
    input:
      tuple val(name), path(bam), path(bai), path(ref_genome), path(ref_fai) 

    output:
      tuple val(name), path('*.bed'), emit: 'bed' 
      tuple val(name), path('*.log'), emit: 'log'

    script:
    """
    modkit pileup "${bam}" "${name}.bed" --ignore h --ref "${ref_genome}" --cpg --combine-strands --log-filepath "${name}_pileup.log" -t 24
    modkit pileup "${bam}" "${name}_bystrand.bed" --ignore h --ref "${ref_genome}" --log-filepath "${name}_pileup_bystrand.log" -t 12
    """
}
