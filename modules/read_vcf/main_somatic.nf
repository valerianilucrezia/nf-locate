#!/usr/bin/env nextflow

params.rscript = '/u/area/ffabris/fast/long_reads_pipeline/LR_Pipeline_DNA/bin/read_vcf_somatic.R'
params.outdir = "${workflow.launchDir}/results/"
params.vcf_file = "${workflow.launchDir}/results/clairS/variants.vcf.gz"

rscript_ch = Channel.fromPath(params.rscript, checkIfExists: true) 
vcf_file_ch = Channel.fromPath(params.vcf_file, checkIfExists: true) 

process READ_SOMATIC {
    publishDir "${params.outdir}read_somatic/", mode: 'copy'
    container 'docker://lvaleriani/long_reads:latest'
    memory '16 GB'

    input:
        path rscript
        path vcf_file

    output:
        path '*.RDS', emit: 'RDS_file'

    script:
    """
        #!/usr/bin/env bash
        Rscript "${rscript}" "${vcf_file}" "" 
    """
}

workflow {
    read_somatic_ch = READ_SOMATIC(rscript_ch,vcf_file_ch)
}