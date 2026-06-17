#!/usr/bin/env nextflow

include { PREPARE_TABLE_VCF } from '../../modules/prepare_table_vcf/'
include { PREPARE_TABLE_METHYLATION } from '../../modules/prepare_table_methylation/'
include { SEGMENTATION } from '../../modules/segmentation/'
include { CN_INFERENCE } from '../../modules/cn_inference/'
include { METHYLATION_INFERENCE } from '../../modules/methylation_inference/'
include { ASM } from '../../modules/asm/'


workflow LOCATE_CN {
    take:
        battenberg_vcf  // tuple(meta, vcf, tbi) keyed by sampleID, chr -- BAF_H1/BAF_H2/DR annotated tumor VCF

    main:
        no_file = file("${projectDir}/assets/NO_FILE")

        table = PREPARE_TABLE_VCF(battenberg_vcf).table

        if (params.run_segmentation.toString() == 'true') {
            breakpoints = SEGMENTATION(table).segments
            cn_input = table.join(breakpoints)
        } else {
            cn_input = table.map { meta, t -> [meta, t, no_file] }
        }

        CN_INFERENCE(cn_input)

    emit:
        cn = CN_INFERENCE.out.cn
}


workflow LOCATE_METHYLATION {
    take:
        meth_h1_tumor   // tuple(meta, bed.gz, tbi) keyed by sampleID, chr, type -- modkit H1 bedMethyl
        meth_h2_tumor   // tuple(meta, bed.gz, tbi) keyed by sampleID, chr, type -- modkit H2 bedMethyl
        meth_h1_normal  // tuple(meta, bed.gz, tbi) keyed by sampleID, chr, type -- modkit H1 bedMethyl
        meth_h2_normal  // tuple(meta, bed.gz, tbi) keyed by sampleID, chr, type -- modkit H2 bedMethyl

    main:
        key = ['sampleID', 'chr']

        meth_table_input = meth_h1_tumor.map { meta, bed, tbi ->
            [meta.subMap(key), bed, tbi]
        }.join(meth_h2_tumor.map { meta, bed, tbi ->
            [meta.subMap(key), bed, tbi]
        }).join(meth_h1_normal.map { meta, bed, tbi ->
            [meta.subMap(key), bed, tbi]
        }).join(meth_h2_normal.map { meta, bed, tbi ->
            [meta.subMap(key), bed, tbi]
        })

        methylation_table = PREPARE_TABLE_METHYLATION(meth_table_input).table

        METHYLATION_INFERENCE(methylation_table)
        ASM(methylation_table)

    emit:
        betat = METHYLATION_INFERENCE.out.betat
        asm   = ASM.out.asm
}
