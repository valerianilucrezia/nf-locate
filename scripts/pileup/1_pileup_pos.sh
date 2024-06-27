#!/bin/bash
#SBATCH --partition=EPYC
#SBATCH --job-name=cnv_genotyping
#SBATCH --nodes=1
#SBATCH --array=1-22
#SBATCH --cpus-per-task=1
#SBATCH --mem 30g
#SBATCH --time=10:00:00
#SBATCH --output=genotype_%a.out

module load bcftools

echo $SLURMD_NODENAME
ch=${SLURM_ARRAY_TASK_ID}
echo $ch

bam="/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/data/raw/COLO829_L/chr${ch}-COLO829_L.bam"
bed="/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/allelecount/G1000_loci_hg38/bed/G1000_loci_hg38_chr${ch}.txt"
ref="/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna"
out="/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/allelecount/vcf_cnv/normal/original/g100_chr${ch}.vcf"

bcftools mpileup -Ou $bam -R $bed -f $ref \
	--annotate FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SP,INFO/AD,INFO/ADF,INFO/ADR \
	-Q 0 \
	--threads 12 \
	| bcftools call -Ov -m --threads 12 -o $out
