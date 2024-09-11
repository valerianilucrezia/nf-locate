#!/usr/bin/env Rscript
library(dplyr)
library(vcfR)

args <- commandArgs(trailingOnly = TRUE)
file <- args[1]         # vcf file

vcf <- vcfR::read.vcfR(file)
vcf <- vcfR::vcfR2tidy(vcf)
fix <- vcf$fix %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, CHROM, POS, REF, ALT, FILTER)
gt <- vcf$gt %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, gt_DP, gt_AF, gt_AD)
vaf <- full_join(fix, gt) %>% select(-ChromKey)

base_name <- sub('\\.vcf.gz*$', '', basename(file))
output_file <- paste0(base_name, '_vaf.RDS')
saveRDS(object = vaf, file = output_file)
