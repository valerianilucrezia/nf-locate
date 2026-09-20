#!/usr/bin/env nextflow

include { PREPARE_TABLE_VCF } from '../../modules/prepare_table_vcf/'
include { PREPARE_TABLE_METHYLATION } from '../../modules/prepare_table_methylation/'
include { PREPARE_TABLE_SOMATIC_VCF } from '../../modules/prepare_table_somatic_vcf/'
include { ALIGN_VAF as ALIGN_VAF_CHROM } from '../../modules/align_vaf/'
include { ALIGN_VAF as ALIGN_VAF_GENOME } from '../../modules/align_vaf/'
include { SPLIT_TABLE_BY_CHROM } from '../../modules/split_table_by_chrom/'
include { BIN_TABLE } from '../../modules/bin_table/'
include { SEGMENTATION } from '../../modules/segmentation/'
include { MERGE_BREAKPOINTS } from '../../modules/merge_breakpoints/'
include { CN_INFERENCE } from '../../modules/cn_inference/'
include { CN_EXPAND_SEGMENTS } from '../../modules/cn_expand_segments/'
include { CN_PLOT } from '../../modules/cn_plot/'
include { CN_DIAGNOSTIC_PLOT } from '../../modules/cn_diagnostic_plot/'
include { METHYLATION_INFERENCE } from '../../modules/methylation_inference/'
include { CLASSIFY_POSTERIOR } from '../../modules/classify_posterior/'
include { AGGREGATE_PROMOTERS } from '../../modules/aggregate_promoters/'


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

            // DR's noise has strong, slowly-decaying local autocorrelation
            // (not iid), so segmentation runs on fixed-size genomic bins
            // (median baf/dr/vaf) rather than raw per-SNP rows -- reduces
            // noise substantially for BAF/VAF, modestly for DR, at some
            // cost to breakpoint positional resolution. Set
            // segmentation_bin_size=0 to disable and segment the unbinned
            // table directly (the pre-binning behavior).
            def do_bin = (params.segmentation_bin_size ?: 30000) as int
            if (do_bin > 0) {
                binned_chrom_tables = BIN_TABLE(chrom_tables_with_vaf).table
                segments = SEGMENTATION(binned_chrom_tables).segments
            } else {
                binned_chrom_tables = Channel.empty()
                segments = SEGMENTATION(chrom_tables_with_vaf).segments
            }

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

            no_file_bp = file("${projectDir}/assets/NO_FILE")
            binned_by_sample = do_bin > 0
                ? binned_chrom_tables.map { meta, f -> [meta.subMap('sampleID'), f] }.groupTuple()
                : offsets_and_tables.map { key, offsets, chrom_files -> [key, [no_file_bp]] }

            merge_input = offsets_and_tables.join(segments_by_sample).join(binned_by_sample)
            breakpoints = MERGE_BREAKPOINTS(merge_input).breakpoints
            cn_input = table_with_vaf.join(breakpoints)
        } else {
            cn_input = table_with_vaf.map { meta, t -> [meta, t, no_file] }
        }

        CN_INFERENCE(cn_input)

        cn_expand_input = CN_INFERENCE.out.cn.combine(Channel.fromPath(centromere_bed))
        CN_EXPAND_SEGMENTS(cn_expand_input)

        // Diagnostic plots: genome-wide BAF/DR/(VAF)/CN/(confidence) track
        // plot (CN_PLOT) and the 4-panel SVI inference diagnostic
        // (CN_DIAGNOSTIC_PLOT) -- both read straight from CN_INFERENCE's own
        // outputs, joined back to the original whole-genome table and
        // breakpoints (if segmentation ran) by sampleID.
        table_by_id = table_with_vaf.map { meta, t -> [meta.subMap('sampleID'), t] }
        cn_by_id = CN_INFERENCE.out.cn.map { meta, f -> [meta.subMap('sampleID'), meta, f] }
        pp_by_id = CN_INFERENCE.out.purity_ploidy.map { meta, f -> [meta.subMap('sampleID'), f] }
        diag_by_id = CN_INFERENCE.out.diagnostics.map { meta, f -> [meta.subMap('sampleID'), f] }
        bp_by_id = cn_input.map { meta, t, bp -> [meta.subMap('sampleID'), bp] }

        cn_plot_input = cn_by_id.join(table_by_id).join(pp_by_id).join(diag_by_id).join(bp_by_id)
            .map { key, meta, cn, t, pp, diag, bp -> [meta, t, cn, pp, diag, bp] }
        CN_PLOT(cn_plot_input)

        CN_DIAGNOSTIC_PLOT(CN_INFERENCE.out.diagnostics)

    emit:
        cn = CN_INFERENCE.out.cn
        cn_segments = CN_EXPAND_SEGMENTS.out.segments
        purity_ploidy = CN_INFERENCE.out.purity_ploidy
        cn_plot = CN_PLOT.out.plot
        cn_diagnostic_plot = CN_DIAGNOSTIC_PLOT.out.plot
}


workflow LOCATE_METHYLATION {
    take:
        meth_h1_tumor   // tuple(meta, bed.gz, tbi) keyed by sampleID, chr, type -- modkit H1 bedMethyl
        meth_h2_tumor   // tuple(meta, bed.gz, tbi) keyed by sampleID, chr, type -- modkit H2 bedMethyl
        meth_h1_normal  // tuple(meta, bed.gz, tbi) keyed by sampleID, chr, type -- modkit H1 bedMethyl
        meth_h2_normal  // tuple(meta, bed.gz, tbi) keyed by sampleID, chr, type -- modkit H2 bedMethyl
        purity_ploidy   // tuple(meta, csv) keyed by sampleID -- LOCATE_CN's one-row purity/ploidy
                        // summary; rho is read from its `purity` column at runtime by
                        // METHYLATION_INFERENCE, replacing the old fixed params.methylation_rho
                        // (methylation samples are necessarily contaminated by normal tissue, so a
                        // single pipeline-wide rho can't be right for every sample).
        cn_segments     // tuple(meta, csv) keyed by sampleID -- LOCATE_CN.out.cn_segments
                        // (chrom/start/end/CN_Major/CN_minor, whole-genome). Enables
                        // AGGREGATE_PROMOTERS' LOH/CNLOH deleted-haplotype resolution; the
                        // NO_FILE placeholder disables it (promoters are still reported, just
                        // without the deleted-haplotype-aware masking).
        reftss_promoters // path -- refTSS promoter reference CSV (export_reftss_promoters.R's
                        // output: gene/chrom/strand/tss/prom_start/prom_end, every alternative
                        // promoter kept, not just MANE canonical), or NO_FILE to skip the
                        // classify-posterior/aggregate-promoters taxonomy entirely.
        imprinted_genes // path -- gene-list CSV/TXT (see `locate methylation
                        // build-imprinted-genes`), or NO_FILE to skip imprinted-gene exclusion.
        tumor_phased_vcf  // tuple(meta, vcf, tbi) keyed by sampleID, chr -- BATTENBERG_PHASE.out.vcf
                        // (tumor phasing, phase-block field SEGMENT_H1). With normal_phased_vcf, used to
                        // reorient the normal's H1/H2 against the tumor's before the tumor/normal comparison.
        normal_phased_vcf // tuple(meta, vcf) keyed by sampleID, chr -- LONGPHASE.out.vcf (normal phasing,
                        // phase-block field PS).

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

        // Tumor/normal H1/H2 orientation: phasing labels H1/H2 arbitrarily per phase
        // block, independently per sample, so tumor and normal H1 only agree by
        // chance. Joining both phased VCFs lets `prepare-table from-bed` reorient the
        // normal per block and mark `orientation_resolved`; without it TSM/NSM would
        // silently compare mismatched haplotypes about half the time.
        if (params.methylation_reorient.toString() == 'true') {
            meth_table_input = meth_table_input
                .join(tumor_phased_vcf.map { meta, v, tbi -> [meta.subMap(key), v] })
                .join(normal_phased_vcf.map { meta, v -> [meta.subMap(key), v] })
        } else {
            no_file_vcf = file("${projectDir}/assets/NO_FILE")
            meth_table_input = meth_table_input.map { k, a, b, c, d, e, f, g, h -> [k, a, b, c, d, e, f, g, h, no_file_vcf, no_file_vcf] }
        }

        methylation_table = PREPARE_TABLE_METHYLATION(meth_table_input).table

        // purity_ploidy is one row per sampleID (genome-wide) -- fan it out
        // to every chromosome of that sample via combine(by: sampleID).
        table_by_sample = methylation_table.map { meta, t -> [meta.subMap('sampleID'), meta, t] }
        purity_by_sample = purity_ploidy.map { meta, pp -> [meta.subMap('sampleID'), pp] }

        table_with_purity = table_by_sample.combine(purity_by_sample, by: 0)
            .map { key_, meta, t, pp -> [meta, t, pp] }

        METHYLATION_INFERENCE(table_with_purity)

        // classify-posterior/aggregate-promoters is additive alongside
        // infer-asm/analyze-asm above, not a replacement -- see
        // add_classify_posterior_arguments' own CLI help text. Gated on
        // run_methylation_taxonomy since it needs a refTSS promoter
        // reference the pipeline has no vendored default for.
        run_taxonomy = params.run_methylation_taxonomy.toString() == 'true'
        if (run_taxonomy) {
            CLASSIFY_POSTERIOR(table_with_purity)

            cn_by_sample = cn_segments.map { meta, f -> [meta.subMap('sampleID'), f] }
            classified_by_sample = CLASSIFY_POSTERIOR.out.classified.map { meta, f -> [meta.subMap('sampleID'), meta, f] }

            agg_input = classified_by_sample.combine(cn_by_sample, by: 0)
                .map { key_, meta, f, cn -> [meta, f, cn] }
                .combine(Channel.fromPath(reftss_promoters))
                .combine(Channel.fromPath(imprinted_genes))

            AGGREGATE_PROMOTERS(agg_input)

            // one row per sample: concatenate all chromosomes' per-chromosome
            // promoter tables, matching aggregate_promoters_reftss.py's own
            // per-sample pd.concat -- keeps the whole-genome file directly
            // comparable to that reference output.
            promoters_genome = AGGREGATE_PROMOTERS.out.promoters
                .map { meta, f -> [meta.subMap('sampleID').sampleID, f] }
                .collectFile(keepHeader: true, skip: 1, storeDir: "${params.outdir}/locate/methylation/promoters") { sampleID, f ->
                    ["${sampleID}_promoters_reftss.csv", f]
                }
        }

    emit:
        betat = METHYLATION_INFERENCE.out.betat
        asm   = METHYLATION_INFERENCE.out.asm
        classified = run_taxonomy ? CLASSIFY_POSTERIOR.out.classified : Channel.empty()
        promoters  = run_taxonomy ? AGGREGATE_PROMOTERS.out.promoters : Channel.empty()
        promoters_genome = run_taxonomy ? promoters_genome : Channel.empty()
}
