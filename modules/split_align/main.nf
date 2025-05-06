#!/usr/bin/env nextflow

process SPLIT_ALIGN {
  tag "${meta.sampleID}-${ch}-${meta.type}"
  labe "process_medium"
  label "error_retry"
  container 'https://depot.galaxyproject.org/singularity/samtools%3A1.9--h91753b0_8'


  input:
    tuple val(ch), val(meta), path(align), path(align_index)

  output:
    tuple val(ch), val(meta), path('*.bam'), path('*.bai'), emit: chr_bam

  script:
    """
    OUTPUT_BAM="${meta.sampleID}_${meta.type}_${ch}.bam"

    samtools view -@ 12 -b -h -o \${OUTPUT_BAM} "${align}" "${ch}"
    samtools index -@ 12 \${OUTPUT_BAM}

    """

}