#!/usr/bin/env nextflow

process SPLIT_TABLE_BY_CHROM {
    tag "${meta.sampleID}"
    label "process_low"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(table)

    output:
      tuple val(meta), path('chrom_tables/*_table.csv'), path('chrom_tables/offsets.csv'), emit: 'chrom_tables'

    script:
    """
    mkdir -p chrom_tables
    locate prepare-table split-by-chrom \
        --input ${table} \
        --out-dir chrom_tables
    """
}
