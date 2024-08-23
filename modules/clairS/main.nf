#!/usr/bin/env nextflow

process CLAIRS {
  publishDir "${workflow.launchDir}/results/clairS/", mode: 'copy'
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
    path '*.vcf.gz', emit: 'vcf' 
    path '*.tbi', emit: 'tbi'

 script:
    """
    #!/usr/bin/env bash
    
    run_clairs \
    --tumor_bam_fn="${tumor_bam}" \
    --normal_bam_fn="${normal_bam}"\
    --ref_fn="${ref_genome}"\
    --threads="${task.cpus}" \
    --platform="ont_r9_guppy" \
    --output_dir="" \
    --output_prefix="variants" \
    --snv_min_af=0.05 \
    --enable_clair3_germline_output \
    -c chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX
    """
}
