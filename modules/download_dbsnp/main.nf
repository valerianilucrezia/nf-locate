#!/usr/bin/env nextflow

process DOWNLOAD_DBSNP {
    label "process_medium"
    label "error_retry"
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'

    output:
      tuple path("dbsnp_common_snp.vcf.gz"), path("dbsnp_common_snp.vcf.gz.tbi"), emit: 'vcf'

    script:
    """
    wget -O 00-common_all.vcf.gz "https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/00-common_all.vcf.gz"
    bcftools view --threads ${task.cpus} -i 'TYPE="SNP"' -Oz -o dbsnp_common_snp.vcf.gz 00-common_all.vcf.gz
    bcftools index -t dbsnp_common_snp.vcf.gz
    rm 00-common_all.vcf.gz
    """
}

process SPLIT_DBSNP_BY_CHR {
    tag "${chr}"
    label "process_low"
    label "error_retry"
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'

    input:
      tuple val(chr), path(vcf), path(tbi)

    output:
      tuple val(chr), path("${chr}.vcf.gz"), emit: 'vcf'

    script:
    // dbSNP contigs are named "1".."22" (no "chr" prefix); rename to chrN for downstream use
    """
    bcftools view --threads ${task.cpus} -r ${chr.replace('chr','')} ${vcf} \
        | sed 's/^\\([0-9XYM]\\+\\)\t/chr\\1\t/' \
        | bcftools view --threads ${task.cpus} -Oz -o ${chr}.vcf.gz
    """
}
