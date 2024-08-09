#!/usr/bin/env nextflow

params.tumor_bam = '/u/area/ffabris/fast/long_reads_pipeline/test_data/chr1_COLO829.bam'
params.tumor_bai = '/u/area/ffabris/fast/long_reads_pipeline/test_data/chr1_COLO829.bam.bai'
params.normal_bam = '/u/area/ffabris/fast/long_reads_pipeline/test_data/chr1_COLO829_L.bam'
params.normal_bai = '/u/area/ffabris/fast/long_reads_pipeline/test_data/chr1_COLO829_L.bam.bai'
params.ref_genome = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna'
params.outdir = '/u/area/ffabris/fast/long_reads_pipeline/results/clairS/'
params.outname = 'clairs_'

process CLAIRS {
  publishDir params.outdir, mode: 'copy'
  container 'docker://hkubal/clairs:latest'

  input:
   path tumor_bam
   path normal_bam
   path ref_genome
  
  output:
   path "${params.outname}_germline.vcf", emit: 'germline_vcf'
   path "${params.outname}_somatic.vcf", emit: 'somatic_vcf'

  script:
  """
  #!/usr/bin/env bash

  echo "tumor_bam: ${tumor_bam}" > {task.workDir}/clairS.log
  echo "normal_bam: ${normal_bam}" >> {task.workDir}/clairS.log
  echo "ref_genome: ${ref_genome}" >> {task.workDir}/clairS.log
  echo "outdir: ${params.outdir}" >> {task.workDir}/clairS.log
  echo "outname: ${params.outname}" >> {task.workDir}/clairS.log

  run_clairs \
    --tumor_bam_fn=${tumor_bam} \ 
    --normal_bam_fn=${normal_bam} \
    --ref_fn=${ref_genome} \
    --threads=8 \
    --platform='ont_r9_guppy' \
    --output_dir=${params.outdir} \
    --output_prefix=${params.outname} \
    --snv_min_af=0.05 \
    --enable_clair3_germline_output \
    -c chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX
  """
}

workflow {
    tumor_bam = file(params.tumor_bam)
    normal_bam = file(params.normal_bam)
    ref_genome = file(params.ref_genome)
    clairs_ch = CLAIRS(tumor_bam, normal_bam, ref_genome)
}
