#!/usr/bin/env nextflow

params.tumor_bam = '/u/area/ffabris/fast/long_reads_pipeline/test_data/full_chr1_COLO829.bam'
params.tumor_bai = '/u/area/ffabris/fast/long_reads_pipeline/test_data/full_chr1_COLO829.bam.bai'
params.normal_bam = '/u/area/ffabris/fast/long_reads_pipeline/test_data/full_chr1_COLO829_L.bam'
params.normal_bai = '/u/area/ffabris/fast/long_reads_pipeline/test_data/full_chr1_COLO829_L.bam.bai'
params.ref_genome = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna'
params.ref_fai = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai'

params.outdir = "${workflow.launchDir}/results/clairS/"

tumor_bam_ch = Channel.fromPath(params.tumor_bam, checkIfExists: true) 
tumor_bai_ch = Channel.fromPath(params.tumor_bai, checkIfExists: true) 
normal_bam_ch = Channel.fromPath(params.normal_bam, checkIfExists: true) 
normal_bai_ch = Channel.fromPath(params.normal_bai, checkIfExists: true) 
ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 
ref_fai_ch = Channel.fromPath(params.ref_fai, checkIfExists: true)

process CLAIRS {
  publishDir params.outdir, mode: 'copy'
  container 'docker://hkubal/clairs:latest'
  cpus 8
  memory '200 GB'
  maxForks 24
  time '2h'

  input:
   path tumor_bam
   path tumor_bai
   path normal_bam
   path normal_bai
   path ref_genome
   path ref_fai

  output:
   path 'variants.vcf.gz', emit: 'vcf_files'


script:
    """
    #!/usr/bin/env bash
    
    run_clairs \
    --tumor_bam_fn="${tumor_bam}" \
    --normal_bam_fn="${normal_bam}"\
    --ref_fn="${ref_genome}"\
    --threads="${task.cpus}" \
    --platform="ont_r9_guppy" \
    --output_dir="${params.outdir}" \
    --output_prefix="variants" \
    --snv_min_af=0.05 \
    --enable_clair3_germline_output \
    -c chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX
    """
}

workflow {
    clairs_ch = CLAIRS(tumor_bam_ch, tumor_bai_ch, normal_bam_ch, normal_bai_ch, ref_genome_ch, ref_fai_ch)
}
