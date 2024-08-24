## To do
### General
- [ ] write `main.nf` workflow
- [x] add singularity images


### `variant_calling`
- [x] write `main.nf` of the sub-workflow `subworkflows/variant_calling/main.nf`
- [x] write `modules/clairS/main.nf` using `scripts/variant_calling/1_clairS.sh`
- [x] write `modules/read_vcf/main_somatic.nf` using `scripts/variant_calling/2_read_vcf_somatic.R`

### `pileup`
- [x] take `.bed` input files from `scripts/pileup/hg38_positions.zip`

- [ ] write `main.nf` of the sub-workflow `subworkflows/pileup/main.nf`
- [x] write `modules/split_bam/main.nf` using `scripts/pileup/1_split_bam.sh`
- [x] write `modules/pileup/main.nf` using `scripts/pileup/2_pileup.sh`
- [ ] write `modules/whatshap/main.nf` using `scripts/pileup/3_whatshap.sh`
- [ ] write `modules/read_vcf/main.nf` using `scripts/pileup/4_read_vcf_phasing.sh`

### `methylation_calling`
- [ ] write `main.nf` of the sub-workflow `subworkflows/methylation/main.nf`
- [x] write `modules/modkit/main.nf` using `scripts/methylation/1_modkit.sh`
- [ ] write `modules/get_positions/main.nf` using `scripts/methylation/2_get_position.sh`
- [ ] write `modules/pileup_methylation/main.nf` using `scripts/methylation/3_pileup.sh`
- [ ] write `modules/read_bed/main.nf` using `scripts/methylation/4_read_bed.R`
- [ ] write `modules/combine_methylation/main.nf` using `scripts/methylation/5_combine.R`
