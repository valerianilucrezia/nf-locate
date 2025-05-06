#!/usr/bin/env nextflow

process SPLIT_HAPLOTYPE {
  tag "${meta.sampleID}-${meta.chr}-${meta.type}"
  container 'https://depot.galaxyproject.org/singularity/whatshap%3A2.3--py39h1f90b4d_0'


  input:
    tuple val(meta), path(bam), path(haplotag_list)

  output:
    tuple val(meta), path('h1_*.bam'), emit: h1_bam
    tuple val(meta), path('h2_*.bam'), emit: h2_bam
    tuple val(meta), path('untag_*.bam'), emit: untag_bam


  script:
    """
    whatshap split \
        --output-h1 h1_${meta.sampleID}_${meta.chr}.bam \
        --output-h2 h2_${meta.sampleID}_${meta.chr}.bam \
        --output-untagged untag_${meta.sampleID}_${meta.chr}.bam \
        ${bam} \
        ${haplotag_list}

    """

}