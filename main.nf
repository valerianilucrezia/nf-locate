#!/usr/bin/env nextflow
nextflow.enable.dsl=2
nextflow.enable.moduleBinaries = true

include { SPLIT_ALIGN as SPLIT_ALIGN_N } from "${baseDir}/modules/split_align/main"
include { SPLIT_ALIGN as SPLIT_ALIGN_T } from "${baseDir}/modules/split_align/main"
include { CLAIRS } from "${baseDir}/modules/clairS/main.nf"
include { MPILEUP } from "${baseDir}/modules/mpileup/main.nf"
include { CLAIR3 as CLAIR3_T } from "${baseDir}/modules/clair3/main"
include { CLAIR3 as CLAIR3_N } from "${baseDir}/modules/clair3/main"
include { MODCALL } from "${baseDir}/modules/modcall/"
include { LONGPHASE } from "${baseDir}/modules/longphase/"
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_1 } from "${baseDir}/modules/bcftools_index/"
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_2 } from "${baseDir}/modules/bcftools_index/"
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_3 } from "${baseDir}/modules/bcftools_index/"
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_4 } from "${baseDir}/modules/bcftools_index/"
include { HAPLOTAG_BAM as HAPLOTAG_BAM_T } from "${baseDir}/modules/haplotag/"
include { HAPLOTAG_BAM as HAPLOTAG_BAM_N } from "${baseDir}/modules/haplotag/"
include { HAPLOTAG_BAM as HAPLOTAG_BAM_T_CORRECTED } from "${baseDir}/modules/haplotag/"
include { SAMTOOLS_INDEX } from "${baseDir}/modules/samtools_index/"
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_CORRECTED } from "${baseDir}/modules/samtools_index/"
include { HAPLOTAGPHASE } from "${baseDir}/modules/haplotagphase/"
include { SHAPEIT4 } from "${baseDir}/modules/shapeit4/"
include { METYLATION_HAPLOTYPE as METYLATION_HAPLOTYPE_T } from "${baseDir}/subworkflows/methylation_haplotype/main"
include { METYLATION_HAPLOTYPE as METYLATION_HAPLOTYPE_N } from "${baseDir}/subworkflows/methylation_haplotype/main"
include { MODKIT as MODKIT_T } from "${baseDir}/modules/modkit/main"
include { MODKIT as MODKIT_N } from "${baseDir}/modules/modkit/main"
include { DMR } from "${baseDir}/modules/dmr/main"
include {BCFTOOLS_BGZIP as BCFTOOLS_BGZIP_N } from "${baseDir}/modules/bcftools_bgzip/"
include {BCFTOOLS_BGZIP as BCFTOOLS_BGZIP_T } from "${baseDir}/modules/bcftools_bgzip/"
include { WHATSHAP } from "${baseDir}/modules/whatshap/"
include { DOWNLOAD_REFERENCES } from "${baseDir}/subworkflows/download_references/main"
include { BATTENBERG_PHASE } from "${baseDir}/modules/battenberg_phase/main"
include { LOCATE_CN; LOCATE_METHYLATION } from "${baseDir}/subworkflows/locate/main"


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

    // call somatic variant
    input_vc = input_T.map{meta, bam, bai -> 
      [meta.subMap('sampleID'), bam,bai]
    }.join(input_N.map{meta, bam, bai -> 
      [meta.subMap('sampleID'), bam,bai]
    }).combine(ref_genome)
    //CLAIRS(input_vc)

    // chr channel
    chromosome = Channel.from(params.test_chromosomes ?: (1..22))
    chromosome = chromosome.map{ chr ->
        ['chr'+chr] }

    // download/locate reference resources (dbSNP vcf, SHAPEIT4 map, 1000G panel)
    DOWNLOAD_REFERENCES(chromosome)
    vcf   = DOWNLOAD_REFERENCES.out.vcf
    gmap  = DOWNLOAD_REFERENCES.out.gmap
    panel = DOWNLOAD_REFERENCES.out.panel

    // shapeit4 reference resources keyed by chr, for joining against per-sample vcfs
    shapeit4_refs = gmap.join(panel)

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

    if (params.shortread == true){
      MPILEUP(input_N)
      
      tmp_vcf = MPILEUP.out.vcf.map{ meta, vcf, tbi -> 
                  [meta.subMap('chr', 'sampleID'), vcf, tbi]}
                  
      tmp_normal = split_N.map{ meta, bam, bai -> 
                  [meta.subMap('chr', 'sampleID'), bam, bai]}
      tmp_tumour = split_T.map{ meta, bam, bai -> 
                  [meta.subMap('chr', 'sampleID'), bam, bai]}

      WHATSHAP(tmp_vcf.join(tmp_normal).combine(ref_genome))
      vcf_phase = WHATSHAP.out.vcf.map { meta, vcf -> 
                meta = meta + [type:'Normal']
                [meta, vcf]}
      idx_vcf = BCFTOOLS_INDEX_3(vcf_phase)
      
      input_haplotag_T = idx_vcf.map{ meta, vcf, idx -> 
        [meta.subMap('sampleID','chr'), vcf, idx]
      }.join(tmp_tumour, by:0).combine(ref_genome)

      HAPLOTAG_BAM_T(input_haplotag_T.map{meta,vcf,idx,bam,bai,ref,fai -> 
        meta = meta+[type:'Tumor']
        [meta,vcf,idx,bam,bai,ref,fai]})
      bam_haplotag = SAMTOOLS_INDEX(HAPLOTAG_BAM_T.out.bam)

      input_phase = CLAIR3_T.out.pileup.join(bam_haplotag, by:0).combine(ref_genome)
      HAPLOTAGPHASE(input_phase)

      SHAPEIT4(BCFTOOLS_INDEX_2(HAPLOTAGPHASE.out.vcf).map{ meta, vcf, idx ->
        [meta.chr, meta, vcf, idx]
      }.join(shapeit4_refs).map{ chr, meta, vcf, idx, gmap, panel, panel_idx ->
        [meta, vcf, idx, gmap, panel, panel_idx]
      })

      // annotate tumour phased vcf with battenberg haplotype/segmentation results
      shapeit_idx = BCFTOOLS_INDEX_4(SHAPEIT4.out.vcf)
      normal_for_battenberg = vcf_phase.map{ meta, vcf -> [meta.subMap('sampleID','chr'), vcf] }

      battenberg_input = HAPLOTAGPHASE.out.vcf.map{ meta, vcf ->
        [meta.subMap('sampleID','chr'), meta, vcf]
      }.join(shapeit_idx.map{ meta, vcf, csi ->
        [meta.subMap('sampleID','chr'), vcf, csi]
      }).join(normal_for_battenberg).map{ key, meta, tumor_vcf, shapeit_vcf, shapeit_csi, normal_vcf ->
        [meta, tumor_vcf, shapeit_vcf, shapeit_csi, normal_vcf]
      }

      BATTENBERG_PHASE(battenberg_input)

      // re-haplotag tumor bam using the battenberg-corrected (GT-swapped) vcf
      input_haplotag_T_corrected = BATTENBERG_PHASE.out.vcf.map{ meta, vcf, idx ->
        [meta.subMap('sampleID','chr'), vcf, idx]
      }.join(tmp_tumour, by:0).combine(ref_genome).map{ meta, vcf, idx, bam, bai, ref, fai ->
        meta = meta + [type:'Tumor']
        [meta, vcf, idx, bam, bai, ref, fai]
      }
      HAPLOTAG_BAM_T_CORRECTED(input_haplotag_T_corrected)
      bam_haplotag_corrected = SAMTOOLS_INDEX_CORRECTED(HAPLOTAG_BAM_T_CORRECTED.out.bam)

      // run methylation on tumor using the corrected haplotag bam
      METYLATION_HAPLOTYPE_T(HAPLOTAG_BAM_T_CORRECTED.out.bam.join(HAPLOTAG_BAM_T_CORRECTED.out.list), ref_genome)

      MODKIT_T(bam_haplotag_corrected.map{meta, bam, bai ->
        meta = meta + [hp:'Tumor']
        [meta, bam, bai]
      }.combine(ref_genome))

      // segmentation + copy-number inference (LOCATE)
      if (params.run_locate) {
        LOCATE_CN(BATTENBERG_PHASE.out.vcf.map{ meta, vcf, idx ->
          [meta.subMap('sampleID','chr'), vcf, idx]
        })
      }

    } else {
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
      
      HAPLOTAG_BAM_T(input_haplotag_T.map{meta,vcf,idx,bam,bai,ref,fai -> 
        meta = meta+[type:'Tumor']
        [meta,vcf,idx,bam,bai,ref,fai]})
      bam_haplotag = SAMTOOLS_INDEX(HAPLOTAG_BAM_T.out.bam)

      // haplotag normal    
      input_haplotag_N = idx_vcf.join(split_N, by:0).combine(ref_genome)
      HAPLOTAG_BAM_N(input_haplotag_N)
      
      // phase tumour vcf
      input_phase = CLAIR3_T.out.pileup.join(bam_haplotag, by:0).combine(ref_genome)
      HAPLOTAGPHASE(input_phase)
      
      // phase tumour with shapeit
      SHAPEIT4(BCFTOOLS_INDEX_2(HAPLOTAGPHASE.out.vcf).map{ meta, vcf, idx ->
        [meta.chr, meta, vcf, idx]
      }.join(shapeit4_refs).map{ chr, meta, vcf, idx, gmap, panel, panel_idx ->
        [meta, vcf, idx, gmap, panel, panel_idx]
      })

      // annotate tumour phased vcf with battenberg haplotype/segmentation results
      shapeit_idx = BCFTOOLS_INDEX_4(SHAPEIT4.out.vcf)
      normal_for_battenberg = LONGPHASE.out.vcf.map{ meta, vcf ->
        [meta.subMap('sampleID','chr'), vcf]
      }

      battenberg_input = HAPLOTAGPHASE.out.vcf.map{ meta, vcf ->
        [meta.subMap('sampleID','chr'), meta, vcf]
      }.join(shapeit_idx.map{ meta, vcf, csi ->
        [meta.subMap('sampleID','chr'), vcf, csi]
      }).join(normal_for_battenberg).map{ key, meta, tumor_vcf, shapeit_vcf, shapeit_csi, normal_vcf ->
        [meta, tumor_vcf, shapeit_vcf, shapeit_csi, normal_vcf]
      }

      BATTENBERG_PHASE(battenberg_input)

      // re-haplotag tumor bam using the battenberg-corrected (GT-swapped) vcf
      input_haplotag_T_corrected = BATTENBERG_PHASE.out.vcf.map{ meta, vcf, idx ->
        [meta.subMap('sampleID','chr'), vcf, idx]
      }.join(bam_tumor, by:0).combine(ref_genome).map{ meta, vcf, idx, bam, bai, ref, fai ->
        meta = meta + [type:'Tumor']
        [meta, vcf, idx, bam, bai, ref, fai]
      }
      
      HAPLOTAG_BAM_T_CORRECTED(input_haplotag_T_corrected)
      bam_haplotag_corrected = SAMTOOLS_INDEX_CORRECTED(HAPLOTAG_BAM_T_CORRECTED.out.bam)

      // run methylation on normal and tumor (tumor uses the corrected haplotag bam)
      METYLATION_HAPLOTYPE_T(HAPLOTAG_BAM_T_CORRECTED.out.bam.join(HAPLOTAG_BAM_T_CORRECTED.out.list), ref_genome)
      METYLATION_HAPLOTYPE_N(HAPLOTAG_BAM_N.out.bam.join(HAPLOTAG_BAM_N.out.list), ref_genome)

      // modkit tumor and normal
      MODKIT_N(split_N.map{meta, bam, bai ->
        meta = meta + [hp:'Normal']
        [meta, bam, bai]
      }.combine(ref_genome))

      MODKIT_T(bam_haplotag_corrected.map{meta, bam, bai ->
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
      DMR(bed_T.join(bed_N).combine(ref_genome).map{meta, bed1, idx1, bed2, idx2, ref, idx ->
        meta = meta + [type:'Tumor-Normal']
        [meta, bed1, idx1, bed2, idx2, ref, idx]
      })

      // segmentation + copy-number + methylation inference (LOCATE)
      if (params.run_locate) {
        LOCATE_CN(BATTENBERG_PHASE.out.vcf.map{ meta, vcf, idx ->
          [meta.subMap('sampleID','chr'), vcf, idx]
        })

        LOCATE_METHYLATION(
          METYLATION_HAPLOTYPE_T.out.meth_h1,
          METYLATION_HAPLOTYPE_T.out.meth_h2,
          METYLATION_HAPLOTYPE_N.out.meth_h1,
          METYLATION_HAPLOTYPE_N.out.meth_h2
        )
      }
    }
  
}

