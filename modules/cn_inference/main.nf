#!/usr/bin/env nextflow

process CN_INFERENCE {
    tag "${meta.sampleID}"
    label "process_high"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(table), path(breakpoints)

    output:
      tuple val(meta), path('*_cn.csv'), emit: 'cn'
      tuple val(meta), path('*_purity_ploidy.csv'), emit: 'purity_ploidy'

    script:
    def steps        = params.cn_steps        ?: 2000
    def lr           = params.cn_lr           ?: 0.05
    def guide        = params.cn_guide        ?: 'delta'
    def hidden_dim   = params.cn_hidden_dim   ?: 3
    def prior_purity = params.cn_prior_purity ?: 0.9
    def prior_ploidy = params.cn_prior_ploidy ?: 2.0
    def bp_strength  = params.cn_bp_strength  ?: 3.0
    def min_seg_len  = params.cn_min_seg_len  ?: 1
    def bp_arg       = breakpoints.name != 'NO_FILE' ? "--breakpoints ${breakpoints} --bp-strength ${bp_strength}" : ''
    """
    locate cn \
        --input ${table} \
        --output ${meta.sampleID}_cn.csv \
        --output-purity-ploidy ${meta.sampleID}_purity_ploidy.csv \
        --steps ${steps} \
        --lr ${lr} \
        --guide ${guide} \
        --hidden-dim ${hidden_dim} \
        --prior-purity ${prior_purity} \
        --prior-ploidy ${prior_ploidy} \
        --min-seg-len ${min_seg_len} \
        ${bp_arg}
    """
}
