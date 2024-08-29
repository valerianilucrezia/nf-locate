#!/usr/bin/env nextflow

process READ_PHASING {
    tag "chr${chr}"
    publishDir "${workflow.launchDir}/results/read_phasing/", mode: 'copy'
    container 'docker://lvaleriani/long_reads:latest'
    memory '30 GB'

    input:
        tuple val(t_name), val(n_name), val(chr), path(t_chr_phased_vcf), path(n_chr_phased_vcf)
        path(rscript)

    output:
        path '*.RDS', emit: 'chr_rds'

    script:
    """
        #!/usr/bin/env bash

        VCF_TUMOR="${t_chr_phased_vcf}"
        VCF_NORMAL="${n_chr_phased_vcf}"

        Rscript "${rscript}" "${chr}" "\${VCF_TUMOR}" "\${VCF_NORMAL}"  

    """
}
