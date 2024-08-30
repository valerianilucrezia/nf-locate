#!/usr/bin/env nextflow

process GET_POSITIONS {
    tag "${name}-chr${ch}"
    publishDir "${workflow.launchDir}/results/get_positions/", mode: 'copy'
    container 'docker://lvaleriani/long_reads:latest'
    memory '20 GB'

    input:
    tuple val(ch), val(name), path(bed)

    output:
    path '*.bed', emit: 'chr_bed'

    script:
    """
    cat "${bed}" | grep -w "chr${ch}" | grep -v "random" | awk '{print \$1, \$2, \$3}' > "chr${ch}_${name}_meth.bed"
    """
}
