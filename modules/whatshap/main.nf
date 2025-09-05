#!/usr/bin/env nextflow

process WHATSHAP {
  tag "${meta.sampleID}-${meta.chr}"
  label "process_low"
  label "error_retry"
  container 'https://depot.galaxyproject.org/singularity/whatshap%3A2.3--py39h1f90b4d_0'

  input:
    tuple val(meta), path(vcf), path(tbi), path(t_bam),  path(t_bai), path(n_bam), path(n_bai), path(ref), path(fai)

  output:
    tuple val(meta), path('*.vcf'), emit: vcf

  script:
    """
    whatshap phase \
        -o ${meta.sampleID}_${meta.chr}.vcf \
        --ignore-read-groups \
        --reference=${ref} ${vcf} ${t_bam} ${n_bam}
    """

}