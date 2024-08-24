#!/usr/bin/env nextflow

params.rscript = '/u/area/ffabris/fast/long_reads_pipeline/LR_Pipeline_DNA/bin/combine.R'
params.rds = "${workflow.launchDir}/results/read_bed"
params.vcf = "${workflow.launchDir}/results/pileup_meth"

rscript_ch = Channel.fromPath(params.rscript, checkIfExists: true) 
chr_ch = Channel.from(1..22)
rds_ch = Channel.fromPath(params.rds, checkIfExists: true)
vcf_ch = Channel.fromPath(params.vcf, checkIfExists: true)

input_ch = rscript_ch
    .combine(chr_ch)
    .combine(rds_ch)
    .combine(vcf_ch)


process COMBINE {
    tag "chr${chr}"
    publishDir "${workflow.workDir}/results/combine_meth", mode: 'copy'
    container 'docker://your_docker_image:latest' 
    memory '50 GB'

    input:
      tuple path(rscript), val(chr), path(rds_files), path(vcf_files)

    output:
      path "*.RDS", emit: 'RDS'

    script:
      """
      RDS_TUMOR="${rds_files}/COLO829_L_chr${ch}.RDS"
      RDS_NORMAL="${rds_files}/COLO829_chr${ch}.RDS"

      VCF_TUMOR="${vcf_files}/missing_tumor_chr${ch}.vcf"
      VCF_NORMAL="${vcf_files}/missing_normal_chr${ch}.vcf"

      Rscript ${rscript} ${chr} \${meth_tumor_rds} \${meth_normal_rds} \${vcf_tumor} \${vcf_normal}
      """
}

workflow {
    combine_ch = COMBINE(input_ch)
}


