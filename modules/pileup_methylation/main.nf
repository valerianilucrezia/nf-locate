process METH_PILEUP {
    tag "${name}-chr${ch}"
    publishDir "${workflow.launchDir}/results/pileup_meth/", mode: 'copy'
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'
    memory '100 GB'
    cpus 12
    time '24h'

    input:
    tuple val(name), val(ch), path(chr_bed), path(chr_bam), path(chr_bai), path(ref), path(fai)
  
    output:
    tuple val(ch), val(name), path('*.vcf'), emit:'chr_vcf'

    script:
    """
    #!/bin/bash -ue
    bcftools mpileup -Ou \
        -f ${ref} ${chr_bam} \
        -R ${chr_bed} \
        -Q 0 \
        --threads 12 \
        --annotate FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SP,INFO/AD,INFO/ADF,INFO/ADR | bcftools call -Ov -m --threads 12 -o missing_tumor_chr${ch}.vcf
    """
}
