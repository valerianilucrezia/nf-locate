#!/usr/bin/env nextflow

process PREPARE_TABLE_VCF {
    tag "${meta.sampleID}"
    label "process_low"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    // container 'TODO/locate:1.0.0'

    input:
      // vcf is now the whole-genome VCF for this sample (all chromosomes
      // concatenated by BCFTOOLS_CONCAT), not a single chromosome's --
      // needed so DP_T/DP_N can be normalized genome-wide rather than per
      // chromosome (see battenberg_phase.R).
      tuple val(meta), path(vcf), path(tbi), path(low_mappability_bed)

    output:
      tuple val(meta), path('*_table.csv'), emit: 'table'

    script:
    def baf_h1_field     = params.locate_baf_h1_field    ?: 'BAF_H1'
    def baf_h2_field     = params.locate_baf_h2_field    ?: 'BAF_H2'
    def dp_tumor_field   = params.locate_dp_tumor_field  ?: 'DP_T'
    def dp_normal_field  = params.locate_dp_normal_field ?: 'DP_N'
    def lowmap_arg       = low_mappability_bed.name != 'NO_FILE' ? "--low-mappability-bed ${low_mappability_bed}" : ''
    """
    locate prepare-table from-vcf \
        --vcf ${vcf} \
        --output ${meta.sampleID}_table.csv \
        --baf-h1-field ${baf_h1_field} \
        --baf-h2-field ${baf_h2_field} \
        --dp-tumor-field ${dp_tumor_field} \
        --dp-normal-field ${dp_normal_field} \
        ${lowmap_arg}
    """
}
