#!/bin/bash
#SBATCH --partition=EPYC
#SBATCH --job-name=whatshap
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --mem 50g
#SBATCH --time=48:00:00


bam=""
vcf=""
outdir=""
ref=""

whatshap phase -o ${outdir} \
    --ignore-read-groups \
    --reference \
    ${ref} \
    ${vcf} \
    ${bam}