#!/usr/bin/env nextflow ooo

process READ_SOMATIC {
    publishDir "${workflow.launchDir}/results/read_somatic/", mode: 'copy'
    container 'docker://lvaleriani/long_reads:latest'
    memory '16 GB'

    input:
        tuple path(rscript), path(vcf_file)
        

    output:
        path '*.RDS', emit: 'RDS'

    script:
    """
        #!/usr/bin/env bash
        Rscript "${rscript}" "${vcf_file}" "" 
    """
}
