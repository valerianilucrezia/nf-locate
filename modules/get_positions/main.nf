params.bed_data="${workflow.launchDir}/results/modkit/COLO829.bed"

chr_ch = Channel.from(1..22)
bed_ch = Channel.fromPath(params.bed_data, checkIfExists: true) 
combined_ch = chr_ch.combine(bed_ch)

process GET_POSITIONS {
    tag "chr${ch}"
    publishDir "${workflow.launchDir}/results/get_positions/", mode: 'copy'
    container 'docker://lvaleriani/long_reads:latest'
    memory '20 GB'

    input:
    tuple val(ch), path(bed)
   
  
    output:
    path '*.bed', emit:'bed'

    script:
    """
    cat "${bed}" | grep -w "chr${ch}" | grep -v "random" | awk '{print \$1, \$3}' > "chr${ch}"_COLO829_meth.bed
    """
}

workflow {
    get_positions_ch = GET_POSITIONS(combined_ch)
}