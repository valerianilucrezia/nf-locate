#!/usr/bin/env nextflow

process METHYLATION_INFERENCE {
    tag "${meta.sampleID}-${meta.chr}"
    label "process_high"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(table)

    output:
      tuple val(meta), path('*_betaT.csv'), emit: 'betat'

    script:
    def model = params.methylation_model ?: 'binomial'
    def rho   = params.methylation_rho   ?: 0.6
    def lr    = params.methylation_lr    ?: 1e-2
    def steps = params.methylation_steps ?: 6000
    """
    locate methylation infer \
        --input ${table} \
        --output ${meta.sampleID}_${meta.chr}_betaT.csv \
        --model ${model} \
        --rho ${rho} \
        --lr ${lr} \
        --steps ${steps}
    """
}
