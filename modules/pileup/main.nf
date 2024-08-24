#!/usr/bin/env nextflow

params.outdir = "${workflow.launchDir}/results/"
params.ref_genome = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna'
params.ref_fai = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai'
params.bam_data="${workflow.launchDir}/results/split_bam"
params.bed_data="/u/area/ffabris/fast/long_reads_pipeline/test_data/pos"

//work harder or input files to be more general

chr_ch = Channel.from(1..4)//Channel.from(1..22)
bam_ch = Channel.fromPath(params.bam_data, checkIfExists: true) 
bed_ch = Channel.fromPath(params.bed_data, checkIfExists: true) 
ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 
ref_fai_ch = Channel.fromPath(params.ref_fai, checkIfExists: true)

combined_ch = chr_ch.combine(bam_ch.combine(bed_ch).combine(ref_genome_ch).combine(ref_fai_ch))



process PILEUP_CN {
    tag "chr${ch}"
    publishDir "${params.outdir}pileup_cn/", mode: 'copy'
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.9--ha228f0b_4'
    memory '200 GB'
    time '48h'
    cpus 12

    input:
      tuple val(ch), path(sample_bam), path(sample_bed), path(ref), path(ref_fai)

    output:
      path '*.vcf', emit: 'vcf' 

    script:
      """
      INPUT_BAM="${sample_bam}/chr${ch}-COLO829.bam"
      INPUT_BED="${sample_bed}/G1000_loci_hg38_chr${ch}.txt"
      OUTPUT_VCF="g100_chr${ch}.vcf"

      bcftools mpileup -Ou \${INPUT_BAM} -R \${INPUT_BED} -f ${ref} \
        --annotate FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SP,INFO/AD,INFO/ADF,INFO/ADR \
        -Q 0 \
        --threads 12 \
        | bcftools call -Ov -m --threads 12 -o \${OUTPUT_VCF}
      """
}

workflow {
    split_bam_ch = PILEUP_CN(combined_ch)
}