#!/usr/bin/env nextflow

process SEGMENTATION {
    tag "${meta.sampleID}-${meta.chr}"
    label "process_medium"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(table)

    output:
      tuple val(meta), path('*_segments.csv'), emit: 'segments'

    script:
    def mode        = params.segmentation_mode        ?: 'max'
    def frequencies = params.segmentation_frequencies ?: 'vaf,baf,dr'
    def window_size = params.segmentation_window_size ?: 'suss'
    """
    locate segmentation \
        --input ${table} \
        --output ${meta.sampleID}_${meta.chr}_segments.csv \
        --mode ${mode} \
        --frequencies ${frequencies} \
        --window-size ${window_size}
    """
}
