#!/usr/bin/env nextflow

include { SPLIT_BAM } from '../../modules/split_bam/main'
include { PILEUP_CN } from '../../modules/pileup/main'
include { WHATSHAP } from '../../modules/whatshap/main'
include { READ_PHASING } from '../../modules/read_vcf/main_phasing'

params.bam_data = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/data/raw/COLO829'
params.ref_genome = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna'
params.ref_fai = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai'
params.bed_data="/u/area/ffabris/fast/long_reads_pipeline/test_data/pos"

params.readphasing_rscript = '/u/area/ffabris/fast/long_reads_pipeline/LR_Pipeline_DNA/bin/read_phasing.R'


chr_ch = Channel.from(1..22)
bam_ch = Channel.fromPath(params.bam_data, checkIfExists: true) 
bed_ch = Channel.fromPath(params.bed_data, checkIfExists: true) 
ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 
ref_fai_ch = Channel.fromPath(params.ref_fai, checkIfExists: true)
readphasing_rscript_ch   = Channel.fromPath(params.readphasing_rscript, checkIfExists: true) 


workflow PILEUP {
    take:
        chr_ch
        bam_ch
        bed_ch
        ref_genome_ch
        ref_fai_ch
        readphasing_rscript_ch  
        
    
    main:
        input_splitbam_ch = chr_ch.combine(bam_ch)
        split_bam_ch = SPLIT_BAM(input_splitbam_ch)
        bam_chr_ch = split_bam_ch.bam.flatten()
        bai_chr_ch = split_bam_ch.bai.flatten()

        input_pileupcn_ch = chr_ch
                                .combine(bam_chr_ch) //esto habria que cambiarlo para usar la tupla que viene del anterior
                                .combine(bai_chr_ch)
                                .combine(bed_ch)
                                .combine(ref_genome_ch)
                                .combine(ref_fai_ch)
        pileupcn_ch =  PILEUP_CN(input_pileupcn_ch)
        vcf_ch = pileupcn_ch.vcf.flatten()

        input_whatshap_ch = chr_ch //esto habria que cambiarlo para usar la tupla que viene del anterior
                            .combine(bam_chr_ch)
                            .combine(bai_chr_ch) //esto lo aregue pero no se si el proceso lo esta o no esperando
                            .combine(vcf_ch)
                            .combine(ref_genome_ch)
                            .combine(ref_fai_ch)
        whatshap_ch = WHATSHAP(input_whatshap_ch)
        vcf_wwp_ch = whatshap_ch.vcf.flatten()

        input_readphasing_ch = readphasing_rscript_ch
                                    .combine(chr_ch)
                                    .combine(vcf_wwp_ch)
        read_phasing_ch = READ_PHASING(input_readphasing_ch)

    emit:
        read_phasing_ch.RDS.flatten()

}