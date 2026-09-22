#!/usr/bin/env nextflow

process BIN_TABLE {
    // Aggregates a single-chromosome table into fixed-size genomic bins
    // (median baf/dr/vaf) before segmentation. DR's noise has strong,
    // slowly-decaying local autocorrelation (measured ~0.94 at lag 1,
    // still ~0.26 at lag 500 positions -- real local structure like
    // mapping/GC bias, not iid noise), so per-bin medians reduce noise
    // substantially for BAF/VAF and modestly for DR, trading off some
    // breakpoint positional resolution. bin_size=30000 matches the
    // validated reference smoothing pipeline (data_smoothing() in
    // locate_reproducibility/locate/2_segment/utils.R).
    tag "${meta.sampleID}-${meta.chr}"
    label "process_low"
    label "error_retry"
    container 'docker://lvaleriani/locate:v1.3'

    input:
      // staged in a subfolder: the input and the output are both <chr>_table.csv, and
      // Nextflow stages inputs as symlinks, so writing the output next to a same-named
      // input would write THROUGH the symlink and overwrite the upstream task's file
      // (silently corrupting its cached output).
      tuple val(meta), path(table, stageAs: 'input/*')

    output:
      tuple val(meta), path("${meta.chr}_table.csv"), emit: 'table'

    script:
    def bin_size = params.segmentation_bin_size ?: 30000
    def min_snps = params.segmentation_bin_min_snps ?: 10
    """
    locate prepare-table bin-table \
        --input ${table} \
        --output ${meta.chr}_table.csv \
        --bin-size ${bin_size} \
        --min-snps ${min_snps}
    """
}
