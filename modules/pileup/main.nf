#!/usr/bin/env nextflow

process PILEUP_CN {
    tag "${name}--chr${ch}"
    publishDir "${workflow.launchDir}/results/modkit/", mode: 'copy'
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'
    memory '200 GB'
    time '12h'
    cpus 12

    input:
      tuple val(name), val(ch), path(chr_bam), path(chr_bai), path(sample_bed), path(ref), path(ref_fai)

    output:
      tuple val(name), val(ch), path('*.vcf'), emit: 'chr_vcf' 

    script:
      """
      INPUT_BAM="${chr_bam}"
      INPUT_BED="${sample_bed}/G1000_loci_hg38_chr${ch}.txt"
      OUTPUT_VCF="g100_chr${ch}_${name}.vcf"

      bcftools mpileup -Ou \${INPUT_BAM} -R \${INPUT_BED} -f ${ref} \
        --annotate FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SP,INFO/AD,INFO/ADF,INFO/ADR \
        -Q 0 \
        --threads 12 | bcftools call -Ov -m --threads 12 -o \${OUTPUT_VCF}
      """
}
