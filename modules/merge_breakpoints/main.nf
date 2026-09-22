#!/usr/bin/env nextflow

process MERGE_BREAKPOINTS {
    tag "${meta.sampleID}"
    label "process_low"
    label "error_retry"
    container 'docker://lvaleriani/locate:v1.3'

    input:
      // binned_chrom_tables is optional (pass NO_FILE when segmentation ran directly
      // on the unbinned chrom_tables) -- when present, it's BIN_TABLE's output, needed
      // to translate each change_point from a binned-table row index back to the
      // unbinned-table row index where that bin starts (see prepare-table
      // merge-breakpoints's --binned-tables-dir docstring).
      //
      // The unbinned and binned tables share file names (<chrom>_table.csv), and Nextflow
      // refuses to stage two inputs with the same name into one task directory, so each
      // set is staged into its own subfolder (stageAs) and those folders are passed
      // straight to the command.
      tuple val(meta), path(offsets), path(chrom_tables, stageAs: 'unbinned/*'), path(breakpoints), path(binned_chrom_tables, stageAs: 'binned/*')

    output:
      tuple val(meta), path('*_breakpoints.csv'), emit: 'breakpoints'

    script:
    // a single staged file arrives as a lone Path, which iterates over its name elements
    def binned_list = (binned_chrom_tables instanceof java.nio.file.Path) ? [binned_chrom_tables] : binned_chrom_tables
    def has_binned  = binned_list.any { it.name != 'NO_FILE' }
    def binned_arg  = has_binned ? '--binned-tables-dir binned' : ''
    """
    locate prepare-table merge-breakpoints \
        --offsets ${offsets} \
        --breakpoints ${breakpoints} \
        --tables-dir unbinned \
        ${binned_arg} \
        --output ${meta.sampleID}_breakpoints.csv
    """
}
