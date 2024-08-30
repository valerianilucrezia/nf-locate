params.ref_genome = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna'
params.ref_fai = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai'
params.bam_data = '/u/area/ffabris/fast/long_reads_pipeline/tests/pielup_pipeline/results/split_bam'
params.bed_data = "${workflow.launchDir}/results/get_positions"

chr_ch = chr_ch = Channel.from(1) //Channel.from(1..22)
bam_ch = Channel.fromPath(params.bam_data, checkIfExists: true) 
bed_ch = Channel.fromPath(params.bed_data, checkIfExists: true) 
ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 
ref_fai_ch = Channel.fromPath(params.ref_fai, checkIfExists: true) 

combined_ch = chr_ch
                .combine(bam_ch)
                .combine(bed_ch)
                .combine(ref_genome_ch)
                .combine(ref_fai_ch)


process METH_PILEUP {
    tag "chr${ch}"
    publishDir "${workflow.launchDir}/results/pileup_meth/", mode: 'copy'
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'
    memory '100 GB'
    cpus 12
    time '24h'

    input:
    tuple val(ch), path(bam), path(bed), path(ref), path(fai)
  
    output:
    path('*.vcf'), emit:'vcf'

    script:
    """
    #!/bin/bash -ue
    bcftools mpileup -Ou \
        -f ${ref} ${bam}/chr${ch}-COLO829.bam \
        -R ${bed}/chr${ch}_COLO829_meth.bed \
        -Q 0 \
        --threads 12 \
        --annotate FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SP,INFO/AD,INFO/ADF,INFO/ADR | bcftools call -Ov -m --threads 12 -o missing_tumor_chr${ch}.vcf
    """
}


workflow {
    pileup_met_ch = METH_PILEUP(combined_ch)
}
