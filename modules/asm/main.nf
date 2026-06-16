#!/usr/bin/env nextflow

process ASM {
    tag "${meta.sampleID}-${meta.chr}"
    label "process_medium"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(table)

    output:
      tuple val(meta), path('*_asm.csv'), emit: 'asm'

    script:
    def a     = params.asm_a     ?: 1.0
    def b     = params.asm_b     ?: 1.0
    def pi    = params.asm_pi    ?: 0.5
    def alpha = params.asm_alpha ?: 0.05
    """
    locate methylation asm \
        --input ${table} \
        --output ${meta.sampleID}_${meta.chr}_asm.csv \
        --a ${a} \
        --b ${b} \
        --pi ${pi} \
        --alpha ${alpha}
    """
}
