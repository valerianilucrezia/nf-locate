
process READ_BED {
    tag "${name}-chr${chr}"
    container 'docker://lvaleriani/long_reads:latest'

    input:
        tuple val(chr), val(name), path(bed)
        

    output:
        tuple val(chr), val(name), path('*.RDS'), emit: 'chr_rds'

    script:
    """
        #!/usr/bin/env bash
        read_bed.R "${chr}" "${bed}" "${name}_chr${chr}" 
    """
}
