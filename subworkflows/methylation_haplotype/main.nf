#!/usr/bin/env nextflow

include { HAPLOTAG_BAM } from '../../modules/haplotag/'
include { SPLIT_HAPLOTYPE } from '../../modules/split_haplotype/'
include { SAMTOOLS_INDEX as  SAMTOOLS_INDEX_H1} from '../../modules/samtools_index/'
include { SAMTOOLS_INDEX as  SAMTOOLS_INDEX_H2} from '../../modules/samtools_index/'
include { MODKIT as MODKIT_H1} from '../../modules/modkit/'
include { MODKIT as MODKIT_H2} from '../../modules/modkit/'
include { BCFTOOLS_BGZIP as BCFTOOLS_BGZIP_H1} from '../../modules/bcftools_bgzip/'
include { BCFTOOLS_BGZIP as BCFTOOLS_BGZIP_H2} from '../../modules/bcftools_bgzip/'
include { DMR } from '../../modules/dmr/'


workflow METYLATION_HAPLOTYPE {
    take:
        haplotag_bam
        ref_genome
    
    main:
        SPLIT_HAPLOTYPE(haplotag_bam)

        h1 = SPLIT_HAPLOTYPE.out.h1_bam.map {meta, bam ->
            meta = meta + [hp:'H1']
            [meta, bam]
        }
        h2 = SPLIT_HAPLOTYPE.out.h2_bam.map {meta, bam ->
            meta = meta + [hp:'H2']
            [meta, bam]
        }

        index_h1 = SAMTOOLS_INDEX_H1(h1)
        index_h2 = SAMTOOLS_INDEX_H2(h2)

        MODKIT_H1(index_h1.combine(ref_genome))
        MODKIT_H2(index_h2.combine(ref_genome))

        meth_h1 = BCFTOOLS_BGZIP_H1(MODKIT_H1.out.bed).bed.map{meta, bed, idx -> 
            [meta.subMap('sampleID', 'chr'), bed, idx]}
        meth_h2 = BCFTOOLS_BGZIP_H2(MODKIT_H2.out.bed).bed.map{meta, bed, idx -> 
            [meta.subMap('sampleID', 'chr'), bed, idx]}

        DMR(meth_h1.join(meth_h2).combine(ref_genome))


    emit:
        dmr = DMR.out.dmr    
        seg = DMR.out.seg

}
