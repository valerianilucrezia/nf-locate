#!/usr/bin/env nextflow

process ALIGN_VAF {
    // Used both genome-wide (meta has no chr) and once per chromosome (meta
    // has chr, when fanned out for per-chromosome SEGMENTATION) -- the
    // output filename includes chr when present so parallel per-chromosome
    // tasks for the same sample don't all publish to the same filename and
    // overwrite each other.
    tag "${meta.chr ? meta.sampleID + '-' + meta.chr : meta.sampleID}"
    label "process_low"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(grid_table), path(somatic_table)

    output:
      tuple val(meta), path('*_table_vaf.csv'), emit: 'table'

    script:
    def out_name = meta.chr ? "${meta.sampleID}_${meta.chr}_table_vaf.csv" : "${meta.sampleID}_table_vaf.csv"
    """
    locate prepare-table align-vaf \
        --grid ${grid_table} \
        --snv ${somatic_table} \
        --output ${out_name}
    """
}
