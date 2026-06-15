#!/usr/bin/env nextflow

process DOWNLOAD_1000G {
    tag "${chr}"
    label "process_low"
    label "error_retry"
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'

    input:
      val(chr)

    output:
      tuple val(chr), path("ALL.${chr}.phase3_shapeit2_mvncall_integrated_v5.20130502.genotypes_chr_38.vcf.gz"), path("ALL.${chr}.phase3_shapeit2_mvncall_integrated_v5.20130502.genotypes_chr_38.vcf.gz.csi"), emit: 'panel'

    script:
    """
    wget -O panel.vcf.gz "http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.${chr}.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz"
    bcftools view --threads ${task.cpus} panel.vcf.gz \
        | sed 's/^\\([0-9XYM]\\+\\)\t/chr\\1\t/' \
        | bcftools view --threads ${task.cpus} -Oz -o ALL.${chr}.phase3_shapeit2_mvncall_integrated_v5.20130502.genotypes_chr_38.vcf.gz
    bcftools index ALL.${chr}.phase3_shapeit2_mvncall_integrated_v5.20130502.genotypes_chr_38.vcf.gz
    rm panel.vcf.gz
    """
}
