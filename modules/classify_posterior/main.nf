#!/usr/bin/env nextflow

process CLASSIFY_POSTERIOR {
    tag "${meta.sampleID}-${meta.chr}"
    label "process_high"
    label "error_retry"
    container 'docker://lvaleriani/locate:v1'

    input:
      tuple val(meta), path(table), path(purity_ploidy)

    output:
      tuple val(meta), path('*_classified.csv'), emit: 'classified'

    script:
    def model  = params.methylation_model ?: 'binomial'
    def lr     = params.methylation_lr    ?: 1e-2
    def steps  = params.methylation_steps ?: 6000
    def tauLo  = params.methylation_tau_lo ?: 0.30
    def tauHi  = params.methylation_tau_hi ?: 0.70
    def chunk  = params.methylation_chunk_size ?: 50000
    def batch  = params.methylation_sample_batch_size ?: 100
    """
    rho=\$(awk -F',' 'NR==1{for(i=1;i<=NF;i++) if(\$i=="purity") c=i} NR==2{print \$c}' ${purity_ploidy})

    locate methylation classify-posterior \
        --input ${table} \
        --output ${meta.sampleID}_${meta.chr}_classified.csv \
        --model ${model} \
        --rho \${rho} \
        --lr ${lr} \
        --steps ${steps} \
        --tau-lo ${tauLo} \
        --tau-hi ${tauHi} \
        --chunk-size ${chunk} \
        --sample-batch-size ${batch}
    """
}
