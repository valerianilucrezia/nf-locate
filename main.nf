#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { VARIANT_CALLING } from "${baseDir}/subworkflows/variant_calling/main"
include { SPLIT_ALIGN as SPLIT_ALIGN_N } from "${baseDir}/modules/split_align/main"
include { SPLIT_ALIGN as SPLIT_ALIGN_T } from "${baseDir}/modules/split_align/main"
include { PILEUP } from "${baseDir}/subworkflows/pileup/main"
include { METYLATION_CALLING } from "${baseDir}/subworkflows/methylation_calling/main"

include { samplesheetToList } from 'plugin/nf-schema'

workflow {  
    // samplesheet validation
    input = params.input ? Channel.fromList(samplesheetToList(params.input, "assets/schema_input.json")) : Channel.empty()
    input_T = input.map{ meta, bamT, baiT, bamN, baiN -> 
            meta = meta + [type:'Tumor']
            [meta, bamT, baiT] }

    input_N = input.map{ meta, bamT, baiT, bamN, baiN -> 
            meta = meta + [type:'Normal']
            [meta, bamN, baiN] }
          
    //reference genome
    ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 
    ref_fai_ch = Channel.fromPath(params.ref_fai, checkIfExists: true)
    ref_genome = ref_genome_ch.combine(ref_fai_ch)

    // bed channel
    bed = Channel.fromPath(params.bed_file, checkIfExists: true) 
    
    // chr channel
    chromosome = Channel.from(21..22)

    // pipeline main
    // split_bam
    split_T = SPLIT_ALIGN_T(chromosome.combine(input_T)).map {ch, meta, bam, bai -> 
                meta = meta + [chr:ch]
                [meta, bam, bai]
    }

    split_N = SPLIT_ALIGN_N(chromosome.combine(input_N)).map {ch, meta, bam, bai -> 
                meta = meta + [chr:ch]
                [meta, bam, bai]
    }
        
    VARIANT_CALLING(input, ref_genome)
    PILEUP(split_T, split_N, bed, ref_genome)
    METYLATION_CALLING(split_T, split_N, ref_genome)
}

