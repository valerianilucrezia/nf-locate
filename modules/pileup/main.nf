
params.outdir = "${workflow.launchDir}/results/"
params.bam_data = '/u/area/ffabris/fast/long_reads_pipeline/test_data/'
params.ref_genome = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna'
params.bam_data="/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/data/raw/COLO829_L/"
params.bed_data="/u/area/ffabris/fast/long_reads_pipeline/test_data/pos/"

chr_ch = Channel.from(1..22)
bam_ch = Channel.fromPath("${params.bam_data}*.bam", checkIfExists: true) 
bed_ch = Channel.fromPath("${params.bam_data}*.txt", checkIfExists: true) 
ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 

bam_ch = chr_ch.map { ch ->
    def bamFile = file("${params.bam_data}chr${ch}-COLO829_L.bam")
    [ch, bamFile]
}


process PILEUP_CN {
    tag "chr${ch}"
    publishDir "${params.outdir}pileup_cn/", mode: 'copy'
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.9--ha228f0b_4'
    memory '30 GB'
    maxForks 12

    input:
      val ch
      path sample_bam
      path sample_bed
      path ref

    output:
      path '*.vcf', emit: 'vcf' 

    script:
      """
      OUTPUT_VCF="g100_chr${ch}.vcf"

      bcftools mpileup -Ou ${sample_bam} -R ${sample_bed} -f ${ref} \
        --annotate FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SP,INFO/AD,INFO/ADF,INFO/ADR \
        -Q 0 \
        --threads 12 \
        | bcftools call -Ov -m --threads 12 -o \$OUTPUT_VCF
      """
}