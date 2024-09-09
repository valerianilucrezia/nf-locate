#!/usr/bin/env nextflow

process SPLIT_BAM {
  tag "${meta.sampleID}-chr${ch}"
  container 'https://depot.galaxyproject.org/singularity/samtools%3A1.9--h91753b0_8'


  input:
    tuple val(ch), val(meta), path(bam), path(bai)

  output:
    tuple val(ch), val(meta), path('*.bam'), path('*.bai'), emit: chr_bam

  script:
    """
    OUTPUT_BAM="chr${ch}_${meta.sampleID}_${meta.type}.bam"

    samtools view -@ 12 -b -h -o \${OUTPUT_BAM} "${bam}" "chr${ch}"
    samtools index -@ 12 \${OUTPUT_BAM}

    """

}