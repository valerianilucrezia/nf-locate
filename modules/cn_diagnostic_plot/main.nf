#!/usr/bin/env nextflow

process CN_DIAGNOSTIC_PLOT {
    tag "${meta.sampleID}"
    label "process_low"
    label "error_retry"
    container 'docker://lvaleriani/locate:v1'

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
