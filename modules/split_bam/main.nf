#!/usr/bin/env nextflow

params.outdir = "${workflow.launchDir}/results/"
params.bam_data = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/data/raw/COLO829'

chr_ch = Channel.from(1..22)
bam_ch = Channel.fromPath(params.bam_data, checkIfExists: true) 
chr_bam_ch = chr_ch.combine(bam_ch)


process SPLIT_BAM {
  tag "chr${ch}"
  publishDir "${params.outdir}split_bam/", mode: 'copy'
  container 'https://depot.galaxyproject.org/singularity/samtools%3A1.9--h91753b0_8'
  memory '200 GB'
  time '10h'

  
  input:
    tuple val(ch), path(sample_bam)

  output:
    tuple val(ch), path('*.bam'), emit: bam
    tuple val(ch), path('*.bai'), emit: bai

  script:
    """
    #!/usr/bin/env bash

    samtools view -b -h -o "chr${ch}-COLO829.bam" "${sample_bam}/COLO829.bam" "chr${ch}"
    samtools index "chr${ch}-COLO829.bam"

    """

}

workflow {
    split_bam_ch = SPLIT_BAM(chr_bam_ch)
}