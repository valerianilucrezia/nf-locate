#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { VARIANT_CALLING } from "${baseDir}/subworkflows/variant_calling/main"
include { SPLIT_BAM as SPLIT_BAM_N } from "${baseDir}/modules/split_bam/main"
include { SPLIT_BAM as SPLIT_BAM_T } from "${baseDir}/modules/split_bam/main"
include { PILEUP } from "${baseDir}/subworkflows/pileup/main"
include { METYLATION } from "${baseDir}/subworkflows/methylation/main"
//include { SMOOTHING } from "${baseDir}/subworkflows/smoothing/main"

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
    bed = Channel.fromPath(params.bed_data, checkIfExists: true) 
    
    // chr channel
    chromosome = Channel.from(21..22)

    //pipeline main
    // split_bam
    splitbam_T = SPLIT_BAM_N(chromosome.combine(input_T)).map {ch, meta, bam, bai -> 
                meta = meta + [chr:ch]
                [meta, bam, bai]
    }

    splitbam_N = SPLIT_BAM_T(chromosome.combine(input_N)).map {ch, meta, bam, bai -> 
                meta = meta + [chr:ch]
                [meta, bam, bai]
    }
        
    VARIANT_CALLING(input, ref_genome)
    PILEUP(splitbam_T, splitbam_N, bed, ref_genome)
    METYLATION(splitbam_T, splitbam_N, ref_genome)
}

