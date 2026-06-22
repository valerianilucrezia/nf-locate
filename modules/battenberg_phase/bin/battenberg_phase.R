#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(optparse)
  library(vcfR)
  library(dplyr)
  library(tidyr)
})

suppressPackageStartupMessages(library(Battenberg))

option_list <- list(
  make_option('--tumor',   type = 'character', help = 'HAPLOTAGPHASE tumor VCF (bgzipped)'),
  make_option('--shapeit', type = 'character', help = 'SHAPEIT4 phased VCF (bgzipped)'),
  make_option('--normal',  type = 'character', help = 'Normal sample VCF with DP/AD (bgzipped)'),
  make_option('--output',  type = 'character', help = 'Output VCF path (plain .vcf, will be bgzipped)'),
  make_option('--sample',  type = 'character', help = 'Sample ID'),
  make_option('--chr',     type = 'character', help = 'Chromosome'),
  make_option('--qual',    type = 'double', default = 10, help = 'Minimum QUAL for tumor records [default %default]'),
  make_option('--min-dp-tumor', type = 'integer', default = 15, dest = 'min_dp_tumor', help = 'Minimum tumor DP for segmentation [default %default]'),
  make_option('--phasing-gamma', type = 'double', default = 3, dest = 'phasing_gamma', help = 'PCF gamma multiplier [default %default]'),
  make_option('--phasing-kmin',  type = 'integer', default = 3, dest = 'phasing_kmin', help = 'PCF kmin [default %default]')
)
opt <- parse_args(OptionParser(option_list = option_list))

read_vcf <- function(path) {
  vcf <- read.vcfR(path, verbose = FALSE) %>% vcfR2tidy(info_only = FALSE)

  fix <- vcf$fix %>%
    select(ChromKey, CHROM, POS, REF, ALT, QUAL, FILTER)

  gt <- vcf$gt %>%
    select(ChromKey, POS, gt_DP, gt_AD, gt_GT, gt_PS)

  inner_join(fix, gt, by = c('ChromKey', 'POS')) %>%
    select(-ChromKey) %>%
    distinct() %>%
    tidyr::separate(gt_AD, into = c('NR', 'NV'), convert = TRUE, extra = 'drop', fill = 'right') %>%
    mutate(BAF = NV / (NR + NV)) %>%
    tidyr::separate(gt_GT, sep = '\\|', into = c('H1', 'H2'), remove = FALSE)
}

read_vcf_shapeit <- function(path) {
  vcf <- read.vcfR(path, verbose = FALSE) %>% vcfR2tidy(info_only = FALSE)

  fix <- vcf$fix %>%
    select(ChromKey, CHROM, POS, REF, ALT, QUAL, FILTER)

  gt <- vcf$gt %>%
    select(ChromKey, POS, gt_GT)

  inner_join(fix, gt, by = c('ChromKey', 'POS')) %>%
    select(-ChromKey) %>%
    distinct() %>%
    tidyr::separate(gt_GT, sep = '\\|', into = c('H1', 'H2'), remove = FALSE)
}

message('Reading tumor VCF: ', opt$tumor)
tumor <- read_vcf(opt$tumor) %>%
  filter(REF %in% c('A', 'G', 'C', 'T'), ALT %in% c('A', 'G', 'C', 'T')) %>%
  mutate(BAF_H1_LP = ifelse(H1 == '1', BAF, 1 - BAF)) %>%
  mutate(BAF_H2_LP = ifelse(H2 == '1', BAF, 1 - BAF))

message('Reading SHAPEIT4 VCF: ', opt$shapeit)
shapeit <- read_vcf_shapeit(opt$shapeit) %>%
  filter(REF %in% c('A', 'G', 'C', 'T'), ALT %in% c('A', 'G', 'C', 'T'))

message('Reading normal VCF: ', opt$normal)
normal_full <- read_vcf(opt$normal) %>%
  filter(REF %in% c('A', 'G', 'C', 'T'), ALT %in% c('A', 'G', 'C', 'T'))

normal <- normal_full %>%
  select(CHROM, POS, gt_DP)

normal_phase <- normal_full %>%
  filter(gt_GT != '1/1', gt_GT != '0/0', gt_GT != '1|1', gt_GT != '0|0') %>%
  select(CHROM, POS, H1_NORMAL = H1, H2_NORMAL = H2)

message('mean DP tumor=', round(mean(tumor$gt_DP, na.rm = TRUE), 2),
        ' normal=', round(mean(normal$gt_DP, na.rm = TRUE), 2))

# gt_DP_T / gt_DP_N (raw per-position tumor/normal depth, kept un-divided) are
# passed through as-is rather than combined into a DR ratio here. This script
# runs once per chromosome (see --chr / BATTENBERG_PHASE's per-chromosome
# tag), so computing/normalizing a depth ratio at this point would only ever
# see one chromosome's depths -- a per-chromosome ratio would normalize each
# chromosome against its own depth, erasing real chromosome-level CN signal
# (e.g. an arm-level gain would partly cancel against its own normalization
# factor). DR must be derived downstream from these raw DP_T/DP_N values
# once all chromosomes are combined for a sample, using the genome-wide mean.
join <- tumor %>%
  left_join(shapeit, by = c('CHROM', 'POS'), suffix = c('_LP', '_SI')) %>%
  filter(FILTER_LP == 'PASS') %>%
  filter(gt_GT_LP != '1/1', gt_GT_LP != '0/0', gt_GT_LP != '1|1', gt_GT_LP != '0|0') %>%
  mutate(BAF_H1_SI = ifelse(H1_SI == '1', BAF, 1 - BAF)) %>%
  mutate(BAF_H2_SI = ifelse(H2_SI == '1', BAF, 1 - BAF)) %>%
  filter(QUAL_LP >= opt$qual) %>%
  left_join(normal, by = c('CHROM', 'POS'), suffix = c('_T', '_N'))

seg_input <- join %>%
  filter(gt_DP_T > opt$min_dp_tumor, QUAL_LP > opt$min_dp_tumor) %>%
  filter(!is.na(BAF_H1_SI), !is.na(BAF_H2_SI)) %>%
  distinct(CHROM, POS, .keep_all = TRUE) %>%
  arrange(CHROM, POS)

result <- join %>%
  mutate(SEGMENT_H1 = NA_real_, PHASED_H1 = NA_real_, PHASED_H2 = NA_real_)

# selectFastPcf's runFastPcf (n < 1000 branch) hardcodes L = 8 and requires
# n >= 6*L = 48 data points, otherwise filterMarkS4 indexes with mixed
# positive/negative subscripts and errors out.
MIN_SEG_POINTS <- 49

if (nrow(seg_input) >= MIN_SEG_POINTS) {
  sdev <- Battenberg:::getMad(
    ifelse(seg_input$BAF_H1_SI < 0.5, seg_input$BAF_H1_SI, 1 - seg_input$BAF_H1_SI),
    k = 25
  )
  if (is.na(sdev) || sdev < 0.002) sdev <- 0.002

  hap_segs <- Battenberg:::selectFastPcf(
    seg_input$BAF_H1_SI,
    kmin = opt$phasing_kmin,
    gamma = opt$phasing_gamma * sdev,
    yest = TRUE
  )

  seg_input$SEGMENT_H1 <- hap_segs$yhat
  seg_input$PHASED_H1 <- ifelse(seg_input$SEGMENT_H1 < 0.5, 1 - seg_input$BAF_H1_SI, seg_input$BAF_H1_SI)
  seg_input$PHASED_H2 <- ifelse(seg_input$SEGMENT_H1 < 0.5, 1 - seg_input$BAF_H2_SI, seg_input$BAF_H2_SI)

  result <- result %>%
    select(-SEGMENT_H1, -PHASED_H1, -PHASED_H2) %>%
    left_join(
      seg_input %>% select(CHROM, POS, SEGMENT_H1, PHASED_H1, PHASED_H2),
      by = c('CHROM', 'POS')
    )
} else {
  message('Only ', nrow(seg_input), ' positions passed segmentation filters (gt_DP_T > ', opt$min_dp_tumor,
          ' & QUAL_LP > ', opt$min_dp_tumor, '); need >= ', MIN_SEG_POINTS,
          ' for PCF segmentation. Output will carry empty annotations.')
}

# --- determine whether the corrected tumor H1 frame is globally flipped ---
# --- relative to the normal LONGPHASE H1 frame, at shared het sites ---
concordance <- result %>%
  filter(!is.na(SEGMENT_H1)) %>%
  mutate(CORRECTED_H1 = ifelse(SEGMENT_H1 < 0.5, H2_LP, H1_LP)) %>%
  inner_join(normal_phase, by = c('CHROM', 'POS')) %>%
  filter(!is.na(CORRECTED_H1), !is.na(H1_NORMAL))

global_flip <- FALSE
if (nrow(concordance) > 0) {
  discordant <- mean(concordance$CORRECTED_H1 != concordance$H1_NORMAL)
  message('Tumor-H1 vs normal-H1 discordance at ', nrow(concordance),
          ' shared het sites: ', round(discordant, 4))
  if (discordant > 0.5) {
    global_flip <- TRUE
    message('Tumor H1 frame is flipped relative to normal H1; applying global swap.')
  }
} else {
  message('No shared het sites with normal for H1/H2 frame alignment; skipping global swap check.')
}

if (global_flip) {
  result <- result %>%
    mutate(
      SEGMENT_H1 = ifelse(is.na(SEGMENT_H1), NA_real_, 1 - SEGMENT_H1),
      tmp = PHASED_H1, PHASED_H1 = PHASED_H2, PHASED_H2 = tmp
    ) %>%
    select(-tmp)
}

# --- annotate the original tumor VCF and write output ---
message('Writing annotated VCF: ', opt$output)

vcf_in <- read.vcfR(opt$tumor, verbose = FALSE)

ann <- result %>%
  transmute(
    CHROM, POS,
    BAF_H1 = PHASED_H1,
    BAF_H2 = PHASED_H2,
    DP_T = gt_DP_T,
    DP_N = gt_DP_N,
    SEGMENT_H1 = SEGMENT_H1,
    SWAP = !is.na(SEGMENT_H1) & SEGMENT_H1 < 0.5
  )

fix_df <- as.data.frame(vcf_in@fix, stringsAsFactors = FALSE)
key <- paste(fix_df$CHROM, fix_df$POS, sep = ':')
ann_key <- paste(ann$CHROM, ann$POS, sep = ':')
idx <- match(key, ann_key)

fmt_num <- function(x, digits = 4) {
  out <- rep('.', length(x))
  ok <- !is.na(x)
  out[ok] <- formatC(x[ok], format = 'f', digits = digits)
  out
}

baf_h1 <- fmt_num(ann$BAF_H1[idx])
baf_h2 <- fmt_num(ann$BAF_H2[idx])
dp_t   <- fmt_num(ann$DP_T[idx], digits = 0)
dp_n   <- fmt_num(ann$DP_N[idx], digits = 0)
seg_h1 <- fmt_num(ann$SEGMENT_H1[idx])

new_info <- paste0('BAF_H1=', baf_h1, ';BAF_H2=', baf_h2, ';DP_T=', dp_t, ';DP_N=', dp_n, ';SEGMENT_H1=', seg_h1)
existing_info <- fix_df$INFO
existing_info[is.na(existing_info) | existing_info == '.'] <- ''
sep <- ifelse(existing_info == '', '', ';')
fix_df$INFO <- paste0(existing_info, sep, new_info)
vcf_in@fix[, 'INFO'] <- fix_df$INFO

vcf_in@meta <- c(
  vcf_in@meta,
  '##INFO=<ID=BAF_H1,Number=1,Type=Float,Description="Battenberg-corrected B-allele frequency for haplotype 1">',
  '##INFO=<ID=BAF_H2,Number=1,Type=Float,Description="Battenberg-corrected B-allele frequency for haplotype 2">',
  '##INFO=<ID=DP_T,Number=1,Type=Integer,Description="Raw tumor read depth at this position (un-normalized; combine with DP_N downstream across all chromosomes for a genome-wide-normalized depth ratio)">',
  '##INFO=<ID=DP_N,Number=1,Type=Integer,Description="Raw normal read depth at this position (un-normalized; combine with DP_T downstream across all chromosomes for a genome-wide-normalized depth ratio)">',
  '##INFO=<ID=SEGMENT_H1,Number=1,Type=Float,Description="PCF segment value for haplotype 1 BAF">'
)

# --- swap GT alleles where SEGMENT_H1 < 0.5, so the output VCF reflects ---
# --- the Battenberg-corrected haplotype assignment for re-haplotagging ---
swap <- ann$SWAP[idx]
swap[is.na(swap)] <- FALSE

if (any(swap)) {
  gt_mat <- vcf_in@gt
  fmt <- gt_mat[, 'FORMAT']
  gt_field_idx <- sapply(strsplit(fmt, ':'), function(x) match('GT', x))

  sample_cols <- colnames(gt_mat)[colnames(gt_mat) != 'FORMAT']
  for (col in sample_cols) {
    values <- strsplit(gt_mat[, col], ':')
    swapped <- mapply(function(v, fi, do_swap) {
      if (do_swap && !is.na(fi) && !is.na(v[fi])) {
        gt <- v[fi]
        sep <- if (grepl('\\|', gt)) '|' else if (grepl('/', gt)) '/' else NA
        if (!is.na(sep)) {
          alleles <- strsplit(gt, sep, fixed = TRUE)[[1]]
          if (length(alleles) == 2) {
            v[fi] <- paste(alleles[2], alleles[1], sep = sep)
          }
        }
      }
      paste(v, collapse = ':')
    }, values, gt_field_idx, swap, SIMPLIFY = TRUE)
    gt_mat[, col] <- swapped
  }
  vcf_in@gt <- gt_mat
}

write.vcf(vcf_in, file = opt$output)

# write.vcf always writes .vcf.gz; rename if needed to match requested --output
written <- paste0(opt$output, ifelse(grepl('\\.gz$', opt$output), '', '.gz'))
if (written != opt$output && file.exists(written)) {
  file.rename(written, opt$output)
}

message('Done.')
