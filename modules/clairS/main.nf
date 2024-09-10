#!/usr/bin/env nextflow

process CLAIRS {
  tag "${meta.sampleID}"
  container = "docker://hkubal/clairs:latest"

  input:
   tuple val(meta), path(tumor_bam), path(tumor_bai), path(normal_bam), path(normal_bai)
   tuple path(ref_genome), path(ref_fai)

  output:
    tuple val(meta), path('clair3_normal_germline_output.vcf.gz'), path('clair3_normal_germline_output.vcf.gz.tbi'), emit: 'g_normal'
    tuple val(meta), path('clair3_tumor_germline_output.vcf.gz'), path('clair3_tumor_germline_output.vcf.gz.tbi'), emit: 'g_tumor'
    tuple val(meta), path('*variants.vcf.gz'), path('*variants.vcf.gz.tbi'), emit: 'somatic' 

  script:
    """
    run_clairs \
    --tumor_bam_fn="${tumor_bam}" \
    --normal_bam_fn="${normal_bam}"\
    --ref_fn="${ref_genome}"\
    --threads=36 \
    --platform="ont_r9_guppy" \
    --output_dir="" \
    --output_prefix="${meta.sampleID}_variants" \
    --snv_min_af=0.05 \
    --enable_clair3_germline_output \
    -c chr22

    #chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21
    """
}
