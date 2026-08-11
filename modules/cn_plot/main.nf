#!/usr/bin/env nextflow

process CN_PLOT {
    tag "${meta.sampleID}"
    label "process_low"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(table), path(cn_table), path(purity_ploidy), path(diagnostics), path(breakpoints)

    output:
      tuple val(meta), path('*_cn_plot.png'), emit: 'plot'

    script:
    def bp_arg = breakpoints.name != 'NO_FILE' ? "--breakpoints ${breakpoints}" : ''
    """
    locate cn-plot \
        --input ${table} \
        --cn ${cn_table} \
        --purity-ploidy ${purity_ploidy} \
        --diagnostics ${diagnostics} \
        --output ${meta.sampleID}_cn_plot.png \
        ${bp_arg}
    """
}
