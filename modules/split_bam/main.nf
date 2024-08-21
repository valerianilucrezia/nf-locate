#!/usr/bin/env nextflow

params.outdir = "${workflow.launchDir}/results/"
params.bam_data = '/u/area/ffabris/fast/long_reads_pipeline/test_data/'

chr_ch = Channel.from(1..22)
bam_ch = Channel.fromPath("${params.bam_data}*.bam", checkIfExists: true) 
chr_bam_ch = chr_ch.combine(bam_ch)


process SPLIT_BAM {
  tag "chr${ch}"
  publishDir "${params.outdir}split_bam/", mode: 'copy'
  container 'https://depot.galaxyproject.org/singularity/samtools%3A1.9--h91753b0_8'
  memory '50 GB'
  
  input:
    tuple val(ch), path(sample_bam)

  output:
    tuple val(ch), path('*.bam'), emit: bam
    tuple val(ch), path('*.bai'), emit: bai

  script:
    """
    #!/usr/bin/env bash
    OUTPUT_NAME_BAM=\"chr${ch}-${sample_bam}\"

    samtools view -b -h -o \${OUTPUT_NAME_BAM} ${sample_bam} "chr${ch}"
    samtools index \${OUTPUT_NAME_BAM}

    """

}

workflow {
    split_bam_ch = SPLIT_BAM(chr_bam_ch)
}