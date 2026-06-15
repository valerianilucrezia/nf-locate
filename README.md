# nf-locate pipeline
Nextflow pipeline for pre-processing long-reads data and calling allele-specific copy number and methylation events.

The pipeline can be run under 2 different settings, specified using the `shortread` parameter:
- `shortread = false`: tumor-normal matched long-read data (2 `.bam` files)
- `shortread = true`: tumor long-read and normal short-read data (2 `.bam` files)

The output files of this pipeline (`.rds` and `.csv` files) are then used by [LOCATE](https://github.com/valerianilucrezia/locate) package for inferring copy number alterations.

# Pipeline overview
The data pre-processing pipeline is composed by the following steps:
- `variant calling` (tumor and normal, via clair3 / mpileup)
- `phasing` (longphase/whatshap on the normal, haplotagging the tumor, haplotagphase on the tumor)
- `population phasing & haplotype correction` (shapeit4 + battenberg-based BAF segmentation)
- `methylation` (whatshap split + modkit + dmr)
- `locate` (downstream, see [LOCATE](https://github.com/valerianilucrezia/locate))

<img width="4300" height="1821" alt="nextflow_pipeline" src="https://github.com/user-attachments/assets/604fc289-e60e-4e57-af64-09a22e3fd0af" />

## Tools used:
- `variant_calling`
  - [clairS](https://github.com/HKU-BAL/ClairS)
  - [clairTO](https://github.com/HKU-BAL/ClairS-TO)
  - [clair3](https://github.com/HKU-BAL/Clair3)
- `pileup_phasing`
  - [mpileup](http://www.htslib.org/doc/samtools-mpileup.html)
  - [whatshap](https://github.com/whatshap/whatshap)
    - `phase`, `haplotag` and `split` commands
  - [longphase](https://github.com/twolinin/longphase)
    - `modcall` and `phase` commands (long-read branch only)
  - [shapeit4](https://github.com/odelaneau/shapeit4)
- `haplotype correction`
  - [Battenberg](https://github.com/Wedge-Oxford/battenberg) (`getMad` + `selectFastPcf` for BAF-based PCF segmentation)
- `methylation`
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

## Samplesheet
Minimal input csv file (`params.input`), validated against `assets/schema_input.json`:

```csv
sampleID,tumor_alignment,tumor_alignment_index,normal_alignment,normal_alignment_index
s1,s1_tumor.bam,s1_tumor.bam.bai,s1_normal.bam,s1_normal.bam.bai
```

| Column                   | Description                                                    |
| ------------------------ | --------------------------------------------------------------- |
| `sampleID`                | Sample identifier. _Required_                                   |
| `tumor_alignment`         | `.bam` or `.cram` of the tumor sample. _Required_                |
| `tumor_alignment_index`   | `.bai`/`.crai`/`.csi` index of the tumor alignment. _Required_  |
| `normal_alignment`        | `.bam` or `.cram` of the normal sample. _Optional_               |
| `normal_alignment_index`  | `.bai`/`.crai`/`.csi` index of the normal alignment. _Optional_ |

## Parameters

### General
| Parameter           | Default | Description                                                                                  |
| ------------------- | ------- | --------------------------------------------------------------------------------------------- |
| `input`              | `null`  | Path to the input samplesheet (CSV). _Required_                                              |
| `outdir`             | `null`  | Output directory. _Required_                                                                  |
| `shortread`          | `true`  | `true`: tumor long-read + normal short-read. `false`: tumor-normal matched long-read.        |
| `test_chromosomes`   | `null`  | Optional list of chromosomes to restrict the run to (e.g. `[21, 22]`). `null` = all of `1..22`. |
| `publish_dir_mode`   | `copy`  | Nextflow `publishDir` mode used by all processes.                                              |

### Reference genome
| Parameter     | Description                                  |
| -------------- | ----------------------------------------------- |
| `ref_genome`   | Path to the reference genome FASTA. _Required_  |
| `ref_fai`      | Path to the `.fai` index of `ref_genome`. _Required_ |

### Reference resources (dbSNP / SHAPEIT4 maps / 1000G panel)
These three parameters point to pre-downloaded reference data used for
population phasing with SHAPEIT4 (common SNPs VCF, genetic maps, 1000G phase3
GRCh38 panel). If left as `null`, the pipeline automatically downloads and
prepares them per-chromosome via the `DOWNLOAD_REFERENCES` subworkflow
(cached under `${outdir}` so subsequent runs reuse them).

| Parameter | Default | Description                                                                 |
| ---------- | ------- | ------------------------------------------------------------------------------ |
| `vcf`      | `null`  | Path to a directory of per-chromosome dbSNP common-SNPs VCFs (e.g. `chr21.vcf.gz`). If `null`, downloaded from NCBI dbSNP151. |
| `map`      | `null`  | Path to a directory of per-chromosome SHAPEIT4 genetic maps (e.g. `chr21.b38.gmap.gz`). If `null`, downloaded from [odelaneau/shapeit4](https://github.com/odelaneau/shapeit4/tree/master/maps). |
| `bcf`      | `null`  | Path to a directory of per-chromosome 1000G phase3 GRCh38 reference panel BCFs/VCFs. If `null`, downloaded from the EBI 1000genomes GRCh38 release. |

Expected file naming inside `vcf`/`map`/`bcf` when providing local paths is
per-chromosome with `chrN` in the filename (e.g. `chr21.vcf.gz`,
`chr21.b38.gmap.gz`, `chr21....vcf.gz`) — see `test_dataset/test.config` for
a working example.

### Long-read basecalling (long-read branch, `shortread = false`)
| Parameter     | Default                  | Description                                  |
| -------------- | ------------------------- | ----------------------------------------------- |
| `model_name`   | `r941_prom_sup_g5014`     | ONT basecalling model name, used by `modcall`/`modkit`. |
| `platform`     | `ont_r9_guppy`            | Platform string, used by clair3/clairS.          |


# Outputs
All outputs are written under `${outdir}`, organized per-process (see
`config/*.config` for the exact `publishDir` layout). Key outputs per
`{sampleID}` (and `{chr}` where applicable):

| Directory                         | Description                                                                                   |
| ----------------------------------- | -------------------------------------------------------------------------------------------- |
| `whatshap/`                         | Phased normal VCF (short-read branch) from `samtools mpileup` + `whatshap phase`.            |
| `longphase/`                        | Phased normal VCF (long-read branch) from `longphase modcall`/`phase`.                       |
| `haplotag/` / `haplotagphase/`      | Tumor BAM haplotagged with the normal phase, and the read-based phased tumor VCF.            |
| `shapeit4/`                         | Population-phased tumor VCF (SHAPEIT4), plus its index.                                       |
| `battenberg_phase/`                 | Tumor VCF annotated with `BAF_H1`, `BAF_H2`, `DR`, `SEGMENT_H1` INFO fields, and with `GT` corrected (haplotype-swapped) where Battenberg's PCF segmentation indicates a phase switch. This corrected VCF is also realigned so that H1 matches the normal sample's H1 frame where possible. |
| `haplotag_corrected/`               | Tumor BAM re-haplotagged using the `battenberg_phase` corrected VCF — this is the BAM used for haplotype-split methylation extraction. |
| `modkit/` / `methylation_haplotype/`| Per-haplotype methylation calls (modkit pileup) and DMR results, computed on the corrected haplotype split. |
| `pipeline_info/`                    | Nextflow execution report, timeline, trace and DAG.                                           |