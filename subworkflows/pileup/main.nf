#!/usr/bin/env nextflow

include { SPLIT_BAM } from '../../modules/split_bam/main'
include { PILEUP_CN } from '../../modules/pileup/main'
include { WHATSHAP } from '../../modules/whatshap/main'
include { READ_PHASING } from '../../modules/read_vcf/main_phasing'

params.t_name = "COLO829"
params.t_bam_data = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/data/raw/COLO829/COLO829.bam'
params.t_bai_data = "${params.t_bam_data}.bai"

params.n_name = "COLO829"
params.n_bam_data = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/data/raw/COLO829/COLO829.bam'
params.n_bai_data = "${params.n_bam_data}.bai"

params.ref_genome = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna'
params.ref_fai = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai'
params.bed_data="/u/area/ffabris/fast/long_reads_pipeline/test_data/pos"
params.rscript = '/u/area/ffabris/fast/long_reads_pipeline/LR_Pipeline_DNA/bin/read_phasing.R'


t_name_ch = Channel.from(params.t_name)
t_bam_ch = Channel.fromPath(params.t_bam_data, checkIfExists: true) 
t_bai_ch = Channel.fromPath(params.t_bai_data, checkIfExists: true) 

n_name_ch = Channel.from(params.n_name)
n_bam_ch = Channel.fromPath(params.n_bam_data, checkIfExists: true) 
n_bai_ch = Channel.fromPath(params.n_bai_data, checkIfExists: true) 

chr_ch = Channel.from(18..22)//chr_ch = Channel.from(1..22)
bed_ch = Channel.fromPath(params.bed_data, checkIfExists: true) 
ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 
ref_fai_ch = Channel.fromPath(params.ref_fai, checkIfExists: true)

phasing_rscript_ch = Channel.fromPath(params.rscript, checkIfExists: true) 

workflow PILEUP {
    take:
        t_name_ch
        t_bam_ch
        t_bai_ch
        n_name_ch
        n_bam_ch
        n_bai_ch
        chr_ch
        bed_ch
        ref_genome_ch
        ref_fai_ch
        phasing_rscript_ch
    
    main:
    // split bam
        t_input_splitbam_ch = t_name_ch.combine(chr_ch).combine(t_bam_ch).combine(t_bai_ch)
        n_input_splitbam_ch = n_name_ch.combine(chr_ch).combine(n_bam_ch).combine(n_bai_ch)
        input_splitbam_ch = t_input_splitbam_ch.mix(n_input_splitbam_ch)
        splitbam_ch = SPLIT_BAM(input_splitbam_ch)
    
    // pileup
        input_pileupcn_ch = splitbam_ch.chr_bam
                                            .combine(bed_ch)
                                            .combine(ref_genome_ch)
                                            .combine(ref_fai_ch)
        pileupcn_ch = PILEUP_CN(input_pileupcn_ch)
    
    // whatshap 
        input_whatshap_ch = pileupcn_ch.chr_vcf
        whatshap_ch = WHATSHAP(input_whatshap_ch)

    // phasing
        input_phasing_ch = whatshap_ch.phased_chr_vcf
                                                .groupTuple(by:1)
                                                .map { entry -> 
                                                        tuple(entry[0][0], entry[0][1], entry[1], entry[2][0], entry[2][1]+"_c")
                                                    }       
        phasing_ch = READ_PHASING(input_phasing_ch, phasing_rscript_ch)

    emit:
        phasing_ch.chr_rds.flatten()

}

workflow {
    PILEUP(t_name_ch, t_bam_ch, t_bai_ch, n_name_ch, n_bam_ch, n_bai_ch, chr_ch, bed_ch, ref_genome_ch, ref_fai_ch, phasing_rscript_ch)
}

