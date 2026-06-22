#!/usr/bin/env nextflow

process CN_EXPAND_SEGMENTS {
    tag "${meta.sampleID}"
    label "process_low"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(cn_table), path(centromere_bed)

    output:
      tuple val(meta), path('*_cn_segments.csv'), emit: 'segments'

    script:
    def bed_arg = centromere_bed.name != 'NO_FILE' ? "--centromere-bed ${centromere_bed}" : ''
    """
    locate cn-expand-segments \
        --input ${cn_table} \
        --output ${meta.sampleID}_cn_segments.csv \
        ${bed_arg}
    """
}
