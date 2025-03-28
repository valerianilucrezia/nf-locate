#!/usr/bin/env nextflow

include { SNIFFLE } from '../../modules/sniffle/'
include { MODCALL } from '../../modules/modcall/'
include { LONGPHASE as LONGPHASE_PHASE } from '../../modules/longphase/'

workflow LONGPHASE {
    take:
        split_bam
        vcf 
        ref_genome
        bam
    
    main:
        sv = SNIFFLE(bam.combine(ref_genome)).map {meta, res -> 
        [res]}
        pileup = vcf.map {meta, bam, bai, file ->
        [meta, file]}
        modcall = MODCALL(split_bam.combine(ref_genome))
        LONGPHASE_PHASE(split_bam.join(modcall).join(pileup).combine(sv).combine(ref_genome))

    emit:
        vcf = LONGPHASE_PHASE.out.vcf
        sv = LONGPHASE_PHASE.out.sv_vcf
        mod = LONGPHASE_PHASE.out.mod_vcf

}