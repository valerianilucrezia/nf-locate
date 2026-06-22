#!/usr/bin/env nextflow

process BCFTOOLS_CONCAT {
    tag "${meta.sampleID}"
    label "process_low"
    label "error_retry"
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'

    input:
      // vcfs/tbis arrive as one list per sample; the caller (main.nf) sorts
      // them into genome order by chromosome before passing them in here,
      // since --naive concatenation below trusts input order as-is.
      tuple val(meta), path(vcfs), path(tbis)

    output:
      tuple val(meta), path('*.vcf.gz'), path('*.vcf.gz.tbi'), emit: 'vcf'

    script:
    """
    bcftools concat --naive -O z -o ${meta.sampleID}_battenberg.vcf.gz ${vcfs}
    tabix -p vcf ${meta.sampleID}_battenberg.vcf.gz
    """
}
