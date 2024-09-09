#!/usr/bin/env nextflow

process READ_PHASING {
    tag "chr${chr}"
    container 'docker://lvaleriani/long_reads:latest'


    input:
        tuple val(t_name), val(n_name), val(chr), path(t_chr_phased_vcf), path(n_chr_phased_vcf)

    output:
        path '*.RDS', emit: 'chr_rds'

    script:
    """
        #!/usr/bin/env bash

        VCF_TUMOR="${t_chr_phased_vcf}"
        VCF_NORMAL="${n_chr_phased_vcf}"

        read_phasing.R "${chr}" "\${VCF_TUMOR}" "\${VCF_NORMAL}"  

    """
}
