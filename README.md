# LR_Pipeline_DNA

![lr_pipeline](https://github.com/valerianilucrezia/LR_Pipeline_DNA/assets/72545549/d3d15afb-fb25-414a-9502-349d177d68cd)

N/T = Normal and Tumor **Separately**

NT = Normal and Tumor **Together**

## Methylation Workflow
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

7. `5_combine.R`: N/T
    
     **In parallel for each chromosome {c}**
    - input:
      - `chr{c}_{sample}_meth.rds`
      - `chr{c}_{sample}.vcf`
        
    - output: `chr{c}_{sample}_MAF.rds`

## Pileup Workflow
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

3. `3_read_vcf.R`: N/T
    
     **In parallel for each chromosome {c}**
    - input: `chr{c}_{sample}.vcf`
    - output: `chr{c}_{sample}.rds`
  

## Variant Calling Workflow
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
  
