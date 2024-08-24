
params.rscript = "/u/area/ffabris/fast/long_reads_pipeline/LR_Pipeline_DNA/bin/read_bed.R"
params.bed_data="${workflow.launchDir}/results/modkit/COLO829.bed"

rscript_ch = Channel.fromPath(params.rscript, checkIfExists: true) 
chr_ch = Channel.from(1..22)
bed_ch = Channel.fromPath(params.bed_data, checkIfExists: true) 

combined_ch = rscript.combine(chr_ch.combine(bed_ch))

process READ_BED {
    publishDir "${workflow.launchDir}/results/read_bed/", mode: 'copy'
    container 'docker://lvaleriani/long_reads:latest'
    memory '16 GB'

    input:
        tuple path(rscript), val(chr), path(bed_file)
        

    output:
        path '*.RDS', emit: 'RDS'

    script:
    """
        #!/usr/bin/env bash
        Rscript "${rscript}"  "${chr}" "${bed_file}" "COLO829" 
    """
}

workflow {
    READ_BED(combined_ch)
}
