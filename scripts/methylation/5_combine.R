library(vcfR)
library(dplyr)

input = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/vcf_meth/vcf/'
output = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/vcf_meth/rds/'
meth = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/df_meth/chr_meth_combined/'


read_vcf <- function(chr){
	vcf <- read.vcfR(paste0(input, 'normal_', chr, '.vcf'))
	vcf <- vcfR2tidy(vcf)

	gt <- vcf$gt %>% 
		mutate(id = paste(ChromKey, POS, sep=':')) %>%
		select(id, gt_DP, gt_AD, gt_GT) 	

	fix <- vcf$fix %>% 
                mutate(id = paste(ChromKey, POS, sep=':')) %>%
		select(id, CHROM, POS, REF, ALT, INDEL, DP, AD)%>%
		tidyr::separate(AD, c('nRef', 'nAlt'), ',')

	join_vcf <- inner_join(fix, gt, join_by(id)) %>% 
			select(-id) %>%
			mutate(ID = paste(CHROM, POS, sep = ':'))
			       
	rds <- readRDS(paste0(meth, 'normal_', chr, '.RDS')) %>%
		mutate(ID = paste(chr, end, sep = ':'))

        join <- inner_join(rds, join_vcf,  join_by(ID)) %>% select(-CHROM, -POS)
}

chr <- 'chr22'
tmp <- read_vcf(chr)
saveRDS(tmp, paste0(output, 'meth_join_normal_', chr, '.RDS'))
#for (chr in paste0('chr', seq(1,22))){
#tmp <- read_vcf(chr)
#saveRDS(tmp, paste0(output, 'meth_join_normal_', chr, '.RDS'))
#}

