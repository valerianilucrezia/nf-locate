#!/usr/bin/env nextflow

process GET_POSITIONS {
    tag "${name}-chr${ch}"
    container 'docker://lvaleriani/long_reads:latest'

    input:
    tuple val(ch), val(name), path(bed)

    output:
    tuple val(name), val(ch), path('*_meth'), emit: 'chr_bed'

    script:
    """
    cat "${bed}" | grep -w "chr${ch}" | grep -v "random" | awk '{print \$1, \$3}' > "chr${ch}_${name}_meth"
    """
}
