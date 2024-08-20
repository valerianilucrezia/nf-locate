#!/usr/bin/env nextflow

params.outdir = '/u/area/ffabris/fast/long_reads_pipeline/results/read_somatic/'
params.rscript = '/u/area/ffabris/fast/long_reads_pipeline/LR_Pipeline_DNA/bin/read_vcf_somatic.R'
params.vcf_file = '/u/area/ffabris/fast/long_reads_pipeline/results/clairS/'

rscript_ch = Channel.fromPath(params.rscript, checkIfExists: true) 
vcf_file_ch = Channel.fromPath(params.vcf_file, checkIfExists: true) 

process READ_SOMATIC {
    publishDir params.outdir, mode: 'copy'
    container 'docker://lvaleriani/long_reads:latest'
    memory '16 GB'

    input:
        path rscript
        path vcf_file

    output:
        path 'read_somatic.log'

    script:
    """
        #!/usr/bin/env bash
        which Rscript > read_somatic.log
        Rscript "${rscript}" "${params.vcf_file}" "${params.outdir}" >> read_somatic.log
    """
}

workflow {
    read_somatic_ch = READ_SOMATIC(rscript_ch,vcf_file_ch)
}