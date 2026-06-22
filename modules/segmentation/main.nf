#!/usr/bin/env nextflow

process SEGMENTATION {
    // Runs once per (sampleID, chr) -- MultivariateClaSP has no chromosome
    // concept, so segmenting the whole genome in one call would let it
    // report spurious breakpoints at chromosome junctions. The output is
    // named <chr>_segments.csv (not sampleID-based) because
    // MERGE_BREAKPOINTS parses the chromosome back out of this filename.
    tag "${meta.sampleID}-${meta.chr}"
    label "process_medium"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(table)

    output:
      tuple val(meta), path("${meta.chr}_segments.csv"), emit: 'segments'

    script:
    def mode        = params.segmentation_mode        ?: 'max'
    def frequencies = params.segmentation_frequencies ?: 'vaf,baf,dr'
    def window_size = params.segmentation_window_size ?: 'suss'
    """
    locate segmentation \
        --input ${table} \
        --output ${meta.chr}_segments.csv \
        --mode ${mode} \
        --frequencies ${frequencies} \
        --window-size ${window_size}
    """
}
