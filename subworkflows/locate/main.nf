#!/usr/bin/env nextflow

include { PREPARE_TABLE_VCF } from '../../modules/prepare_table_vcf/'
include { PREPARE_TABLE_METHYLATION } from '../../modules/prepare_table_methylation/'
include { PREPARE_TABLE_SOMATIC_VCF } from '../../modules/prepare_table_somatic_vcf/'
include { ALIGN_VAF as ALIGN_VAF_CHROM } from '../../modules/align_vaf/'
include { ALIGN_VAF as ALIGN_VAF_GENOME } from '../../modules/align_vaf/'
include { SPLIT_TABLE_BY_CHROM } from '../../modules/split_table_by_chrom/'
include { SEGMENTATION } from '../../modules/segmentation/'
include { MERGE_BREAKPOINTS } from '../../modules/merge_breakpoints/'
include { CN_INFERENCE } from '../../modules/cn_inference/'
include { CN_EXPAND_SEGMENTS } from '../../modules/cn_expand_segments/'
include { METHYLATION_INFERENCE } from '../../modules/methylation_inference/'
include { ASM } from '../../modules/asm/'


workflow LOCATE_CN {
    take:
        battenberg_vcf  // tuple(meta, vcf, tbi) keyed by sampleID -- whole-genome (all chromosomes
                        // concatenated) BAF_H1/BAF_H2/DP_T/DP_N annotated tumor VCF
        somatic_vcf     // tuple(meta, vcf) keyed by sampleID -- whole-genome somatic SNV VCF (e.g.
                        // ClairS), or an empty channel if run_somatic_calling=false. VAF is skipped
                        // (table/segmentation run without it) whenever this channel has no entries.
        centromere_bed  // path to a centromere BED (chrom, start, end) for this genome build, or
                        // the NO_FILE placeholder if not provided -- segments overlapping a
                        // centromere are split around it instead of spanning across the gap.
        low_mappability_bed  // path to a low-mappability BED (e.g. ENCODE) for this genome build,
                        // or the NO_FILE placeholder if not provided -- SNPs overlapping one of
                        // these regions are excluded from the table before any inference runs.

    main:
        no_file = file("${projectDir}/assets/NO_FILE")

        table = PREPARE_TABLE_VCF(battenberg_vcf.combine(Channel.fromPath(low_mappability_bed))).table

        // VAF is optional: only attempt alignment for samples that actually
        // have a somatic VCF (run_somatic_calling=true). Samples without one
        // fall through with their table/segmentation input unchanged (no
        // vaf column) rather than being silently dropped by a join against
        // an empty channel.
        somatic_table = PREPARE_TABLE_SOMATIC_VCF(somatic_vcf).table

        table_by_sample = table.map { meta, t -> [meta.subMap('sampleID'), meta, t] }
        somatic_by_sample = somatic_table.map { meta, t -> [meta.subMap('sampleID'), t] }

        table_have_vaf = table_by_sample.combine(somatic_by_sample, by: 0)
            .map { key, meta, t, st -> [meta, t, st] }
        table_no_vaf = table_by_sample.join(somatic_by_sample, by: 0, remainder: true)
            .filter { key, meta, t, st -> st == null }
            .map { key, meta, t, st -> [meta, t] }

        table_with_vaf = ALIGN_VAF_GENOME(table_have_vaf).table.mix(table_no_vaf)

        if (params.run_segmentation.toString() == 'true') {
            // Fan out the whole-genome table into one file per chromosome
            // (MultivariateClaSP has no chromosome concept -- see
            // SPLIT_TABLE_BY_CHROM's docstring), then VAF-align (where
            // available) and segment each chromosome independently and in
            // parallel.
            split = SPLIT_TABLE_BY_CHROM(table).chrom_tables

            chrom_tables = split.flatMap { meta, chrom_files, offsets ->
                chrom_files.collect { f ->
                    def chrom = f.name.replaceAll(/_table\.csv$/, '')
                    [meta + [chr: chrom], f]
                }
            }

            chrom_by_sample = chrom_tables.map { meta, f -> [meta.subMap('sampleID'), meta, f] }
            chrom_have_vaf = chrom_by_sample.combine(somatic_by_sample, by: 0)
                .map { key, meta, f, st -> [meta, f, st] }
            chrom_no_vaf = chrom_by_sample.join(somatic_by_sample, by: 0, remainder: true)
                .filter { key, meta, f, st -> st == null }
                .map { key, meta, f, st -> [meta, f] }

            chrom_tables_with_vaf = ALIGN_VAF_CHROM(chrom_have_vaf).table.mix(chrom_no_vaf)

            segments = SEGMENTATION(chrom_tables_with_vaf).segments

            // Group each sample's per-chromosome segment CSVs back together
            // for MERGE_BREAKPOINTS, alongside the offsets.csv and
            // per-chromosome (non-VAF) tables split() already produced --
            // merge_breakpoints only needs `pos` per chromosome, which is
            // identical whether or not the VAF column has been added.
            offsets_and_tables = split.map { meta, chrom_files, offsets ->
                [meta.subMap('sampleID'), offsets, chrom_files]
            }
            segments_by_sample = segments.map { meta, seg ->
                [meta.subMap('sampleID'), seg]
            }.groupTuple()

            breakpoints = MERGE_BREAKPOINTS(offsets_and_tables.join(segments_by_sample)).breakpoints
            cn_input = table_with_vaf.join(breakpoints)
        } else {
            cn_input = table_with_vaf.map { meta, t -> [meta, t, no_file] }
        }

        CN_INFERENCE(cn_input)

        cn_expand_input = CN_INFERENCE.out.cn.combine(Channel.fromPath(centromere_bed))
        CN_EXPAND_SEGMENTS(cn_expand_input)

    emit:
        cn = CN_INFERENCE.out.cn
        cn_segments = CN_EXPAND_SEGMENTS.out.segments
        purity_ploidy = CN_INFERENCE.out.purity_ploidy
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
