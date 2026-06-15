#!/usr/bin/env nextflow

process DOWNLOAD_MAP {
    label "process_low"
    label "error_retry"
    container 'https://depot.galaxyproject.org/singularity/bcftools%3A1.17--haef29d1_0'

    output:
      path("chr*.b38.gmap_CHR.gz"), emit: 'map'

    script:
    """
    wget -O genetic_maps.b38.tar.gz "https://raw.githubusercontent.com/odelaneau/shapeit4/master/maps/genetic_maps.b38.tar.gz"
    tar -xzf genetic_maps.b38.tar.gz
    for chr in chr{1..22}; do
        mv "\${chr}.b38.gmap.gz" "\${chr}.b38.gmap_CHR.gz"
    done
    rm genetic_maps.b38.tar.gz chrX*.b38.gmap.gz
    """
}
