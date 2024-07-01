library(dplyr)
library(data.table)
library(vcfR)

setwd('/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/df')

get_vcf <- function(file){
  vcf <- read.vcfR(file)
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
  
  return(join_vcf)
}


get_meth <- function(mN, mT, vcfN, vcfT){
  meth_normal <- mN  %>% 
    mutate(id = paste(chr, end, sep = ':')) %>% 
    select(-score, -strand)
  
  meth_tumor <- mT %>% 
    mutate(id = paste(chr, end, sep = ':')) %>% 
    select(-score, -strand, -chr, -end, -start)
  
  vcf_normal <- get_vcf(vcfN)
  vcf_tumor <- get_vcf(vcfT)
  
  normal <- full_join(meth_normal, vcf_normal)
  tumor <- full_join(meth_tumor, vcf_tumor)
  
  saveRDS(object = normal, file = '')
  saveRDS(object = tumor, file = '')
  
  join_all <- inner_join(normal, tumor, suffix = c('_N', '_T'), by = join_by(id))
  saveRDS(object = join_all, file = '')
  
}


for (chr in paste0('chr', seq(1,22))){
  meth_normal <- readRDS("./meth_normal.RDS") 
  meth_tumor <- readRDS("./meth_tumor.RDS")
  
  vcf_normal <-  readRDS("./meth_normal.vcf") 
  vcf_tumor <-  readRDS("./meth_tumor.vcf")
  get_meth(chr, meth_normal, meth_tumor, vcf_normal, vcf_tumor)
}
