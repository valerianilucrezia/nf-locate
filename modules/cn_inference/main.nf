#!/usr/bin/env nextflow

process CN_INFERENCE {
    tag "${meta.sampleID}"
    label "process_high"
    label "error_retry"
    container 'docker://lvaleriani/locate:v1.1'

    input:
      tuple val(meta), path(table), path(breakpoints)

    output:
      tuple val(meta), path('*_cn.csv'), emit: 'cn'
      tuple val(meta), path('*_purity_ploidy.csv'), emit: 'purity_ploidy'
      tuple val(meta), path('*_diagnostics.npz'), emit: 'diagnostics'

    script:
    // Purity/ploidy are INFERRED by default (params.cn_fix_purity/cn_fix_ploidy = false).
    // cn_prior_purity/cn_prior_ploidy are optional: if set they are a soft anchor, or the
    // fixed value when the matching cn_fix_* is true. Inferring them needs breakpoints
    // (segment-pooled likelihood), i.e. params.run_segmentation = true.
    def steps        = params.cn_steps        ?: 500
    def lr           = params.cn_lr           ?: 0.05
    def guide        = params.cn_guide        ?: 'delta'
    def hidden_dim   = params.cn_hidden_dim   ?: 6
    def bp_strength  = params.cn_bp_strength  ?: 3.0
    def min_seg_len  = params.cn_min_seg_len  ?: 1
    def sample_type  = params.cn_sample_type  ?: 'clinical'
    def bp_arg       = breakpoints.name != 'NO_FILE' ? "--breakpoints ${breakpoints} --bp-strength ${bp_strength} --max-pos-per-segment ${params.cn_max_pos_per_segment ?: 500}" : ''
    def purity_arg   = params.cn_prior_purity  != null ? "--prior-purity ${params.cn_prior_purity} --purity-variance ${params.cn_purity_variance ?: 0.05}" : ''
    def ploidy_arg   = params.cn_prior_ploidy  != null ? "--prior-ploidy ${params.cn_prior_ploidy}" : ''
    def fix_p_arg    = params.cn_fix_purity.toString() == 'true' ? '--fix-purity' : ''
    def fix_q_arg    = params.cn_fix_ploidy.toString() == 'true' ? '--fix-ploidy' : ''
    """
    locate cn \
        --input ${table} \
        --output ${meta.sampleID}_cn.csv \
        --output-purity-ploidy ${meta.sampleID}_purity_ploidy.csv \
        --output-diagnostics ${meta.sampleID}_diagnostics.npz \
        --steps ${steps} \
        --lr ${lr} \
        --guide ${guide} \
        --hidden-dim ${hidden_dim} \
        --sample-type ${sample_type} \
        --min-seg-len ${min_seg_len} \
        ${purity_arg} ${ploidy_arg} ${fix_p_arg} ${fix_q_arg} ${bp_arg}
    """
}
