#!/usr/bin/env Rscript
library(dplyr)
library(vcfR)

get_join_meth <- function(c, vcf_tumor, vcf_normal, output_name) {
  T_vcf <- vcfR::read.vcfR(vcf_tumor)
  T_vcf <- vcfR::vcfR2tidy(T_vcf)
  #fix <- T_vcf$fix %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, CHROM, POS, REF, ALT, FILTER)
  #gt <- T_vcf$gt %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, gt_DP, gt_AF, gt_AD) ---- old
  #gt <- T_vcf$gt %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, gt_DP)
  #T_join <- inner_join(fix, gt)

    
  #N_vcf <- vcfR::read.vcfR(vcf_normal)
  #N_vcf <- vcfR::vcfR2tidy(N_vcf)
  #fix <- N_vcf$fix %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, CHROM, POS, REF, ALT, FILTER)
  # gt <- N_vcf$gt %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, gt_DP, gt_AF, gt_AD) ---- old
  #gt <- N_vcf$gt %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, gt_DP)
  #N_join <- inner_join(fix, gt)

  #join <- full_join(T_join, N_join, by = join_by(id, suffix = c("_T", "_N")))  
  saveRDS(object = T_vcf, file = paste0(output_name, '_join_meth.RDS'))
}


######################################################
### Processing a single chromosome
######################################################

args <- commandArgs(trailingOnly = TRUE)
c <- args[1] # chromosome
vcf_tumor <-  args[2] 
vcf_normal <- args[3] 
output_name <-  paste0("chr",c,"_COLO829")

get_join_meth(c, vcf_tumor, vcf_normal, output_name)