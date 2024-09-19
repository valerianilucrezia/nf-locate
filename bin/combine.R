#!/usr/bin/env Rscript
library(dplyr)
library(vcfR)

# function to read a process vcf files 
read_vcf <- function(file){
  vcf <- read.vcfR(file)
  vcf <- vcfR2tidy(vcf)
  
  gt <- vcf$gt %>% 
    mutate(id = paste(ChromKey, POS, sep=':')) %>%
    select(id, gt_DP, gt_AD, gt_GT) 	
  
  fix <- vcf$fix %>% 
    mutate(id = paste(ChromKey, POS, sep=':')) %>%
    filter(INDEL == FALSE) %>%
    select(id, CHROM, POS, REF, ALT, DP, AD)%>%
    tidyr::separate(AD, c('nRef', 'nAlt'), ',')
  
  join_vcf <- inner_join(fix, gt, join_by(id)) %>% 
    select(-id)
  
  return(join_vcf)
}

# Combines methylation and VCF data 
get_meth <- function(chr, mT, vcfT, vcfN, sample){  
  meth_tumor <- readRDS(mT)
  
  vcf_normal <- read_vcf(vcfN)
  vcf_tumor <- read_vcf(vcfT)
  
  T_join <- full_join(meth_tumor, vcf_tumor, by = join_by(CHROM, POS))
  join <- inner_join(T_join, vcf_normal, by = join_by(CHROM, POS), suffix= c('_T', '_N')) 
  saveRDS(object = join, file = paste0(sample, '_chr', chr, '_methylation_join.RDS'))
}


######################################################
### Processing a single chromosome
######################################################
args <- commandArgs(trailingOnly = TRUE)
chr <- args[1] # chromosome
T_vcf <- args[2] # Tumor .vcf
N_vcf <- args[3] # Normal .vcf
T_rds <- args[4] # Tumor .RDS
sample <- args[5] # Sample Name

get_meth(chr, T_rds, T_vcf, N_vcf, sample)

