library(dplyr)
library(vcfR)

for (ch in paste0('chr', seq(1,22))){
	print(ch)
	data <- paste0('/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/allelecount/vcf_cnv/normal/filter/vcf/filter_g100_', ch, '.vcf.gz')

	vcf <- read.vcfR(data)
	vcf <- vcfR::vcfR2tidy(vcf)

	fix <- vcf$fix %>% 
	mutate(id = paste(ChromKey, POS, sep=':')) %>% 
	select(id, CHROM, REF, ALT, INDEL,DP)

	gt <- vcf$gt %>% 
	mutate(id = paste(ChromKey, POS, sep=':')) %>%
	select(id, POS, gt_DP, gt_AD, gt_GT, gt_GT_alleles, -gt_GT_alleles) 

	join <- inner_join(gt, fix, join_by(id)) %>%
	tidyr::separate(col = gt_AD, into = c('Nref', 'Nalt'), convert = T) %>%
	mutate(AF = Nalt/(Nalt + Nref)) %>%
	mutate(AF = ifelse(is.na(AF),  0, AF))
	
	saveRDS(join, paste0('/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/allelecount/vcf_cnv/normal/filter/rds/filter_g100_', ch, '.rds'))

}
