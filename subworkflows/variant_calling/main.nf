#!/usr/bin/env nextflow
params.outdir = "${workflow.launchDir}/results/"

params.tumor_bam = '/u/area/ffabris/fast/long_reads_pipeline/test_data/full_chr1_COLO829.bam'
params.tumor_bai = '/u/area/ffabris/fast/long_reads_pipeline/test_data/full_chr1_COLO829.bam.bai'
params.normal_bam = '/u/area/ffabris/fast/long_reads_pipeline/test_data/full_chr1_COLO829_L.bam'
params.normal_bai = '/u/area/ffabris/fast/long_reads_pipeline/test_data/full_chr1_COLO829_L.bam.bai'
params.ref_genome = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna'
params.ref_fai = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai'
params.rscript = '/u/area/ffabris/fast/long_reads_pipeline/LR_Pipeline_DNA/bin/read_vcf_somatic.R'

include { CLAIRS } from '../../modules/clairS/main.nf' 
include { READ_SOMATIC } from '../../modules/read_vcf/main_somatic.nf'

tumor_bam_ch = Channel.fromPath(params.tumor_bam, checkIfExists: true) 
tumor_bai_ch = Channel.fromPath(params.tumor_bai, checkIfExists: true) 
normal_bam_ch = Channel.fromPath(params.normal_bam, checkIfExists: true) 
normal_bai_ch = Channel.fromPath(params.normal_bai, checkIfExists: true) 
ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 
ref_fai_ch = Channel.fromPath(params.ref_fai, checkIfExists: true)
rscript_ch = Channel.fromPath(params.rscript, checkIfExists: true) 


workflow VARIANT_CALLING {
    take:
        tumor_bam
        tumor_bai
        normal_bam
        normal_bai
        ref_genome
        ref_fai
        rscript

    main:
        clairs_ch = CLAIRS(tumor_bam, tumor_bai, normal_bam, normal_bai, ref_genome, ref_fai)
        vcf_ch = clairs_ch.vcf.flatten()
        combined_ch = rscript_ch.combine(vcf_ch)


        combined_ch.view()
        read_somatic_ch = READ_SOMATIC(combined_ch)

    emit:
        clairs_ch.vcf
        clairs_ch.tbi
        read_somatic_ch.RDS
        
}

workflow {
    VARIANT_CALLING(tumor_bam_ch, tumor_bai_ch, normal_bam_ch, normal_bai_ch, ref_genome_ch, ref_fai_ch, rscript_ch)
}

