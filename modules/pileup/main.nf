#!/usr/bin/env nextflow

process PILEUP_CN {
    tag "${meta.sampleID}-${meta.type}-chr${meta.chr}"
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'

    input:

      tuple val(meta), path(bam), path(bai), path(bed), path(ref), path(ref_fai)

    output:
      tuple val(meta), path(bam), path(bai), path('*.vcf'), emit: 'chr_vcf' 

    script:

      """
      INPUT_BAM="${bam}"
      INPUT_BED="${bed}/G1000_loci_hg38_chr${meta.chr}.txt"
      OUTPUT_VCF="chr${meta.chr}_${meta.sampleID}_${meta.type}.vcf"

      bcftools mpileup -Ou \${INPUT_BAM} -R \${INPUT_BED} -f ${ref} \
        --annotate FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SP,INFO/AD,INFO/ADF,INFO/ADR \
        -Q 0 \
        --threads 12 | bcftools call -Ov -m --threads 12 -o \${OUTPUT_VCF}
      """
}
