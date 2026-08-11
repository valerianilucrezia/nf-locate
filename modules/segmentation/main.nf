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
    // Settings per [[project_segmentation_oversegment_policy]]: bias
    // toward high recall (more breakpoints), since use_segment_pooled CN
    // inference is robust to over-segmentation but not under-segmentation
    // (under-seg costs up to -0.38 accuracy). mode=max/window_size=5/
    // threshold=1e-10 was the highest-recall combo measured on sim_17
    // (recall 0.917, precision 0.175) among all settings swept in
    // evaluate_segment.py's segment_metrics_*.csv, and reproduced the
    // reference multipcf+MiMMAl breakpoints on real COLO829 chr7/chr17.
    def mode        = params.segmentation_mode        ?: 'max'
    def frequencies = params.segmentation_frequencies ?: 'vaf,baf,dr'
    def window_size = params.segmentation_window_size ?: 5
    def threshold   = params.segmentation_threshold    ?: '1e-10'
    """
    locate segmentation \
        --input ${table} \
        --output ${meta.chr}_segments.csv \
        --mode ${mode} \
        --frequencies ${frequencies} \
        --window-size ${window_size} \
        --threshold ${threshold}
    """
}
