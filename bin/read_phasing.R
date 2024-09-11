#!/usr/bin/env Rscript
library(dplyr)
library(vcfR)
library(tidyverse)

read_vcf <- function(filename) {
  vcf <- vcfR::read.vcfR(filename)
  vcf <- vcfR::vcfR2tidy(vcf)
  fix <- vcf$fix %>% filter(INDEL == 'FALSE') %>% select(ChromKey, CHROM, POS, REF, ALT)
  gt <- vcf$gt %>% select(ChromKey, POS, gt_DP, gt_AD, gt_GT, gt_PS)
  join <- inner_join(fix, gt, by = join_by(ChromKey, POS)) %>% 
       tidyr::separate(gt_AD, into = c('R_AD', 'A_AD'), sep = ',', remove = T, convert = T) %>%
       dplyr::mutate(BAF = A_AD/gt_DP) %>%
       dplyr::select(-ChromKey) %>%
       dplyr::filter(gt_GT != "1/2", !is.na(gt_GT))
  return(join)
}

args <- commandArgs(trailingOnly = TRUE)
c <- args[1] #chromosome
vcf_tumor <-  args[2] 
vcf_normal <- args[3] 
output_name <-  args[3] #sample name

vcf_T <- read_vcf(vcf_tumor)
vcf_N <- read_vcf(vcf_normal)

T_mean_cov <- mean(vcf_T$gt_DP)
T_median_cov <- median(vcf_T$gt_DP)

N_mean_cov <- mean(vcf_N$gt_DP)
N_median_cov <- median(vcf_N$gt_DP)

corr_mean <- N_mean_cov / T_mean_cov
corr_median <- N_median_cov / T_median_cov

vcf_join <- inner_join(vcf_N, vcf_T, by = join_by(CHROM,POS), suffix = c('_N', '_T')) %>%
  dplyr::mutate(DR = gt_DP_T / gt_DP_N) %>%
  dplyr::mutate(mean_DR = DR * corr_mean,
                median_DR = DR * corr_median) %>%
  dplyr::mutate(mirr_BAF = ifelse(BAF_T > 0.5, 1-BAF_T, BAF_T)) %>%
  dplyr::arrange(POS) %>%
  dplyr::mutate(pos = seq(1, n()))

saveRDS(object=vcf_join, file=paste0(output_name, '_chr', c, '.RDS'))


