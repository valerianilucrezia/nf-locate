#!/usr/bin/env nextflow

include { CLAIRS } from '../../modules/clairS/main.nf' 
include { READ_SOMATIC } from '../../modules/read_vcf/main_somatic.nf'

workflow VARIANT_CALLING {
    take:
        sample_ch
        
    main:
        clairs_ch = CLAIRS(sample_ch)
        vcf_ch = clairs_ch.vcf.flatten().first()
                                        .combine(clairs_ch.vcf.flatten().filter{ file -> file.toString().contains('.vcf') })
        read_somatic_ch = READ_SOMATIC(vcf_ch)

    emit:
        read_somatic_ch.rds
        
}


