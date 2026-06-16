#!/usr/bin/env nextflow

process PREPARE_TABLE_METHYLATION {
    tag "${meta.sampleID}-${meta.chr}"
    label "process_low"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(h1_tumor), path(h1_tumor_tbi), path(h2_tumor), path(h2_tumor_tbi), path(h1_normal), path(h1_normal_tbi), path(h2_normal), path(h2_normal_tbi)

    output:
      tuple val(meta), path('*_methylation_table.csv'), emit: 'table'

    script:
    """
    locate prepare-table from-bed \
        --h1-tumor ${h1_tumor} \
        --h2-tumor ${h2_tumor} \
        --h1-normal ${h1_normal} \
        --h2-normal ${h2_normal} \
        --output ${meta.sampleID}_${meta.chr}_methylation_table.csv
    """
}
