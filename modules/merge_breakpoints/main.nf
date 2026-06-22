#!/usr/bin/env nextflow

process MERGE_BREAKPOINTS {
    tag "${meta.sampleID}"
    label "process_low"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      tuple val(meta), path(offsets), path(chrom_tables), path(breakpoints)

    output:
      tuple val(meta), path('*_breakpoints.csv'), emit: 'breakpoints'

    script:
    """
    mkdir -p tables_dir
    for f in ${chrom_tables}; do ln -s "\$(readlink -f \$f)" tables_dir/; done

    locate prepare-table merge-breakpoints \
        --offsets ${offsets} \
        --breakpoints ${breakpoints} \
        --tables-dir tables_dir \
        --output ${meta.sampleID}_breakpoints.csv
    """
}
