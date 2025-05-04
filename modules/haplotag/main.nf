#!/usr/bin/env nextflow

process HAPLOTAG_BAM {
  tag "${meta.sampleID}-${meta.chr}"
  container 'https://depot.galaxyproject.org/singularity/whatshap%3A2.3--py39h1f90b4d_0'


  input:
    tuple val(meta), path(vcf), path(idx), path(bam), path(bai), path(ref_genome), path(idx_ref_genome)

  output:
    tuple val(meta), path('*.bam'), emit: bam
    tuple val(meta), path('*haplotag_list'), emit: list
  script:
    """
    whatshap haplotag  \
    -o "${meta.sampleID}_${meta.chr}_haplotagged.bam" \
    --reference ${ref_genome} \
    --output-haplotag-list "${meta.sampleID}_${meta.chr}_haplotag_list" \
    --output-threads 12 \
    --ignore-read-groups \
    ${vcf} ${bam}
    """
}
