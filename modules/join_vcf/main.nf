#!/usr/bin/env nextflow

process JOIN_VCF {
    tag "${meta.sampleID}-${meta.chr}"
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'

    input:
      tuple val(meta), path(vcfs)

    output:
      tuple val(meta), path('*.vcf'), emit: 'vcf' 
      tuple val(meta), path('*.vcf.gz'), path('*.vcf.gz.csi'), emit: 'vcf_gz' 
    
    script:

    """
    bcftools concat ${vcfs} --output ${meta.sampleID}-${meta.chr}.vcf -O v --threads 12
    bcftools sort ${meta.sampleID}-${meta.chr}.vcf -O z -o ${meta.sampleID}-${meta.chr}.vcf.gz
    bcftools index ${meta.sampleID}-${meta.chr}.vcf.gz
    """
}
