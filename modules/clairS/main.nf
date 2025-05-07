#!/usr/bin/env nextflow

process CLAIRS {
  tag "${meta.sampleID}"
  label "process_high_long"
  label "error_retry"
  container = "docker://hkubal/clairs:latest"

  input:
  tuple val(meta), path(tumor_bam), path(tumor_bai), path(normal_bam), path(normal_bai), path(ref_genome), path(ref_fai)

  output:
  tuple val(meta), path('*variants.vcf.gz'), path('*variants.vcf.gz.tbi'), emit: 'somatic' 

  script:
  """
  run_clairs \
  --tumor_bam_fn="${tumor_bam}" \
  --normal_bam_fn="${normal_bam}"\
  --ref_fn="${ref_genome}"\
  --threads=12 \
  --platform=${params.platform} \
  --output_dir="" \
  --output_prefix="${meta.sampleID}_variants" \
  --snv_min_af=0.05 \
  """
}
