#!/usr/bin/env nextflow

process PREPARE_TABLE_VCF {
    tag "${meta.sampleID}-${meta.chr}"
    label "process_low"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(vcf), path(tbi)

    output:
      tuple val(meta), path('*_table.csv'), emit: 'table'

    script:
    def baf_field = params.locate_baf_field ?: 'BAF_H1'
    def dr_field  = params.locate_dr_field  ?: 'DR'
    """
    locate prepare-table from-vcf \
        --vcf ${vcf} \
        --output ${meta.sampleID}_${meta.chr}_table.csv \
        --baf-field ${baf_field} \
        --dr-field ${dr_field}
    """
}
