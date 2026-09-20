#!/usr/bin/env nextflow

process AGGREGATE_PROMOTERS {
    tag "${meta.sampleID}-${meta.chr}"
    label "process_medium"
    label "error_retry"
    container 'docker://lvaleriani/locate:v1.1'

    input:
      tuple val(meta), path(classified), path(cn_segments), path(reftss_promoters), path(imprinted_genes)

    output:
      tuple val(meta), path('*_promoters.csv'), emit: 'promoters'

    script:
    def cn_arg   = cn_segments.name != 'NO_FILE' ? "--cn ${cn_segments} --cn-fmt nf-locate" : ''
    def excl_arg = imprinted_genes.name != 'NO_FILE' ? "--exclude-imprinted ${imprinted_genes}" : ''
    def pAsm = params.methylation_p_asm_threshold ?: 0.9
    def pTsm = params.methylation_p_tsm_threshold ?: 0.9
    def pNsm = params.methylation_p_nsm_threshold ?: 0.9
    """
    locate methylation aggregate-promoters \
        --input ${classified} \
        --output ${meta.sampleID}_${meta.chr}_promoters.csv \
        --promoters ${reftss_promoters} \
        --promoters-fmt reftss \
        --chrom ${meta.chr} \
        --p-asm-threshold ${pAsm} \
        --p-tsm-threshold ${pTsm} \
        --p-nsm-threshold ${pNsm} \
        ${cn_arg} ${excl_arg}
    """
}
