#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { VARIANT_CALLING } from "${baseDir}/subworkflows/variant_calling/main"
include { SPLIT_ALIGN as SPLIT_ALIGN_N } from "${baseDir}/modules/split_align/main"
include { SPLIT_ALIGN as SPLIT_ALIGN_T } from "${baseDir}/modules/split_align/main"
include { PILEUP as PILEUP_T } from "${baseDir}/subworkflows/pileup/main"
include { PILEUP as PILEUP_N } from "${baseDir}/subworkflows/pileup/main"
include { PHASING as PHASING_T } from "${baseDir}/subworkflows/phasing/main"
include { PHASING as PHASING_N } from "${baseDir}/subworkflows/phasing/main"
//include { METYLATION_CALLING } from "${baseDir}/subworkflows/methylation_calling/main"
include { METYLATION_HAPLOTYPE as METYLATION_HAPLOTYPE_T } from "${baseDir}/subworkflows/methylation_haplotype/main"
include { METYLATION_HAPLOTYPE as METYLATION_HAPLOTYPE_N } from "${baseDir}/subworkflows/methylation_haplotype/main"


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
    bed = Channel.fromPath("${params.bed_file}/**/chr*")
    bed = bed.map{ file ->
        meta = [chr:file.parent.getName()]
        [meta, file]}

    // chr channel
    chromosome = Channel.from(21..22)
    chromosome = chromosome.map{ chr -> 
        ['chr'+chr] }

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
        

    //VARIANT_CALLING(input, ref_genome)
    pileup_T = PILEUP_T(split_T, bed, ref_genome)
    pileup_N = PILEUP_N(split_N, bed, ref_genome)

    if (params.sample == 'nanopore'){
        phasing_T = PHASING_T(pileup_T, split_T, ref_genome, input_T)
        meth_T = METYLATION_HAPLOTYPE_T(pileup_T.join(split_T), ref_genome)

        phasing_N = PHASING_N(pileup_N, split_N, ref_genome, input_N)
        meth_N = METYLATION_HAPLOTYPE_N(pileup_N, split_N)
        
    } elif (params.sample == 'mix'){
        phasing_T = PHASING_T(pileup_T, split_T, ref_genome, input_T)
        meth_T = METYLATION_HAPLOTYPE_T(pileup_T.join(split_T), ref_genome)
    }
}

