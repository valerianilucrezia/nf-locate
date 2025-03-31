#!/usr/bin/env nextflow

process LONGPHASE {
    tag "${meta.sampleID}-${meta.type}-${meta.chr}"
    container 'https://depot.galaxyproject.org/singularity/longphase%3A1.7.3--hf5e1c6e_0'

    input:
      tuple val(meta), path(bam), path(bai), path(vcf), path(mod), path(sv), path(ref_genome), path(ref_fai) 

    output:
      tuple val(meta), path('*snp.vcf'), emit: 'vcf' 
      tuple val(meta), path('*SV.vcf'), emit: 'sv_vcf' 
      tuple val(meta), path('*mod.vcf'), emit: 'mod_vcf' 

    script:

    """
    longphase phase \
        -s ${vcf} \
        --mod-file=${mod} \
        --sv-file ${sv} \
        -b ${bam} \
        -r ${ref_genome} \
        -t 24 \
        -o ${meta.sampleID}_${meta.chr}_snp \
        --ont
    """
}
