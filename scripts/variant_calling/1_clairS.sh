#!/bin/bash
#SBATCH --partition=EPYC
#SBATCH --job-name=clairS
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --mem 50g
#SBATCH --time=48:00:00

run_clairs \
    --tumor_bam_fn=$tumour \
    --normal_bam_fn=$germline \
    --ref_fn=$ref \
    --threads=8 \
    --platform="ont_r9_guppy" \
    --output_dir=outdir \
    --output_prefix=outname \
    --snv_min_af=0.05 \
    --enable_clair3_germline_output \
    -c chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX
