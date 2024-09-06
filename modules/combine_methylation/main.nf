#!/usr/bin/env nextflow

process COMBINE {
    tag "chr${chr}-${t_name}-${n_name}"
    publishDir "${workflow.launchDir}/results/combine_meth", mode: 'copy'
    container 'docker://lvaleriani/long_reads:latest'
    memory '50 GB'

    input:
      tuple  val(chr), val(t_name), path(t_rds_files), path(t_vcf_files), val(n_name), path(n_rds_files), path(n_vcf_files)

    output:
      tuple val(chr),path ("*.RDS"), emit: 'chr_rds'

    script:
      """
      combine.R ${chr} ${rds_files} ${rds_files} ${vcf_files} ${vcf_files}
      """
}


