#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//include { METYLATION } from "${baseDir}/subworkflows/methylation/main"
include { PILEUP } from "${baseDir}/subworkflows/pileup/main"
include { VARIANT_CALLING } from "${baseDir}/subworkflows/variant_calling/main"
//include { SMOOTHING } from "${baseDir}/subworkflows/smoothing/main"


workflow {  
    //samplesheet
    input_tumor = Channel.fromPath(params.samplesheet).
      splitCsv(header: true).
      map{row ->
        tuple("t_"+ row.sample.toString(), file(row.tumor_bam), file(row.tumor_bam + '.bai'))}

    input_normal = Channel.fromPath(params.samplesheet).
      splitCsv(header: true).
      map{row ->
        tuple("n_"+ row.sample.toString(), file(row.normal_bam), file(row.normal_bam + '.bai'))}

    input_all = Channel.fromPath(params.samplesheet).
      splitCsv(header: true).
      map{row ->
        tuple(row.sample.toString(), file(row.tumor_bam), file(row.tumor_bam + '.bai'), file(row.normal_bam), file(row.normal_bam + '.bai'))}
    
    //reference genome
    ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 
    ref_fai_ch = Channel.fromPath(params.ref_fai, checkIfExists: true)

    //bed channel
    bed_ch = Channel.fromPath(params.bed_data, checkIfExists: true) 
    
    // chr channel
    chr_ch = Channel.from(1)//Channel.from(20..22)


    //pipeline main
    input_vc_ch = input_all.combine(ref_genome_ch).combine(ref_fai_ch)
    VARIANT_CALLING(input_vc_ch)
    PILEUP(input_tumor, input_normal, chr_ch, bed_ch, ref_genome_ch, ref_fai_ch)

    
}

