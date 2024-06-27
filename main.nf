#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { METYLATION } from "${baseDir}/subworkflows/methylation/main"
include { PILEUP } from "${baseDir}/subworkflows/pileup/main"
include { SMOOTHING } from "${baseDir}/subworkflows/smoothing/main"
include { VARIANT_CALLING } from "${baseDir}/subworkflows/variant_calling/main"

workflow {  
    input_tumor = Channel.fromPath(params.samples).
      splitCsv(header: true).
      map{row ->
        tuple(row.sample.toString(), file(row.tumor_bam), file(row.tumour_bai))}
 
    input_normal = Channel.fromPath(params.samples).
      splitCsv(header: true).
      map{row ->
        tuple(row.sample.toString(), file(row.normal_bam), file(row.normal_bai))}
    
    input_all = Channel.fromPath(params.samples).
      splitCsv(header: true).
      map{row ->
        tuple(row.sample.toString(), file(row.tumor_bam), file(row.tumour_bai), file(row.normal_bam), file(row.normal_bai))}

    
}

