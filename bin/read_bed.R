library(dplyr)
library(data.table)
library(tidyr)

# Function to process data for a single chromosome
read_meth <- function(data, ch, out) {
  f_file <- data %>%
    filter(chr == ch) %>%
    separate(N, into = c("cov", "beta", 'mod', 'canon', 'other', 'delete', 'fail', 'diff', 'nocall'), sep = " ")
  
  saveRDS(f_file, paste0(out, '_chr', ch, '.RDS'))
}


######################################################
### Processing a single chromosome
######################################################
args <- commandArgs(trailingOnly = TRUE)
out <- args[3] # output dir
bed_file <- args[2]   # path to the single bed file
chr <- args[1] # chromosome

file <- fread(bed_file, nThread = 2)
colnames(file) <- c('chr', 'start', 'end', 'mod', 'score', 'strand', 'v1', 'v2', 'v3', 'N')

data <- file %>%
  filter(chr == chr) %>%
  select(-v1, -v2, -v3, -mod)

read_meth(data, chr, out)