# nf-locate pipeline
Nextflow pipeline for pre-processing long-reads data and calling allele-specific copy number and methylation events.

The pipeline can be run under 2 different settings, specified using the `shortread` parameter:
- `shortread = false`: tumor-normal matched long-read data (2 `.bam` files)
- `shortread = true`: tumor long-read and normal short-read data (2 `.bam` files)

When `run_locate = true` (default), the pipeline also runs the [LOCATE](https://github.com/valerianilucrezia/locate) package directly as part of the workflow, performing segmentation, copy-number inference, and methylation analysis on the pipeline outputs.

# Pipeline overview
The data pre-processing pipeline is composed by the following steps:
- `somatic variant calling` (tumor vs normal, via clairS; controlled by `--run_somatic_calling`)
- `variant calling` (tumor and normal, via clair3 / mpileup)
- `phasing` (longphase/whatshap on the normal, haplotagging the tumor, haplotagphase on the tumor)
- `population phasing & haplotype correction` (shapeit4 + battenberg-based BAF segmentation)
- `methylation` (haplotype-specific: whatshap split + modkit + dmr on the corrected haplotag BAM; non-haplotype-specific: modkit + dmr on the unsplit BAMs, controlled by `--run_modkit`)
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

## Running somatic variant calling alongside the full pipeline
Somatic variant calling (`CLAIRS`) is skipped by default. To include it as part of a full pipeline run, set `--run_somatic_calling true`:
```bash
nextflow run main.nf \
 -profile <PROFILE> \
 --input <INPUT CSV> \
 --outdir <OUTPUT DIR> \
 --run_somatic_calling true
```

## Running only somatic variant calling
To run just the `CLAIRS` somatic variant calling step (tumor vs normal) without the rest of the pipeline, set `--somatic_only true`:
```bash
nextflow run main.nf \
 -profile <PROFILE> \
 --input <INPUT CSV> \
 --outdir <OUTPUT DIR> \
 --somatic_only true
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

> **Note:** boolean parameters (`shortread`, `run_locate`, `run_segmentation`, `run_somatic_calling`, `somatic_only`, `run_modkit`) must be passed as the lowercase literals `true` or `false` (e.g. `--run_locate false`), not `1`/`0` or `True`/`False`.

### General
| Parameter           | Default | Description                                                                                  |
| ------------------- | ------- | --------------------------------------------------------------------------------------------- |
| `input`              | `null`  | Path to the input samplesheet (CSV). _Required_                                              |
| `outdir`             | `null`  | Output directory. _Required_                                                                  |
| `shortread`          | `true`  | `true`: tumor long-read + normal short-read. `false`: tumor-normal matched long-read.        |
| `test_chromosomes`   | `null`  | Optional list of chromosomes to restrict the run to (e.g. `[21, 22]`). `null` = all of `1..22`. |
| `run_somatic_calling`| `false` | Run somatic variant calling (`CLAIRS`, tumor vs normal) as part of the full pipeline. Set to `true` to enable. |
| `somatic_only`       | `false` | Run only somatic variant calling (`CLAIRS`) and skip the rest of the pipeline. |
| `run_modkit`         | `false` | Run the non-haplotype-specific methylation block (`modkit` + `dmr` on the unsplit tumor/normal BAMs). Set to `true` to enable. |
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
| `locate_dp_tumor_field` | `DP_T` | INFO field extracted from the Battenberg VCF as the raw tumor depth. |
| `locate_dp_normal_field` | `DP_N` | INFO field extracted from the Battenberg VCF as the raw normal depth. |
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
| `methylation_lr` | `1e-2` | Adam learning rate for methylation SVI. |
| `methylation_steps` | `6000` | SVI iterations for methylation inference. |
| `asm_a` | `1.0` | Beta prior shape $a$ for ASM analysis. |
| `asm_b` | `1.0` | Beta prior shape $b$ for ASM analysis. |
| `asm_pi` | `0.5` | Prior probability of ASM ($H_1$). |
| `asm_n_draws` | `200` | Latent tumour-only count realizations drawn per site for the ASM Bayes-factor confidence interval. |

> **LOCATE steps run at the granularity their statistics require, not
> uniformly per chromosome.** `PREPARE_TABLE_VCF` and segmentation still run
> per chromosome (parallelized across the pipeline as before), but depth-
> ratio normalization and copy-number inference operate genome-wide: BAF/DR
> tables from all chromosomes for a sample are concatenated and DR is
> renormalized once across the whole genome before `CN_INFERENCE` runs, and
> `MERGE_BREAKPOINTS` combines every chromosome's segmentation output (with
> a forced breakpoint at each chromosome's start) into one genome-wide
> breakpoint prior. This matters because DR is a ratio normalized by its own
> mean — normalizing it one chromosome at a time silently erases real
> whole-chromosome gains/losses, and CN segments must never span two
> physically unrelated chromosomes. These fixes live in the shared `locate`
> library (`prepare-table renormalize-dr`, `prepare-table
> merge-breakpoints`'s chromosome-boundary forcing, and a corrected
> multivariate ClaSP recursion that no longer misses transitions on
> "sandwich" BAF/DR patterns) — this pipeline picks them up automatically
> once its container/environment is rebuilt against a `locate` version that
> includes them, no workflow changes required. Haplotype methylation tables
> (`PREPARE_TABLE_METHYLATION`) can additionally be built with tumour/normal
> H1-H2 orientation correction (`locate prepare-table from-bed
> --tumor-vcf/--normal-vcf`); wiring the required phased VCF inputs through
> this subworkflow is planned but not yet done, so methylation tables
> currently do not benefit from this correction.

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
| `battenberg_phase/`                 | Tumor VCF annotated with `BAF_H1`, `BAF_H2`, `DP_T`, `DP_N`, `SEGMENT_H1` INFO fields, and with `GT` corrected (haplotype-swapped) where Battenberg's PCF segmentation indicates a phase switch. This corrected VCF is also realigned so that H1 matches the normal sample's H1 frame where possible. `DP_T`/`DP_N` are raw, un-normalized per-position depths -- a genome-wide-normalized depth ratio must be derived downstream once all chromosomes for a sample are combined. |
| `haplotag_corrected/`               | Tumor BAM re-haplotagged using the `battenberg_phase` corrected VCF — this is the BAM used for haplotype-split methylation extraction. |
| `modkit/` / `methylation_haplotype/`| Per-haplotype methylation calls (modkit pileup) and DMR results, computed on the corrected haplotype split. |
| `pipeline_info/`                    | Nextflow execution report, timeline, trace and DAG.                                           |
| `locate/{sampleID}/tables/`         | Per-chromosome BAF/DP_T/DP_N tables (from Battenberg VCF, unnormalized DR) plus a genome-wide-concatenated, DR-renormalized table for the sample, and haplotype methylation tables (from modkit bedMethyl). Produced only when `run_locate = true`. |
| `locate/{sampleID}/segmentation/`   | Per-chromosome change-point CSVs from multivariate ClaSP, plus a merged genome-wide breakpoint CSV (with a forced breakpoint at every chromosome start). Produced only when `run_locate = true` and `run_segmentation = true`. |
| `locate/{sampleID}/cn/`             | Genome-wide copy-number inference results (`CN_Major`, `CN_minor`, `states`, `purity`, `ploidy`) plus a one-row `*_purity_ploidy.csv` summary. Produced only when `run_locate = true`. |
| `locate/{sampleID}/methylation/`    | Per-chromosome betaT summaries (`betaT_h1/h2_med/lo/hi`) and ASM results on the inferred tumour-only counts (`BF10_med/lo/hi`, `P_ASM_med/lo/hi`, `asm_call`). Tumour purity (`rho`) is read per sample from `locate/{sampleID}/cn/`'s purity estimate, not a fixed pipeline-wide value, since methylation samples are necessarily contaminated by normal tissue at differing rates. Produced only in the long-read branch when `run_locate = true`. |