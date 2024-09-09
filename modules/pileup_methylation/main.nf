process METH_PILEUP {
    tag "${meta.sampleID}-${meta.type}-chr${meta.chr}"
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'

    input:
    tuple val(meta), path(bam), path(bai), path(bed), path(ref), path(fai)
  
    output:
    tuple val(meta), path('*.vcf'), emit:'vcf'

    script:
    """
    #!/bin/bash -ue
    bcftools mpileup -Ou \
        -f ${ref} \
        ${bam} \
        -R ${bed} \
        -Q 0 \
        --threads 12 \
        --annotate FORMAT/AD,FORMAT/ADF,FORMAT/ADR,FORMAT/DP,FORMAT/SP,INFO/AD,INFO/ADF,INFO/ADR | bcftools call -Ov -m --threads 12 -o ${meta.sampleID}_chr${meta.chr}_${meta.type}.vcf
    """
}
