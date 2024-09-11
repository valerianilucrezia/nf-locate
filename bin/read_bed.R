#!/usr/bin/env Rscript
library(dplyr)
library(data.table)
library(tidyr)

args <- commandArgs(trailingOnly = TRUE)
bed <- args[1]   # path to the bed file

file <- fread(bed, nThread = getDTthreads())
colnames(file) <- c('chr', 'start', 'end', 'mod', 'score', 'strand', 'v1', 'v2', 'v3', "cov", "beta", 'mod', 'canon', 'other', 'delete', 'fail', 'diff', 'nocall')
data <- file %>%
  dplyr::select(-v1, -v2, -v3, -mod, -strand, -start) %>%
  dplyr::rename(POS = end, CHROM = chr)
  #separate(N, into = c("cov", "beta", 'mod', 'canon', 'other', 'delete', 'fail', 'diff', 'nocall'), sep = " ")

basename <- sub('\\.bed*$', '', basename(bed))
saveRDS(object = data, file = paste0(basename, '.RDS'))
