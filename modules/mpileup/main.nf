#!/usr/bin/env nextflow

process MPILEUP {
  tag "${meta.sampleID}-${meta.chr}-${meta.type}"
  label "process_medium"
  label "error_retry"
  container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.20--h8b25389_0'

  input:
  tuple val(meta), path(bam), path(bai), path(vcf), path(ref), path(fai)
  
  output:
  tuple val(meta), path('*.vcf.gz'), path('*.vcf.gz.csi'), emit: vcf

  script:
  """
  bcftools mpileup \
      -f "${ref}" \
      -T "${vcf}" \
      --min-MQ 20 \
      --min-BQ 20 \
      -a DP,AD \
      -O u \
      "${bam}" | \
  bcftools call \
      --multiallelic-caller \
      --keep-alts \
      -O z \
      -o raw.vcf.gz && \
  bcftools index raw.vcf.gz && \
  bcftools +fill-tags raw.vcf.gz \
      -O z \
      -o ${meta.sampleID}-${meta.chr}-${meta.type}.vcf.gz \
      -- -t AF && \
  bcftools index ${meta.sampleID}-${meta.chr}-${meta.type}.vcf.gz
  """
}
