#!/usr/bin/env nextflow

include { SPLIT_BAM } from '../../modules/split_bam/main'
include { PILEUP_CN as PILEUP_CN_T } from '../../modules/pileup/main'
include { PILEUP_CN as PILEUP_CN_N } from '../../modules/pileup/main'
include { WHATSHAP as WHATSHAP_T } from '../../modules/whatshap/main'
include { WHATSHAP as WHATSHAP_N } from '../../modules/whatshap/main'
include { READ_PHASING } from '../../modules/read_vcf/main_phasing'

workflow PILEUP {
    take:
        split_tumor 
        split_normal
        bed
        ref_genome
    
    main:

        // pileup
        pileup_T = PILEUP_CN_T(split_tumor.combine(bed).combine(ref_genome))
        pileup_N = PILEUP_CN_N(split_normal.combine(bed).combine(ref_genome))

        // phasing
        whatshap_T = WHATSHAP_T(pileup_T.combine(ref_genome)).map {meta, vcf -> 
                [meta.subMap('sampleID', 'chr'), vcf]
        }
        whatshap_N = WHATSHAP_N(pileup_N.combine(ref_genome)).map {meta, vcf -> 
                [meta.subMap('sampleID', 'chr'), vcf]
        }

        // read 
        phasing = READ_PHASING(whatshap_N.join(whatshap_T))

    emit:
        phasing    


}


