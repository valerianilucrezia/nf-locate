#!/usr/bin/env nextflow

process PREPARE_TABLE_SOMATIC_VCF {
    tag "${meta.sampleID}"
    label "process_low"
    label "error_retry"
    container 'docker://lvaleriani/locate:v1.2'

    input:
      tuple val(meta), path(vcf)

    output:
      tuple val(meta), path('*_somatic_table.csv'), emit: 'table'

    script:
    def af_field = params.locate_somatic_af_field ?: 'AF'
    def dp_field = params.locate_somatic_dp_field ?: 'DP'
    """
    locate prepare-table from-somatic-vcf \
        --vcf ${vcf} \
        --output ${meta.sampleID}_somatic_table.csv \
        --af-field ${af_field} \
        --dp-field ${dp_field}
    """
}
