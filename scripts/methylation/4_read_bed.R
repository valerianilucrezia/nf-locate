library(dplyr)
library(data.table)
library(tidyr)

out = ''
file <- '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/COLO829_L.bed'
chrs <- paste0('chr', 1:22)

nt <- 24
file <- fread(N_file, nThread = nt)
file <-  file %>% filter(V1 %in% chrs)
rm(file)

colnames(file) <- c('chr', 'start', 'end', 'mod', 'score', 'strand', 'v1', 'v2', 'v3', 'N')
data <- file %>% select(-v1, -v2, -v3, -mod)

read_meth <- function(data, ch){
  f_file <- data %>% 
    filter(chr == ch) %>% 
    separate(N, into = c("cov", "beta", 'mod', 'canon', 'other', 'delete', 'fail', 'diff', 'nocall'), sep = " ")
  
  saveRDS(f_file, paste0(out,'_', ch, '.RDS'))
}

for (ch in chrs){
  read_meth(data, ch, 'tumor')
}