#!/bin/bash
#SBATCH --partition=EPYC
#SBATCH --job-name=vcf_tumor
#SBATCH --nodes=1
#SBATCH --array=1-9
#SBATCH --cpus-per-task=24
#SBATCH --mem 30g
#SBATCH --time=24:00:00
#SBATCH --output=tumor_%a.out

echo $SLURMD_NODENAME

ch=${SLURM_ARRAY_TASK_ID}
echo $ch

module load bcftools

#bed=/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/bed_meth/chr${ch}_tumor_meth
bed=/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/vcf_meth/missing_bed/chr${ch}_missing
bam=/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/data/raw/COLO829/chr${ch}-COLO829.bam
fasta=/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
out=/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/meth/vcf_meth/missing_bed/missing_tumor_chr${ch}

bcftools mpileup -Ou -f $fasta $bam -R $bed \
	-Q 0 \
	--threads 24 \
	--annotate FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SP,INFO/AD,INFO/ADF,INFO/ADR \
        | bcftools call -Ov -m --threads 24 -o ${out}.vcf


