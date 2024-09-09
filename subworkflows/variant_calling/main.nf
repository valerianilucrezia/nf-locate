#!/usr/bin/env nextflow

include { CLAIRS } from '../../modules/clairS/main.nf' 
include { READ_SOMATIC } from '../../modules/read_vcf/main_somatic.nf'

workflow VARIANT_CALLING {
    take:
        bam
        reference
        
    main:

        clairs = CLAIRS(bam, reference)
        clairs.view()
        vcf = clairs.vcf.flatten().first().combine(clairs.vcf.flatten().filter{ file -> file.toString().contains('.vcf') })
        results = READ_SOMATIC(vcf)

    emit:
        results.rds
        
}


