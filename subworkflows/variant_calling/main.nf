#!/usr/bin/env nextflow

include { CLAIRS } from '../../modules/clairS/main.nf' 
include { READ_SOMATIC } from '../../modules/read_vcf/main_somatic.nf'

workflow VARIANT_CALLING {
    take:
        bam
        ref_genome
        
    main:

        clairs = CLAIRS(bam, ref_genome)
        results = READ_SOMATIC(clairs.somatic)
        

    emit:
        results
        
}


