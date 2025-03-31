#!/usr/bin/env nextflow

include { PILEUP_CN } from '../../modules/pileup/main'
include { JOIN_VCF } from '../../modules/join_vcf/main'


workflow PILEUP {
    take:
        split_bam 
        bed
        ref_genome
    
    main:
        // pileup
        input = split_bam.map{ meta, bam, bai ->
            def info = [sampleID:meta.sampleID, type:meta.type]
            [meta.subMap('chr'), info, bam, bai]}.combine(bed, by: 0).map{ meta, info, bam, bai, b ->
            meta = meta + [sampleID:info.sampleID, type:info.type]
            [meta, bam, bai, b]
            }.combine(ref_genome)

        pileup = PILEUP_CN(input)
        JOIN_VCF(pileup.groupTuple(by: 0))

    emit:
        JOIN_VCF.out.vcf
}


