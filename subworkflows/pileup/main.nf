#!/usr/bin/env nextflow

include { SPLIT_BAM } from '../../modules/split_bam/main'
include { PILEUP_CN } from '../../modules/pileup/main'
include { WHATSHAP } from '../../modules/whatshap/main'
include { READ_PHASING } from '../../modules/read_vcf/main_phasing'

workflow PILEUP {
    take:
        tumor 
        normal
        chromosome
        bed
        ref_genome
    
    main:
    // split bam
        t_input_splitbam_ch = chr_ch.combine(tumor) 
        n_input_splitbam_ch = chr_ch.combine(normal) 
        input_splitbam_ch = t_input_splitbam_ch.mix(n_input_splitbam_ch)
        splitbam_ch = SPLIT_BAM(input_splitbam_ch)
    
    // pileup
        input_pileupcn_ch = splitbam_ch.chr_bam
                                            .combine(bed)
                                            .combine(ref_genome)
        pileupcn_ch = PILEUP_CN(input_pileupcn_ch)
    
        input_whatshap_ch = pileupcn_ch.chr_vcf
                                            .combine(splitbam_ch.chr_bam,by:[0,1])
                                            .combine(ref_genome)
        whatshap_ch = WHATSHAP(input_whatshap_ch)

    // phasing
        input_phasing_ch = whatshap_ch.phased_chr_vcf
                                                .groupTuple(by:1)
                                                .map { entry -> 
                                                        tuple(entry[0][0], entry[0][1], entry[1], entry[2][0], entry[2][1]+"_c")
                                                    }       
        phasing_ch = READ_PHASING(input_phasing_ch)

    emit:
        splitbam_ch.chr_bam

}


