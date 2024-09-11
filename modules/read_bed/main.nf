
process READ_BED {
    tag "${meta.sampleID}-chr${meta.chr}"
    container 'docker://lvaleriani/long_reads:latest'

    input:
        tuple val(meta), path(bed)
        

    output:
        tuple val(meta), path('*.RDS'), emit: 'rds'

    script:
    """
    read_bed.R "${bed}" 
    """
}
