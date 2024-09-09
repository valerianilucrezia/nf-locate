#!/usr/bin/env nextflow

process GET_POSITIONS {
    tag "${meta.sampleID}-chr${meta.chr}"
    container 'docker://lvaleriani/long_reads:latest'

    input:
    tuple val(meta), path(bed)

    output:
    tuple val(meta), path('*_meth'), emit: 'bed'

    script:

    """
    #change to cat
    head -n 100 "${bed}" | grep -w "chr${meta.chr}" | grep -v "random" | awk '{print \$1, \$3}' > "chr${meta.chr}_${meta.sampleID}_meth"
    """
}
