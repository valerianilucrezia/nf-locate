# nf-locate pipeline
Nextflow pipeline for pre-processing long-reads data and calling allele-specific copy number and methylation events.

The pipeline can be runned under 3 different setting, specified using the `sample` parameter:
- `nanopore`: tumor-normal matched long-read data (2 `.bam` files)
- `tumor-only`: tumor-only long-reads data (1 `.bam` file)
- `mix`: tumor long-read and normal short-read data (2 `.bam` files)


The output files of this pipeline (`.rds` and `.csv` files) are then used by [LOCATE](https://github.com/valerianilucrezia/locate) package for inferring copy number alterations.

# Pipeline overview   
The data pre-processing pipeline is composed by 3 workflows:
- `variant_calling`
- `pileup_phasing` that contains also the `longphase` workflow
- `methylation`
- `locate`

The final `locate` workflow is meant for collecting and smoothing data and finally running [LOCATE](https://github.com/valerianilucrezia/locate) tool.


<img width="4300" height="1821" alt="nextflow_pipeline" src="https://github.com/user-attachments/assets/604fc289-e60e-4e57-af64-09a22e3fd0af" />

## Tools used:
- `variant_calling`
  - [clairS](https://github.com/HKU-BAL/ClairS)
  - [clairTO](https://github.com/HKU-BAL/ClairS-TO)
- `pileup_phasing`
  - [mpileup](http://www.htslib.org/doc/samtools-mpileup.html)
  - [longphase](https://github.com/twolinin/longphase)
    - `modcall` and `phase` commands
  - [shapeit4](https://github.com/odelaneau/shapeit4)
  - [Sniffles2](https://github.com/fritzsedlazeck/Sniffles)
- `methylation`
  - [whatshap](https://github.com/whatshap/whatshap)
    - `haplotag` and `split` commands
  - [modkit](https://github.com/nanoporetech/modkit)
    - `pileup` and `dmr` commands
- `locate`
  - [LOCATE](https://github.com/valerianilucrezia/locate) 



# How to run the pipeline
```bash
nextflow run main.nf \
 -profile <PROFILE> \
 --input <INPUT CSV> \
 --outdir <OUTPUT DIR>
```

### Samplesheet
Minimal input csv file:

```bash
sample,tumor_alignment,tumor_alignment_index
s1,s1.bam,s1.bam.bai
```

| Column    | Description                                                                                                                                                                                                                                                                                                                       |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sampleID` |  name of the tumor sample <br /> _Required_                                                                                      |
| `tumor_alignment` | .bam or .cram of tumor sample <br /> _Required_                                                                                                                                |
| `tumor_alignment_index`  |  .bai or .crai of tumor sample <br /> _Required_                                              |
| `normal_alignment`  |     .bam or .cram of normal sample            <br /> _Optional_                                                                                                                                |
| `normal_alignment_index`  |        .bai or .crai of normal sample <br /> _Optional_                                                                                                                                      |                                           |


### Parameters
- `ref_genome`
- `ref_fai`
- `bed`
- `map`
- `bcf`

