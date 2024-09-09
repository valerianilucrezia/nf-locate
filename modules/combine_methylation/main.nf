#!/usr/bin/env nextflow

process COMBINE {
    tag "${meta.sampleID}-chr${meta.chr}"
    container 'docker://lvaleriani/long_reads:latest'

    input:
      tuple  val(meta), path(vcf_T), path(vcf_N), path(rds)

    output:
      tuple val(meta),path ("*.RDS"), emit: 'rds'

    script:
      """
      combine.R ${meta.chr} ${vcf_T} ${vcf_N} ${rds} ${meta.sampleID}
      """
}


