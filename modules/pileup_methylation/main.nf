params.ref_genome = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna'
params.ref_fai = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai'
params.bam = '/u/area/ffabris/fast/long_reads_pipeline/tests/pielup_pipeline/results/split_bam/'
params.bed = "${workflow.launchDir}/results/get_positions/"

// chr_ch = Channel.from(1..22)
chr_ch = Channel.from(1..9)
bam_ch = Channel.fromPath(params.bam_data, checkIfExists: true) 
bed_ch = Channel.fromPath(params.bed_data, checkIfExists: true) 
ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 

combined_ch = chr_ch.combine(bam_ch.combine(bed_ch).combine(ref_genome_ch))


process PILEUP_METH {
    tag "chr${ch}"
    publishDir "${workflow.launchDir}/results/pileup_meth", mode: 'copy'
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.9--ha228f0b_4'
    memory '30 GB'
    cpus 24
    time '24h'

    input:
    tuple val(ch), path(bam), path(bed), path (ref)
  
    output:
    path "*.vcf", emit:'vcf'

    script:
    """
    bcftools mpileup -Ou -f "${ref_genome}" "${bam}/chr${ch}-COLO829.bam"" -R "${bed}/chr${ch}_tumor_meth.bed" \
    -Q 0 \
    --threads 24 \
    --annotate FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SP,INFO/AD,INFO/ADF,INFO/ADR \
          | bcftools call -Ov -m --threads 24 -o "missing_tumor_chr${ch}.vcf"
    """
}

workflow {
    pileup_met_ch = PILEUP_METH(combined_ch)
}
