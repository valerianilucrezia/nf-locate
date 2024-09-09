#!/usr/bin/env Rscript
library(dplyr)
library(data.table)
library(vcfR)
library(tidyr)  # added to "separate"

# function to read a process vcf files 
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

# Combines methylation and VCF data 
get_meth <- function(chr, mT, vcfT, vcfN, sample){
  # meth_normal <- mN  %>% 
  #   mutate(id = paste(chr, end, sep = ':')) %>% 
  #   select(-score, -strand)
  
  meth_tumor <- mT %>% 
    mutate(id = paste(chr, end, sep = ':')) %>% 
    select(-score, -strand, -chr, -end, -start)
  
  vcf_normal <- get_vcf(vcfN)
  vcf_tumor <- get_vcf(vcfT)
  

  tumor <- meth_tumor #full_join(meth_tumor, vcf_tumor)
  
  saveRDS(object = tumor, file = paste0(sample, '_tumor_', chr, '.RDS'))
}


######################################################
### Processing a single chromosome
######################################################
args <- commandArgs(trailingOnly = TRUE)
chr <- args[1] # chromosome

meth_tumor_rds <- readRDS(args[4]) # .RDS

meth_tumor_vcf <- args[2] #readRDS(args[4]) #.vcf
meth_normal_vcf <- args[3] #readRDS(args[5]) #.vcf

sample <- args[4]

get_meth(chr, meth_tumor_rds, meth_tumor_vcf, meth_normal_vcf, sample)

