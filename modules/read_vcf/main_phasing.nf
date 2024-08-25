#!/usr/bin/env nextflow

params.rscript = '/u/area/ffabris/fast/long_reads_pipeline/LR_Pipeline_DNA/bin/read_phasing.R'
params.vcf = "${workflow.launchDir}/results/whatshap"

rscript_ch = Channel.fromPath(params.rscript, checkIfExists: true) 
chr_ch = Channel.from(1..22)
vcf_ch = Channel.fromPath(params.vcf, checkIfExists: true)

input_ch = rscript_ch
    .combine(chr_ch)
    .combine(vcf_ch)

process READ_PHASING {
    publishDir "${workflow.launchDir}/results/read_phasing/", mode: 'copy'
    container 'docker://lvaleriani/long_reads:latest'
    memory '30 GB'

    input:
        tuple path(rscript), val(chr), path(vcf_files)
        

    output:
        path '*.RDS', emit: 'RDS'

    script:
    """
        #!/usr/bin/env bash

        VCF_TUMOR="${vcf_files}/missing_tumor_chr${ch}.vcf"
        VCF_NORMAL="${vcf_files}/missing_normal_chr${ch}.vcf"

        Rscript "${rscript}" "${chr}" "\${VCF_TUMOR}" "\${VCF_NORMAL}"  

    """
}

workflow {
    read_phasing_ch = READ_PHASING(input_ch)
}