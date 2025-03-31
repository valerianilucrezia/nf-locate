#!/usr/bin/env nextflow

include { WHATSHAP } from '../../modules/whatshap/main'
include { LONGPHASE } from '../../subworkflows/longphase/main'
include { SHAPEIT4 } from '../../modules/shapeit4/main'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_1 } from '../../modules/bcftools_index/main'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_2 } from '../../modules/bcftools_index/main'

workflow PHASING {
    take:
        pileup
        split_bam 
        ref_genome
        bam
    
    main:
        if (params.phasing == 'whatshap'){
            phasing = WHATSHAP(pileup.combine(ref_genome)).map {meta, vcf -> 
                    [meta.subMap('sampleID', 'chr'), vcf]
            }
        } else if (params.phasing == 'longphase'){
            LONGPHASE(split_bam, pileup, ref_genome, bam)
            phasing = LONGPHASE.out.vcf
        }

        phasing_gz = BCFTOOLS_INDEX_1(phasing)
        //ref_phasing = SHAPEIT4(phasing_gz)
        //ref_phasing_gz = BCFTOOLS_INDEX_2(ref_phasing)

    emit:
        phasing_gz
}


