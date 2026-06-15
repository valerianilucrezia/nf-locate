#!/usr/bin/env nextflow

process BATTENBERG_PHASE {
    tag "${meta.sampleID}-${meta.chr}"
    label "process_medium"
    //label "error_retry"
    // TODO: build and push the image from modules/battenberg_phase/Dockerfile,
    // then replace this placeholder with the resulting registry path.
    container 'docker://lvaleriani/battenberg-phase:1.0.1'

    input:
      tuple val(meta), path(tumor_vcf), path(shapeit_vcf), path(shapeit_csi), path(normal_vcf)

    output:
      tuple val(meta), path('*.vcf.gz'), path('*.vcf.gz.tbi'), emit: 'vcf'

    script:
    """
    Rscript ${moduleDir}/bin/battenberg_phase.R \
        --tumor ${tumor_vcf} \
        --shapeit ${shapeit_vcf} \
        --normal ${normal_vcf} \
        --output ${meta.sampleID}_${meta.chr}_battenberg.vcf.gz \
        --sample ${meta.sampleID} \
        --chr ${meta.chr}

    # vcfR::write.vcf produces gzip (not BGZF); re-compress for tabix
    mv ${meta.sampleID}_${meta.chr}_battenberg.vcf.gz ${meta.sampleID}_${meta.chr}_battenberg.vcf.gz.tmp
    zcat ${meta.sampleID}_${meta.chr}_battenberg.vcf.gz.tmp | bgzip -c > ${meta.sampleID}_${meta.chr}_battenberg.vcf.gz
    rm ${meta.sampleID}_${meta.chr}_battenberg.vcf.gz.tmp

    tabix -p vcf ${meta.sampleID}_${meta.chr}_battenberg.vcf.gz
    """
}
