#!/usr/bin/env nextflow

params.input_vcf='/u/area/ffabris/fast/long_reads_pipeline/results/clairS/variants.vcf'
params.outdir = '/u/area/ffabris/fast/long_reads_pipeline/results/read_somatic/'

input_vcf_ch = Channel.fromPath(params.input_vcf, checkIfExists: true) 

process READ_SOMATIC {
    publishDir params.outdir, mode: 'copy'
    container 'docker://lvaleriani/long_reads:latest'

    input:
        path input_vcf

    output:
        path 'vaf.RDS'

    script:
    """
        #!/usr/bin/env bash
        Rscript process_vcf.R "${input_vcf}" "${params.outdir}"
    """
}

workflow {
    read_somatic_ch = READ_SOMATIC(input_vcf_ch)
}