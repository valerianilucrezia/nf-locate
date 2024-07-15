library(dplyr)
library(vcfR)


file <- ''
res_dir <- ''

vcf <- vcfR::read.vcfR(file)
vcf <- vcfR::vcfR2tidy(vcf)
fix <- vcf$fix %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, CHROM, POS, REF, ALT, FILTER)
gt <- vcf$gt %>% dplyr::mutate(id = paste(ChromKey, POS, sep = ':')) %>% select(id, gt_DP, gt_AF, gt_AD)
vaf <- full_join(fix, gt)
saveRDS(object = vaf, file = paste0(res_dir, 'vaf.RDS'))