# LR_Pipeline_DNA
<img width="958" alt="Screenshot 2024-07-08 alle 15 58 52" src="https://github.com/valerianilucrezia/LR_Pipeline_DNA/assets/72545549/04d31099-6b46-4df9-b404-ff0bb555ec14">


N/T = Normal and Tumor **Separately**

NT = Normal and Tumor **Together**

## `methylation_calling` workflow
1. `1_modkit.sh`: N/T
    - input: `{sample}.bam`
    - output: `{sample}.bed`
    - reference file
    
2. `2_get_position.sh`: N/T

   **In parallel for each chromosome {c}**
   - input: `{sample}.bed`
   - output: `chr{c}_{sample}.bed`

 3. `3_pileup.sh`: N/T
    
    **In parallel for each chromosome {c}**
    - input:
      - `chr{c}_{sample}.bed`
      - `{sample}.bam`
    - output: `chr{c}_{sample}.vcf`

 6. `4_read_bed.R`: N/T
    
     **In parallel for each chromosome {c}**
    - input: `{sample}.bed`
    - output: `chr{c}_{sample}_meth.rds`

7. `5_combine.R`: NT
    
     **In parallel for each chromosome {c}**
    - input:
      - `T_chr{c}_{sample}_meth.rds`
      - `T_chr{c}_{sample}.vcf`
      - `N_chr{c}_{sample}_meth.rds`
      - `N_chr{c}_{sample}.vcf`
        
    - output: `chr{c}_{sample}_MAF.rds`

## `pileup` workflow
1. `1_split_bam.sh`: N/T
    - input: `{sample}.bam`
    - output:
      - `chr{c}_{sample}.bam`
      - `chr{c}_{sample}.bai`

2. `2_pileup.sh`: N/T
    
     **In parallel for each chromosome {c}**
    - input:
      - `chr{c}_{sample}.bam`
      - `chr{c}_pos.bed`
    - output: `chr{c}_{sample}.vcf`

3. `3_whatshap.R`: N/T
    
     **In parallel for each chromosome {c}**
    - input:
        - `chr{c}_{sample}.bam`
        - `chr{c}_{sample}.vcf`
    - output:  `phased_chr{c}_{sample}.vcf`
  
4. `4_read_vcf_phasing.R`: N/T
    
     **In parallel for each chromosome {c}**
    - input:   `phased_chr{c}_{sample}.vcf`
    - output:  `phased_chr{c}_{sample}.rds`
  

## `variant_calling` workflow
1. `1_clairS.sh`: NT
    - input:
      - `T_{sample}.bam`
      - `N_{sample}.bam`
    - output:
      - `somatic_{sample}.vcf`
      - `T_germline_{sample}.vcf`
      - `N_germline_{sample}.vcf`
    - reference file

2. `2_read_vcf.R`: NT
   - input: `somatic_{sample}.vcf`
   - output: `somatic_{sample}.rds`
  
