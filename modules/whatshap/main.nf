#!/usr/bin/env nextflow

params.ref_genome = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna'
params.ref_fai = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai'
params.bam_data="${workflow.launchDir}/results/split_bam"
params.vcf_data="${workflow.launchDir}/results/pileup_cn"

chr_ch_old = Channel.from(1..22)
chr_ch = Channel.from(1)
bam_ch = Channel.fromPath(params.bam_data, checkIfExists: true) 
vcf_ch = Channel.fromPath(params.vcf_data, checkIfExists: true) 
ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 
ref_fai_ch = Channel.fromPath(params.ref_fai, checkIfExists: true)

input_ch = chr_ch
            .combine(bam_ch)
            .combine(vcf_ch)
            .combine(ref_genome_ch)
            .combine(ref_fai_ch)

process WHATSHAP {
    tag "chr${ch}"
    publishDir "${workflow.launchDir}/results/whatshap/", mode: 'copy'
    container 'https://depot.galaxyproject.org/singularity/whatshap%3A2.3--py39h1f90b4d_0'
    memory '50 GB'
    maxForks 24

    input:
        tuple val(ch), path(sample_bam), path(sample_vcf), path(ref), path (ref_fai)


    output:
        path '*.vcf', emit: 'vcf' 

    script:

        """
        INPUT_BAM="${sample_bam}/chr${ch}-full_chr1_COLO829_L.bam"
        INPUT_VCF="${sample_vcf}/g100_chr${ch}.vcf"

        whatshap phase -o "" \
            --ignore-read-groups \
            --reference ${ref} \
            \${INPUT_VCF} \
            \${INPUT_BAM}
        """
}

workflow {
    whatshap_ch = WHATSHAP(input_ch)
}