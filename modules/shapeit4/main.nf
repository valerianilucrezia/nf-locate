#!/usr/bin/env nextflow

process SHAPEIT4 {
    tag "${meta.sampleID}-chr${meta.chr}"
    container 'https://depot.galaxyproject.org/singularity/shapeit4%3A4.1.3--h3ac2748_0'

    input:
      tuple val(meta), path(vcf), path(index)

    output:
      tuple val(meta), path('*.vcf'), emit: 'vcf' 

    script:

    """
    shapeit4 --input ${vcf} \
        --map "${params.map}/chr${meta.chr}.b38.gmap_CHR" \
        --region chr${meta.chr} \
        --output "shapeit_${meta.sampleID}-chr${meta.chr}.vcf" \
        --reference "${params.bcf}/ALL.chr${meta.chr}.phase3_shapeit2_mvncall_integrated_v5.20130502.genotypes_chr_38.vcf.gz" \
        --use-PS 0.0001 \
        --thread 24
    """
}