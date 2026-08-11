#!/usr/bin/env nextflow

process METHYLATION_INFERENCE {
    tag "${meta.sampleID}-${meta.chr}"
    label "process_high"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(table), path(purity_ploidy)

    output:
      tuple val(meta), path('*_betaT.csv'), emit: 'betat'
      tuple val(meta), path('*_asm.csv'), emit: 'asm'

    script:
    def model   = params.methylation_model ?: 'binomial'
    def lr      = params.methylation_lr    ?: 1e-2
    def steps   = params.methylation_steps ?: 6000
    def n_draws = params.asm_n_draws       ?: 200
    def a       = params.asm_a             ?: 1.0
    def b       = params.asm_b             ?: 1.0
    def pi      = params.asm_pi            ?: 0.5
    """
    rho=\$(awk -F',' 'NR==1{for(i=1;i<=NF;i++) if(\$i=="purity") c=i} NR==2{print \$c}' ${purity_ploidy})

    locate methylation infer-asm \
        --input ${table} \
        --output-betat ${meta.sampleID}_${meta.chr}_betaT.csv \
        --output-asm ${meta.sampleID}_${meta.chr}_asm.csv \
        --model ${model} \
        --rho \${rho} \
        --lr ${lr} \
        --steps ${steps} \
        --n-draws ${n_draws} \
        --a ${a} \
        --b ${b} \
        --pi ${pi}
    """
}
