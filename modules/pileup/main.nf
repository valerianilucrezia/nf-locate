#!/usr/bin/env nextflow

process PILEUP_CN {
    tag "${meta.sampleID}-${meta.type}-${meta.chr}"
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'

    input:
    tuple val(meta), path(bam), path(bai), path(bed), path(ref_genome), path(ref_fai)

    output:
    tuple val(meta), path('*.vcf'), emit: 'chr_vcf' 

    script:

    """
    filename=\$(basename "${bed}")
    OUTPUT_VCF="\${filename}_pileup.vcf"

    bcftools mpileup -Ou ${bam} -R ${bed} -f ${ref_genome} \
      --skip-indels \
      --config ont \
      --annotate FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SP,INFO/AD,INFO/ADF,INFO/ADR \
      --threads 12 | bcftools call -Ov -m -P 0.1 --threads 12 -o \${OUTPUT_VCF}
      
    """
}
