# locate-nf-pipeline
Nextflow pipeline for pre-processing long-reads data, under 3 different setting:
- Tumor-Normal matched long-reads data (`.bam` files)
- Tumor-only long-reads data (`.bam` files)
- Tumor long-reads and Normal short-reads data (`.bam` files)

The output files of this pipeline (`.rds` and `.csv` files) are then used by [LOCATE](https://github.com/valerianilucrezia/locate) package for inferring copy number alterations.

# Pipeline overview   
The pipeline is composed by 3 parallel workflows:
- `variant_calling`
- `methylation_calling`
- `pileup`

<img width="958" alt="Screenshot 2024-07-08 alle 15 58 52" src="https://github.com/valerianilucrezia/LR_Pipeline_DNA/assets/72545549/04d31099-6b46-4df9-b404-ff0bb555ec14">

