#!/usr/bin/env nextflow

process SPLIT_BAM {
  tag "${name}-chr${ch}"
  container 'https://depot.galaxyproject.org/singularity/samtools%3A1.9--h91753b0_8'


  input:
    tuple val(ch), val(name), path(sample_bam), path(sample_bai)

  output:
    tuple val(name), val(ch), path('*.bam'), path('*.bai'), emit: chr_bam

  script:
    """
    #!/usr/bin/env bash
    OUTPUT_BAM="chr${ch}-${name}.bam"

    samtools view -b -h -o \${OUTPUT_BAM} "${sample_bam}" "chr${ch}"
    samtools index \${OUTPUT_BAM}

    """

}