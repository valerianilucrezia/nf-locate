#!/bin/bash
#SBATCH --partition=EPYC
#SBATCH --job-name=tumor_modkit
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --mem 50g
#SBATCH --time=48:00:00

cd /orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/dist

in="/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/data/raw/COLO829/COLO829.bam"
out="/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/COLO829.bed"
log="/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/tumor_pileup.log"
ref="/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna"

./modkit pileup $in $out --ignore h --ref $ref --cpg --combine-strands  --log-filepath $log -t 24
./modkit pileup $in ${out}_bystrand --ignore h --ref $ref --log-filepath ${log}_bystrand -t 24

