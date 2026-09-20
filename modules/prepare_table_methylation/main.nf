#!/usr/bin/env nextflow

process PREPARE_TABLE_METHYLATION {
    tag "${meta.sampleID}-${meta.chr}"
    label "process_low"
    label "error_retry"
    container 'docker://lvaleriani/locate:v1.1'

    input:
      tuple val(meta), path(h1_tumor), path(h1_tumor_tbi), path(h2_tumor), path(h2_tumor_tbi), path(h1_normal), path(h1_normal_tbi), path(h2_normal), path(h2_normal_tbi), path(tumor_phased_vcf), path(normal_phased_vcf)

    output:
      tuple val(meta), path('*_methylation_table.csv'), emit: 'table'

    script:
    // Tumor/normal H1/H2 orientation correction: phasing tools label H1/H2
    // arbitrarily per phase block, independently per sample, so the normal's
    // H1 is the tumor's H1 only by chance and this flips at block boundaries.
    // With both phased VCFs, `from-bed` reorients the normal's H1/H2 against the
    // tumor's phasing (at shared het SNPs, per block) and writes an
    // `orientation_resolved` column; TSM/NSM are only defined where it is true.
    // Without them (NO_FILE) the tumor/normal comparison is left uncorrected.
    def reorient = tumor_phased_vcf.name != 'NO_FILE' && normal_phased_vcf.name != 'NO_FILE'
    def vcf_args = reorient ? "--tumor-vcf ${tumor_phased_vcf} --normal-vcf ${normal_phased_vcf}" : ''
    """
    locate prepare-table from-bed \
        --h1-tumor ${h1_tumor} \
        --h2-tumor ${h2_tumor} \
        --h1-normal ${h1_normal} \
        --h2-normal ${h2_normal} \
        ${vcf_args} \
        --output ${meta.sampleID}_${meta.chr}_methylation_table.csv
    """
}
