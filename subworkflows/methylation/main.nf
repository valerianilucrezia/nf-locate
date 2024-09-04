#!/usr/bin/env nextflow

include { MODKIT } from '../../modules/modkit/main'
include { GET_POSITIONS } from '../../modules/get_positions/main'
include { METH_PILEUP } from '../../modules/pileup_methylation/main'
include { READ_BED } from '../../modules/read_bed/main'
include { COMBINE } from '../../modules/combine_methylation/main'


workflow METYLATION {
    take:
        t_ch 
        n_ch
        chr_ch
        ref_genome_ch
        ref_fai_ch
        chr_bam_ch
       
    main:

        //modkit
        t_input_modkit_ch = t_ch.combine(t_ch).combine(ref_genome_ch).combine(ref_fai_ch)
        n_input_modkit_ch = n_ch.combine(n_ch).combine(ref_genome_ch).combine(ref_fai_ch)
        input_modkit_ch = t_input_modkit_ch.mix(n_input_modkit_ch)
        modkit_ch = MODKIT(input_modkit_ch)
        
        //get positions
        input_getpositions_ch = chr_ch.combine(modkit_ch.bed_summary)
        get_positions_ch = GET_POSITIONS(input_getpositions_ch)

        //pileup meth
        channel name bed
        input_pilupmet_ch = get_positions_ch.chr_bed.combine(chr_bam_ch, by:[0,1])
                                                .combine(ref_genome_ch)
                                                .combine(ref_fai_ch) 
        pileupmet_ch = METH_PILEUP(input_pilupmet_ch)
        
        //read bed
        input_readbed_ch = chr_ch.combine(modkit_ch.bed_summary)    
        readbed_ch = READ_BED(input_readbed_ch)

        //combine
        readbed_rds_ch = readbed_ch.chr_rds
        chr_vcf_ch = pileupmet_ch.chr_vcf
        input_combine_ch = readbed_rds_ch.combine(chr_vcf_ch,by:[0,1]).branch {
                                                                    tumor: it[0] == t_ch.first()
                                                                    normal: it[0] == n_ch.first() }
        combine_ch = COMBINE(input_combine_ch.tumor.combine(input_combine_ch.normal,by=0))

    emit:
        combine_ch.chr_rds
}
