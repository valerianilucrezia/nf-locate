# locate-nf-pipeline
Nextflow pipeline for pre-processing long-reads data, under 3 different setting:
- Tumor-Normal matched long-reads data (2 `.bam` files)
- Tumor-only long-reads data (1 `.bam` file)
- Tumor long-reads and Normal short-reads data (2 `.bam` files)

The output files of this pipeline (`.rds` and `.csv` files) are then used by [LOCATE](https://github.com/valerianilucrezia/locate) package for inferring copy number alterations.

# Pipeline overview   
The pipeline is composed by 3 parallel workflows:
- `variant_calling`
- `methylation_calling`
- `pileup`

<img width="863" alt="Screenshot 2024-09-10 alle 16 51 49" src="https://github.com/user-attachments/assets/714b6b90-61ea-4dd7-ba7a-8bcdbab70686">


# How to run the pipeline
### Samplesheet
