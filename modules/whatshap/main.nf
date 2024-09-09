#!/usr/bin/env nextflow

process WHATSHAP {
    tag "${meta.sampleID}-${meta.type}-chr${meta.chr}"
    container 'https://depot.galaxyproject.org/singularity/whatshap%3A2.3--py39h1f90b4d_0'

    input:
        tuple val(meta), path(bam), path(bai), path(vcf), path(ref), path(ref_fai)

    output:
        tuple val(meta), path('*.vcf'), emit: 'phased_chr_vcf' 

    script:

        """
        INPUT_BAM="${bam}"
        INPUT_VCF="${vcf}"
        OUTPUT_VCF="phased_chr${meta.chr}_${meta.sampleID}_${meta.type}.vcf"

        whatshap phase -o \${OUTPUT_VCF} \
            --ignore-read-groups \
            --reference ${ref} \
            \${INPUT_VCF} \
            \${INPUT_BAM}
        """
}
