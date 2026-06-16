# nf-locate pipeline
Nextflow pipeline for pre-processing long-reads data and calling allele-specific copy number and methylation events.

The pipeline can be run under 2 different settings, specified using the `shortread` parameter:
- `shortread = false`: tumor-normal matched long-read data (2 `.bam` files)
- `shortread = true`: tumor long-read and normal short-read data (2 `.bam` files)

When `run_locate = true` (default), the pipeline also runs the [LOCATE](https://github.com/valerianilucrezia/locate) package directly as part of the workflow, performing segmentation, copy-number inference, and methylation analysis on the pipeline outputs.

# Pipeline overview
The data pre-processing pipeline is composed by the following steps:
- `variant calling` (tumor and normal, via clair3 / mpileup)
- `phasing` (longphase/whatshap on the normal, haplotagging the tumor, haplotagphase on the tumor)
- `population phasing & haplotype correction` (shapeit4 + battenberg-based BAF segmentation)
- `methylation` (whatshap split + modkit + dmr)
- `locate` (segmentation → copy-number inference → methylation inference + ASM, via [LOCATE](https://github.com/valerianilucrezia/locate); controlled by `--run_locate`)

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

### LOCATE inference

These parameters control the integrated [LOCATE](https://github.com/valerianilucrezia/locate) subworkflow (`LOCATE_CN` + `LOCATE_METHYLATION`). Set `run_locate = false` to skip all LOCATE steps and produce only the upstream pipeline outputs.

| Parameter | Default | Description |
| --------- | ------- | ----------- |
| `run_locate` | `true` | Run the LOCATE subworkflow (segmentation + CN inference + methylation inference + ASM). Set to `false` to skip. |
| `run_segmentation` | `true` | Run multivariate ClaSP segmentation before CN inference and pass breakpoints as a prior. Set to `false` to run CN inference without a segmentation prior. |
| `locate_baf_field` | `BAF_H1` | INFO field extracted from the Battenberg VCF as the BAF signal. |
| `locate_dr_field` | `DR` | INFO field extracted from the Battenberg VCF as the depth ratio signal. |
| `segmentation_mode` | `max` | ClaSP score combination mode (`max`, `sum`, `mult`). |
| `segmentation_frequencies` | `vaf,baf,dr` | Comma-separated signal columns used for segmentation. |
| `segmentation_window_size` | `suss` | ClaSP window size method (`suss`, `fft`, `acf`) or an integer. |
| `cn_steps` | `2000` | SVI optimisation steps for CN inference. |
| `cn_lr` | `0.05` | Adam learning rate for CN inference. |
| `cn_guide` | `delta` | Variational guide: `delta` (MAP) or `normal` (mean-field). |
| `cn_hidden_dim` | `3` | Number of CN states per allele. |
| `cn_prior_purity` | `0.9` | Prior tumour purity. |
| `cn_prior_ploidy` | `2.0` | Prior tumour ploidy. |
| `cn_bp_strength` | `3.0` | Strength of the breakpoint prior on HMM transition logits. |
| `cn_min_seg_len` | `1` | Minimum consecutive positions for a CN state run (post-processing). |
| `methylation_model` | `binomial` | Likelihood for betaT inference: `binomial` or `betabinom`. |
| `methylation_rho` | `0.6` | Tumour contamination fraction for methylation inference. |
| `methylation_lr` | `1e-2` | Adam learning rate for methylation SVI. |
| `methylation_steps` | `6000` | SVI iterations for methylation inference. |
| `asm_a` | `1.0` | Beta prior shape $a$ for ASM analysis. |
| `asm_b` | `1.0` | Beta prior shape $b$ for ASM analysis. |
| `asm_pi` | `0.5` | Prior probability of ASM ($H_1$). |
| `asm_alpha` | `0.05` | Credible interval level for ASM. |

### Long-read basecalling
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
| `locate/{sampleID}/tables/`         | Per-chromosome BAF/DR tables (from Battenberg VCF) and haplotype methylation tables (from modkit bedMethyl). Produced only when `run_locate = true`. |
| `locate/{sampleID}/segmentation/`   | Per-chromosome change-point CSVs from multivariate ClaSP. Produced only when `run_locate = true` and `run_segmentation = true`. |
| `locate/{sampleID}/cn/`             | Per-chromosome copy-number inference results (`CN_Major`, `CN_minor`, `states`, `purity`, `ploidy`). Produced only when `run_locate = true`. |
| `locate/{sampleID}/methylation/`    | Per-chromosome betaT summaries (`betaT_h1/h2_med/lo/hi`) and ASM results (`BF10`, `P_ASM`, `asm_call`). Produced only in the long-read branch when `run_locate = true`. |