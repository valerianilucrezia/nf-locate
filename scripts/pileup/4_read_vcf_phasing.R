library(dplyr)
library(vcfR)

for (c in seq(1,22)){
  vcf_tumor <- ''
  vcf_normal <- ''
  
  T_vcf <- vcfR::read.vcfR(vcf_tumor)
  T_vcf <- vcfR::vcfR2tidy(T_vcf)
  fix <- T_vcf$fix %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, CHROM, POS, REF, ALT, FILTER)
  gt <- T_vcf$gt %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, gt_DP, gt_AF, gt_AD)
  T_join <- inner_join(fix, gt)

    
  N_vcf <- vcfR::read.vcfR(vcf_normal)
  N_vcf <- vcfR::vcfR2tidy(N_vcf)
  fix <- N_vcf$fix %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, CHROM, POS, REF, ALT, FILTER)
  gt <- N_vcf$gt %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, gt_DP, gt_AF, gt_AD)
  N_join <- inner_join(fix, gt)

  join <- full_join(T_join, N_join, by = join_by(id, suffix = c("_T", "_N"))  
  saveRDS(object = join, file = paste0(res_dir, 'join_meth.RDS'))
}
