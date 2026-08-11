#!/usr/bin/env nextflow

process MERGE_BREAKPOINTS {
    tag "${meta.sampleID}"
    label "process_low"
    label "error_retry"
    // TODO: container with the `locate` package installed (provides the `locate` CLI)
    container 'TODO/locate:1.0.0'

    input:
      // binned_chrom_tables is optional (pass an empty list / NO_FILE when
      // segmentation ran directly on the unbinned chrom_tables) -- when
      // present, it's BIN_TABLE's output, needed to translate each
      // change_point from a binned-table row index back to the unbinned-
      // table row index where that bin starts (see prepare-table
      // merge-breakpoints's --binned-tables-dir docstring).
      tuple val(meta), path(offsets), path(chrom_tables), path(breakpoints), path(binned_chrom_tables)

    output:
      tuple val(meta), path('*_breakpoints.csv'), emit: 'breakpoints'

    script:
    def has_binned = binned_chrom_tables.findAll { it.name != 'NO_FILE' }
    def binned_arg = has_binned ? '--binned-tables-dir binned_tables_dir' : ''
    """
    mkdir -p tables_dir
    for f in ${chrom_tables}; do ln -s "\$(readlink -f \$f)" tables_dir/; done

    ${has_binned ? "mkdir -p binned_tables_dir\nfor f in ${has_binned.join(' ')}; do ln -s \"\$(readlink -f \$f)\" binned_tables_dir/; done" : ''}

    locate prepare-table merge-breakpoints \
        --offsets ${offsets} \
        --breakpoints ${breakpoints} \
        --tables-dir tables_dir \
        ${binned_arg} \
        --output ${meta.sampleID}_breakpoints.csv
    """
}
