#!/usr/bin/env nextflow

process SPLIT_ALIGN {
  tag "${meta.sampleID}-chr${ch}"
  container 'https://depot.galaxyproject.org/singularity/samtools%3A1.9--h91753b0_8'


  input:
    tuple val(ch), val(meta), path(align), path(align_index)

  output:
    tuple val(ch), val(meta), path('*.bam'), path('*.bai'), emit: chr_bam

  script:
    """

    #!/usr/bin/env bash
    OUTPUT_BAM="${meta.sampleID}_${meta.type}_chr${ch}.bam"

    samtools view -@ 12 -b -h -o \${OUTPUT_BAM} "${align}" "chr${ch}"
    samtools index -@ 12 \${OUTPUT_BAM}

    """

}