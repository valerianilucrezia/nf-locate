#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// include { VARIANT_CALLING } from "${baseDir}/subworkflows/variant_calling/main"
include { SPLIT_ALIGN as SPLIT_ALIGN_N } from "${baseDir}/modules/split_align/main"
include { SPLIT_ALIGN as SPLIT_ALIGN_T } from "${baseDir}/modules/split_align/main"
include { CLAIR3 as CLAIR3_T } from "${baseDir}/modules/clair3/main"
include { CLAIR3 as CLAIR3_N } from "${baseDir}/modules/clair3/main"
include { MODCALL } from "${baseDir}/modules/modcall/"
include { LONGPHASE } from "${baseDir}/modules/longphase/"
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_1 } from "${baseDir}/modules/bcftools_index/"
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_2 } from "${baseDir}/modules/bcftools_index/"
include { HAPLOTAG_BAM as HAPLOTAG_BAM_T } from "${baseDir}/modules/haplotag/"
include { HAPLOTAG_BAM as HAPLOTAG_BAM_N } from "${baseDir}/modules/haplotag/"
include { SAMTOOLS_INDEX } from "${baseDir}/modules/samtools_index/"
include { HAPLOTAGPHASE } from "${baseDir}/modules/haplotagphase/"
include { SHAPEIT4 } from "${baseDir}/modules/shapeit4/"
include { METYLATION_HAPLOTYPE as METYLATION_HAPLOTYPE_T } from "${baseDir}/subworkflows/methylation_haplotype/main"
include { METYLATION_HAPLOTYPE as METYLATION_HAPLOTYPE_N } from "${baseDir}/subworkflows/methylation_haplotype/main"
include { MODKIT as MODKIT_T } from "${baseDir}/modules/modkit/main"
include { MODKIT as MODKIT_N } from "${baseDir}/modules/modkit/main"
include { DMR } from "${baseDir}/modules/dmr/main"
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_T } from "${baseDir}/modules/samtools_index/"
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_N } from "${baseDir}/modules/samtools_index/"
include {BCFTOOLS_BGZIP as BCFTOOLS_BGZIP_N } from "${baseDir}/modules/bcftools_bgzip/"
include {BCFTOOLS_BGZIP as BCFTOOLS_BGZIP_T } from "${baseDir}/modules/bcftools_bgzip/"

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

    // vcf channel
    vcf = Channel.fromPath("${params.vcf}/chr*")
    vcf = vcf.map{ file ->
        meta = [chr:file.getSimpleName()]
        [meta, file]}

    // chr channel
    //chromosome = Channel.from(1..22)
    chromosome = Channel.from([10,22])
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
    
    // input for pileup
    input_T = split_T.map{ meta, bam, bai ->
            def info = [sampleID:meta.sampleID, type:meta.type]
            [meta.subMap('chr'), info, bam, bai]}.combine(vcf, by: 0).map{ meta, info, bam, bai, b ->
            meta = meta + [sampleID:info.sampleID, type:info.type]
            [meta, bam, bai, b]
            }.combine(ref_genome)

    input_N = split_N.map{ meta, bam, bai ->
            def info = [sampleID:meta.sampleID, type:meta.type]
            [meta.subMap('chr'), info, bam, bai]}.combine(vcf, by: 0).map{ meta, info, bam, bai, b ->
            meta = meta + [sampleID:info.sampleID, type:info.type]
            [meta, bam, bai, b]
            }.combine(ref_genome)
    
    // call var in normal and tumor
    CLAIR3_T(input_T)
    CLAIR3_N(input_N)

    // phase normal
    modcall = MODCALL(split_N.combine(ref_genome))
    LONGPHASE(split_N.join(modcall).join(CLAIR3_N.out.pileup).combine(ref_genome))
    idx_vcf = BCFTOOLS_INDEX_1(LONGPHASE.out.vcf)
    
    // haplotag tumor bam
    bam_tumor = split_T.map{ meta, bam, bai -> 
      [meta.subMap('sampleID','chr'), bam, bai]
    }
    
    input_haplotag_T = idx_vcf.map{ meta, vcf, idx -> 
      [meta.subMap('sampleID','chr'), vcf, idx]
    }.join(bam_tumor, by:0).combine(ref_genome)
    
    HAPLOTAG_BAM_T(input_haplotag_T)
    bam_haplotag = SAMTOOLS_INDEX(HAPLOTAG_BAM_T.out.bam)
    
    // haplotag normal
    bam_normal = split_N.map{ meta, bam, bai -> 
      [meta.subMap('sampleID','chr'), bam, bai]
    }
    
    input_haplotag_N = idx_vcf.map{ meta, vcf, idx -> 
      [meta.subMap('sampleID','chr'), vcf, idx]
    }.join(bam_normal, by:0).combine(ref_genome)
    HAPLOTAG_BAM_N(input_haplotag_N)
    
    // phase tumour vcf
    input_phase = CLAIR3_T.out.pileup.map{meta, vcf, idx ->
      [meta.subMap('sampleID','chr'), vcf, idx]
    }.join(bam_haplotag, by:0).combine(ref_genome)
    HAPLOTAGPHASE(input_phase)
    
    // phase tumour with shapeit
    SHAPEIT4(BCFTOOLS_INDEX_2(HAPLOTAGPHASE.out.vcf))
    
    // run methylation on normal and tumor
    METYLATION_HAPLOTYPE_T(HAPLOTAG_BAM_T.out.bam.join(HAPLOTAG_BAM_T.out.list), ref_genome)    
    METYLATION_HAPLOTYPE_N(HAPLOTAG_BAM_N.out.bam.join(HAPLOTAG_BAM_N.out.list), ref_genome) 

    // modkit tumor and normal
    MODKIT_N(split_N.map{meta, bam, bai -> 
      meta = meta + [hp:'Normal']
      [meta, bam, bai]
    }.combine(ref_genome))
    MODKIT_T(split_T.map{meta, bam, bai -> 
      meta = meta + [hp:'Tumor']
      [meta, bam, bai]
    }.combine(ref_genome))
    
    bed_N = BCFTOOLS_BGZIP_N(MODKIT_N.out.bed.map{meta, bed -> 
      meta = meta + [hp:'Normal']
      [meta, bed]
    }).map{meta, bed, idx ->
      [meta.subMap('sampleID','chr'), bed, idx]
    }
    bed_T = BCFTOOLS_BGZIP_T(MODKIT_T.out.bed.map{meta, bed -> 
      meta = meta + [hp:'Tumor']
      [meta, bed]
    }).map{meta, bed, idx ->
      [meta.subMap('sampleID','chr'), bed, idx]
    }
    
    // dmr tumor-normal
    DMR(bed_T.join(bed_N).combine(ref_genome))
  
}

