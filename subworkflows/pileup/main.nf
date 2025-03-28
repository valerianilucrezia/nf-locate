#!/usr/bin/env nextflow

include { PILEUP_CN } from '../../modules/pileup/main'
include { WHATSHAP } from '../../modules/whatshap/main'
include { LONGPHASE } from '../../subworkflows/longphase/main'
include { SHAPEIT4 } from '../../modules/shapeit4/main'
include {BCFTOOLS_INDEX } from '../../modules/bcftools_index/main'

workflow PILEUP {
    take:
        split_bam 
        bed
        ref_genome
        bam
    
    main:
        // pileup
        pileup = PILEUP_CN(split_bam.combine(bed).combine(ref_genome))

        if (params.phasing == 'whatshap'){
            phasing = WHATSHAP(pileup.combine(ref_genome)).map {meta, vcf -> 
                    [meta.subMap('sampleID', 'chr'), vcf]
            }
        } else if (params.phasing == 'longphase'){
            LONGPHASE(split_bam, pileup, ref_genome, bam)
            phasing = LONGPHASE.out.vcf
        }

        phasing_gz = BCFTOOLS_INDEX(phasing)
        //ref_phasing = SHAPEIT4(phasing_gz)

    emit:
        //ref_phasing
        phasing_gz
}


