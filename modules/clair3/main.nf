#!/usr/bin/env nextflow

process CLAIR3 {
  tag "${meta.sampleID}-${meta.chr}-${meta.type}"
  label "process_high_long"
  label "error_retry"
  container = "docker://hkubal/clair3:latest"

  input:
  tuple val(meta), path(bam), path(bai), path(vcf), path(ref), path(fai)

  output:
  tuple val(meta), path("${meta.type}/${meta.chr}/pileup.vcf.gz"), path("${meta.type}/${meta.chr}/pileup.vcf.gz.tbi"), emit: 'pileup'
  tuple val(meta), path("${meta.type}/${meta.chr}/merge_output.vcf.gz"), path("${meta.type}/${meta.chr}/merge_output.vcf.gz.tbi"), emit: 'merge'
  tuple val(meta), path("${meta.type}/${meta.chr}/full_alignment.vcf.gz"), path("${meta.type}/${meta.chr}/full_alignment.vcf.gz.tbi"), emit: 'full' 

  script:
  """
  /opt/bin/run_clair3.sh \
  --bam_fn="${bam}" \
  --ref_fn="${ref}" \
  --threads=12 \
  --platform="ont" \
  --model_path="/opt/models/${params.model_name}" \
  --output="${meta.type}/${meta.chr}" \
  --vcf_fn="${vcf}"
  """
}
