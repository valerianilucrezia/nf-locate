#!/bin/bash
#SBATCH --partition=THIN
#SBATCH --job-name=normal_split
#SBATCH --nodes=1
#SBATCH --array=1-22
#SBATCH --cpus-per-task=1
#SBATCH --mem 50g
#SBATCH --time=2:00:00
#SBATCH --output=normal_%a.out

module load samtools
ch=${SLURM_ARRAY_TASK_ID}
echo $ch

bam=/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/data/raw/COLO829_L/COLO829_L.bam

cd /orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/data/raw/COLO829_L/

samtools view -b -h -o chr${ch}-COLO829_L.bam COLO829_L.bam "chr${ch}"
samtools index chr${ch}-COLO829_L.bam
