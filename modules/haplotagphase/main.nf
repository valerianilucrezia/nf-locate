#!/usr/bin/env nextflow

process HAPLOTAGPHASE {
  tag "${meta.sampleID}-${meta.chr}"
  label "process_medium"
  label "error_retry"
  container 'https://depot.galaxyproject.org/singularity/whatshap%3A2.3--py39h1f90b4d_0'

  input:
    tuple val(meta), path(vcf), path(idx), path(bam), path(bai), path(ref_genome), path(idx_ref_genome)

  output:
    tuple val(meta), path('*.vcf.gz'), emit: vcf

  script:
    """
    whatshap haplotagphase \
    -o "${meta.sampleID}_${meta.chr}_phased.vcf.gz" \
    --ignore-read-group \
    -r ${ref_genome} \
    ${vcf} ${bam} 
    """
}
