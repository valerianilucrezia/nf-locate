#!/bin/bash
#SBATCH --partition=THIN
#SBATCH --job-name=meth
#SBATCH --nodes=1
#SBATCH --array=1-22
#SBATCH --cpus-per-task=1
#SBATCH --mem 10g
#SBATCH --time=00:30:00
#SBATCH --output=tumor_%a.out

ch=${SLURM_ARRAY_TASK_ID}
echo $ch

bed=/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/COLO829.bed

cat $bed | grep -w "chr${ch}" | grep -v "random" | awk '{print $1, $3}' > /orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/bed_meth/"chr${ch}"_tumor_meth
