#!/usr/bin/env nextflow

include { MODKIT } from '../../modules/modkit/main'
include { GET_POSITIONS } from '../../modules/get_positions/main'
include { METH_PILEUP as METH_PILEUP_T } from '../../modules/pileup_methylation/main'
include { METH_PILEUP as METH_PILEUP_N } from '../../modules/pileup_methylation/main'

include { READ_BED } from '../../modules/read_bed/main'
include { COMBINE } from '../../modules/combine_methylation/main'


workflow METYLATION {
    take:
        split_tumor 
        split_normal
        ref_genome
       
    main:

        //modkit
        tumor = split_tumor.combine(ref_genome)
        modkit_T = MODKIT(tumor)
        
        //get positions
        get_positions = GET_POSITIONS(modkit_T.bed_summary)

        //pileup meth
        in_T = split_tumor.join(get_positions).combine(ref_genome)
        in_N = split_normal.map{ meta, bam, bai ->
                    [meta.subMap('sampleID', 'chr'), bam, bai]
                }.join(get_positions.map { meta, bed -> 
                    [meta.subMap('sampleID', 'chr'), bed]
                }).map{ meta, bam, bai, bed -> 
                    meta = meta + [type:'Normal']
                    [meta, bam, bai, bed]
                }.combine(ref_genome)

        METH_PILEUP_T(in_T)
        METH_PILEUP_N(in_N)
        
        //read bed 
        READ_BED(modkit_T.bed_summary)

        //combine
        combine = METH_PILEUP_T.out.vcf.map { meta, vcf ->
                [meta.subMap('sampleID', 'chr'), vcf]
            }.join(METH_PILEUP_N.out.vcf.map { meta, vcf ->
                [meta.subMap('sampleID', 'chr'), vcf]
            }).join(READ_BED.out.rds.map {meta, bed ->
                [meta.subMap('sampleID', 'chr'), bed]
            })
        COMBINE(combine)

    emit:
        COMBINE.out.rds
}
