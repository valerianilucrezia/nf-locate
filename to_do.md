## To do
### General
- [x] write `main.nf` workflow
- [x] add singularity images
- [ ] need to change `modules/read_vcf/main.nf`to perform the correct tasks (use the corresponding  script on the bin dir)
- [ ] need to chanche `modules/combine_methylation/main.nf` to perform the correct tasks (use the corresponding  script on the bin dir)
- [x] get a *testing dataset*
- [ ] tune general HPC default parameters
- [ ] test the pipelines with 2 datasets
- [ ] see the output names -- for the moment I think that the only problem is 'read_phasing', and maybe 'pileup meth'?


### `variant_calling`
- [x] write `main.nf` of the sub-workflow `subworkflows/variant_calling/main.nf`
- [x] write `modules/clairS/main.nf` using `scripts/variant_calling/1_clairS.sh`
- [x] write `modules/read_vcf/main_somatic.nf` using `scripts/variant_calling/2_read_vcf_somatic.R`

### `pileup`
- [x] take `.bed` input files from `scripts/pileup/hg38_positions.zip`

- [x] write `main.nf` of the sub-workflow `subworkflows/pileup/main.nf`
- [x] write `modules/split_bam/main.nf` using `scripts/pileup/1_split_bam.sh`
- [x] write `modules/pileup/main.nf` using `scripts/pileup/2_pileup.sh`
- [x] write `modules/whatshap/main.nf` using `scripts/pileup/3_whatshap.sh`
- [x] write `modules/read_vcf/main.nf` using `scripts/pileup/4_read_vcf_phasing.sh`

### `methylation_calling`
- [x] write `main.nf` of the sub-workflow `subworkflows/methylation/main.nf`
- [x] write `modules/modkit/main.nf` using `scripts/methylation/1_modkit.sh`
- [x] write `modules/get_positions/main.nf` using `scripts/methylation/2_get_position.sh`
- [x] write `modules/pileup_methylation/main.nf` using `scripts/methylation/3_pileup.sh`
- [x] write `modules/read_bed/main.nf` using `scripts/methylation/4_read_bed.R`
- [x] write `modules/combine_methylation/main.nf` using `scripts/methylation/5_combine.R`


