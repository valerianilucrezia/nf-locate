#!/usr/bin/env nextflow

process READ_SOMATIC {
    tag "${name}"
    publishDir "${workflow.launchDir}/results/read_somatic/", mode: 'copy'
    container 'docker://lvaleriani/long_reads:latest'
    memory '16 GB'

    input:
        tuple val(name), path(vcf_file)
        
    output:
        tuple val(name), path('*.RDS'), emit: 'rds'

    script:
    """
        #!/usr/bin/env bash
        read_vcf_somatic.R "${vcf_file}" "" 
    """
}
