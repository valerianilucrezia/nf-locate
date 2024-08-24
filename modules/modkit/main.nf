#!/usr/bin/env nextflow

params.bam = '/u/area/ffabris/fast/long_reads_pipeline/test_data/full_chr1_COLO829.bam'
params.bai = '/u/area/ffabris/fast/long_reads_pipeline/test_data/full_chr1_COLO829.bam.bai'
params.ref_genome = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna'
params.ref_fai = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai'

bam_ch = Channel.fromPath(params.bam, checkIfExists: true) 
bai_ch = Channel.fromPath(params.bai, checkIfExists: true) 
ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 
ref_fai_ch = Channel.fromPath(params.ref_fai, checkIfExists: true)


process MODKIT {
    publishDir "${workflow.launchDir}/results/modkit/", mode: 'copy'
    container 'https://depot.galaxyproject.org/singularity/ont-modkit%3A0.3.1--h5c23e0d_1'
    cpus 12
    memory '100 GB'
    time '12h'

    
    input:
      path bam
      path bai
      path ref_genome
      path ref_fai    
   
    output:
      path '*.bed', emit: 'bed' 
      path '*.log', emit: 'log'

    script:
    """
    modkit pileup "${bam}" "COLO829.bed" --ignore h --ref "${ref_genome}" --cpg --combine-strands --log-filepath "COLO829_pileup.log" -t 24
    modkit pileup "${bam}" "COLO829_bystrand.bed" --ignore h --ref "${ref_genome}" --log-filepath "COLO829_pileup_bystrand.log" -t 12
    """
}

workflow {
    modkit_ch = MODKIT(bam_ch, bai_ch, ref_genome_ch, ref_fai_ch)
}