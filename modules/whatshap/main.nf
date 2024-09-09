#!/usr/bin/env nextflow

process WHATSHAP {
    tag "${name}-chr${ch}"
    container 'https://depot.galaxyproject.org/singularity/whatshap%3A2.3--py39h1f90b4d_0'

    input:
        tuple val(name), val(ch), path(chr_vcf), path(chr_bam), path(chr_bai), path(ref), path(ref_fai)

    output:
        tuple val(name), val(ch), path('*.vcf'), emit: 'phased_chr_vcf' 

    script:

        """
        INPUT_BAM="${chr_bam}"
        INPUT_VCF="${chr_vcf}"
        OUTPUT_VCF="phased_g100_chr${ch}_${name}.vcf"

        whatshap phase -o \${OUTPUT_VCF} \
            --ignore-read-groups \
            --reference ${ref} \
            \${INPUT_VCF} \
            \${INPUT_BAM}
        """
}
