#!/usr/bin/env nextflow

process CN_DIAGNOSTIC_PLOT {
    tag "${meta.sampleID}"
    label "process_low"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(diagnostics)

    output:
      tuple val(meta), path('*_cn_diagnostic_plot.png'), emit: 'plot'

    script:
    """
    locate cn-diagnostic-plot \
        --diagnostics ${diagnostics} \
        --output ${meta.sampleID}_cn_diagnostic_plot.png
    """
}
