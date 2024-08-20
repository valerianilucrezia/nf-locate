
#!/usr/bin/env Rscript
library(dplyr)
library(vcfR)

args <- commandArgs(trailingOnly = TRUE)
file <- args[1]         # vcf file
res_dir <- args[2]      # output dir

print(res_dir)
