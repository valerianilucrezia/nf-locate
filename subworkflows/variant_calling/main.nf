#!/usr/bin/env nextflow

include { CLAIRS } from '../../modules/clairS/main.nf' 
include { READ_SOMATIC } from '../../modules/read_vcf/main_somatic.nf'

workflow VARIANT_CALLING {
    take:
        bam
        reference
        
    main:

        clairs = CLAIRS(bam, reference)
        results = READ_SOMATIC(clairs.somatic)
        

    emit:
        results.rds
        
}


