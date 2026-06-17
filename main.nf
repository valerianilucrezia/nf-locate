#!/usr/bin/env nextflow
nextflow.enable.dsl=2
nextflow.enable.moduleBinaries = true

include { SPLIT_ALIGN as SPLIT_ALIGN_N } from "./modules/split_align/main"
include { SPLIT_ALIGN as SPLIT_ALIGN_T } from "./modules/split_align/main"
include { CLAIRS } from "./modules/clairS/main.nf"
include { MPILEUP } from "./modules/mpileup/main.nf"
include { CLAIR3 as CLAIR3_T } from "./modules/clair3/main"
include { CLAIR3 as CLAIR3_N } from "./modules/clair3/main"
include { MODCALL } from "./modules/modcall/"
include { LONGPHASE } from "./modules/longphase/"
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_1 } from "./modules/bcftools_index/"
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_2 } from "./modules/bcftools_index/"
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_3 } from "./modules/bcftools_index/"
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_4 } from "./modules/bcftools_index/"
include { HAPLOTAG_BAM as HAPLOTAG_BAM_T } from "./modules/haplotag/"
include { HAPLOTAG_BAM as HAPLOTAG_BAM_N } from "./modules/haplotag/"
include { HAPLOTAG_BAM as HAPLOTAG_BAM_T_CORRECTED } from "./modules/haplotag/"
include { SAMTOOLS_INDEX } from "./modules/samtools_index/"
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_CORRECTED } from "./modules/samtools_index/"
include { HAPLOTAGPHASE } from "./modules/haplotagphase/"
include { SHAPEIT4 } from "./modules/shapeit4/"
include { METYLATION_HAPLOTYPE as METYLATION_HAPLOTYPE_T } from "./subworkflows/methylation_haplotype/main"
include { METYLATION_HAPLOTYPE as METYLATION_HAPLOTYPE_N } from "./subworkflows/methylation_haplotype/main"
include { MODKIT as MODKIT_T } from "./modules/modkit/main"
include { MODKIT as MODKIT_N } from "./modules/modkit/main"
include { DMR } from "./modules/dmr/main"
include {BCFTOOLS_BGZIP as BCFTOOLS_BGZIP_N } from "./modules/bcftools_bgzip/"
include {BCFTOOLS_BGZIP as BCFTOOLS_BGZIP_T } from "./modules/bcftools_bgzip/"
include { WHATSHAP } from "./modules/whatshap/"
include { DOWNLOAD_REFERENCES } from "./subworkflows/download_references/main"
include { BATTENBERG_PHASE } from "./modules/battenberg_phase/main"
include { LOCATE_CN; LOCATE_METHYLATION } from "./subworkflows/locate/main"


include { samplesheetToList } from 'plugin/nf-schema'

// run with: nextflow run main.nf --somatic_only true --input <CSV> --outdir <DIR>
workflow SOMATIC {
    input = params.input ? Channel.fromList(samplesheetToList(params.input, "assets/schema_input.json")) : Channel.empty()

    input_T = input.map{ meta, bamT, baiT, bamN, baiN ->
            meta = meta + [type:'Tumor']
            [meta, bamT, baiT] }

    input_N = input.map{ meta, bamT, baiT, bamN, baiN ->
            meta = meta + [type:'Normal']
            [meta, bamN, baiN] }

    ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true)
    ref_fai_ch = Channel.fromPath(params.ref_fai, checkIfExists: true)
    ref_genome = ref_genome_ch.combine(ref_fai_ch)

    input_vc = input_T.map{meta, bam, bai ->
      [meta.subMap('sampleID'), bam,bai]
    }.join(input_N.map{meta, bam, bai ->
      [meta.subMap('sampleID'), bam,bai]
    }).combine(ref_genome)

    CLAIRS(input_vc)
}

workflow {
  if (params.somatic_only.toString() == 'true') {
    SOMATIC()
  } else {
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

    if (params.run_somatic_calling.toString() == 'true') {
      CLAIRS(input_vc)
    }

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

    if (params.shortread.toString() == 'true'){
      MPILEUP(input_N)
      
      tmp_vcf = MPILEUP.out.vcf.map{ meta, v, tbi ->
                  [meta.subMap('chr', 'sampleID'), v, tbi]}
                  
      tmp_normal = split_N.map{ meta, bam, bai -> 
                  [meta.subMap('chr', 'sampleID'), bam, bai]}
      tmp_tumour = split_T.map{ meta, bam, bai -> 
                  [meta.subMap('chr', 'sampleID'), bam, bai]}

      WHATSHAP(tmp_vcf.join(tmp_normal).combine(ref_genome))
      vcf_phase = WHATSHAP.out.vcf.map { meta, v ->
                meta = meta + [type:'Normal']
                [meta, v]}
      idx_vcf = BCFTOOLS_INDEX_3(vcf_phase)
      
      input_haplotag_T = idx_vcf.map{ meta, v, idx ->
        [meta.subMap('sampleID','chr'), v, idx]
      }.join(tmp_tumour, by:0).combine(ref_genome)

      HAPLOTAG_BAM_T(input_haplotag_T.map{meta,v,idx,bam,bai,ref,fai ->
        meta = meta+[type:'Tumor']
        [meta,v,idx,bam,bai,ref,fai]})
      bam_haplotag = SAMTOOLS_INDEX(HAPLOTAG_BAM_T.out.bam)

      input_phase = CLAIR3_T.out.pileup.join(bam_haplotag, by:0).combine(ref_genome)
      HAPLOTAGPHASE(input_phase)

      out_bcf = BCFTOOLS_INDEX_2(HAPLOTAGPHASE.out.vcf)

      SHAPEIT4(out_bcf.map{ meta, v, idx ->
        [meta.chr, meta, v, idx]
      }.combine(shapeit4_refs, by: 0).map{ chr, meta, v, idx, gmap_f, panel_f, panel_idx ->
        [meta, v, idx, gmap_f, panel_f, panel_idx]
      })

      // annotate tumour phased vcf with battenberg haplotype/segmentation results
      shapeit_idx = BCFTOOLS_INDEX_4(SHAPEIT4.out.vcf)
      normal_for_battenberg = vcf_phase.map{ meta, v -> [meta.subMap('sampleID','chr'), v] }

      battenberg_input = HAPLOTAGPHASE.out.vcf.map{ meta, v ->
        [meta.subMap('sampleID','chr'), meta, v]
      }.join(shapeit_idx.map{ meta, v, csi ->
        [meta.subMap('sampleID','chr'), v, csi]
      }).join(normal_for_battenberg).map{ key, meta, tumor_vcf, shapeit_vcf, shapeit_csi, normal_vcf ->
        [meta, tumor_vcf, shapeit_vcf, shapeit_csi, normal_vcf]
      }

      BATTENBERG_PHASE(battenberg_input)

      // re-haplotag tumor bam using the battenberg-corrected (GT-swapped) vcf
      input_haplotag_T_corrected = BATTENBERG_PHASE.out.vcf.map{ meta, v, idx ->
        [meta.subMap('sampleID','chr'), v, idx]
      }.join(tmp_tumour, by:0).combine(ref_genome).map{ meta, v, idx, bam, bai, ref, fai ->
        meta = meta + [type:'Tumor']
        [meta, v, idx, bam, bai, ref, fai]
      }
      HAPLOTAG_BAM_T_CORRECTED(input_haplotag_T_corrected)
      bam_haplotag_corrected = SAMTOOLS_INDEX_CORRECTED(HAPLOTAG_BAM_T_CORRECTED.out.bam)

      // run methylation on tumor using the corrected haplotag bam
      METYLATION_HAPLOTYPE_T(HAPLOTAG_BAM_T_CORRECTED.out.bam.join(HAPLOTAG_BAM_T_CORRECTED.out.list), ref_genome)

      if (params.run_modkit.toString() == 'true') {
        MODKIT_T(bam_haplotag_corrected.map{meta, bam, bai ->
          meta = meta + [hp:'Tumor']
          [meta, bam, bai]
        }.combine(ref_genome))
      }

      // segmentation + copy-number inference (LOCATE)
      if (params.run_locate.toString() == 'true') {
        LOCATE_CN(BATTENBERG_PHASE.out.vcf.map{ meta, v, idx ->
          [meta.subMap('sampleID','chr'), v, idx]
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
      
      input_haplotag_T = idx_vcf.map{ meta, v, idx ->
        [meta.subMap('sampleID','chr'), v, idx]
      }.join(bam_tumor, by:0).combine(ref_genome)

      HAPLOTAG_BAM_T(input_haplotag_T.map{meta,v,idx,bam,bai,ref,fai ->
        meta = meta+[type:'Tumor']
        [meta,v,idx,bam,bai,ref,fai]})
      bam_haplotag = SAMTOOLS_INDEX(HAPLOTAG_BAM_T.out.bam)

      // haplotag normal    
      input_haplotag_N = idx_vcf.join(split_N, by:0).combine(ref_genome)
      HAPLOTAG_BAM_N(input_haplotag_N)
      
      // phase tumour vcf
      input_phase = CLAIR3_T.out.pileup.join(bam_haplotag, by:0).combine(ref_genome)
      HAPLOTAGPHASE(input_phase)
      
      // phase tumour with shapeit
      SHAPEIT4(BCFTOOLS_INDEX_2(HAPLOTAGPHASE.out.vcf).map{ meta, v, idx ->
        [meta.chr, meta, v, idx]
      }.combine(shapeit4_refs, by: 0).map{ chr, meta, v, idx, gmap_f, panel_f, panel_idx ->
        [meta, v, idx, gmap_f, panel_f, panel_idx]
      })

      // annotate tumour phased vcf with battenberg haplotype/segmentation results
      shapeit_idx = BCFTOOLS_INDEX_4(SHAPEIT4.out.vcf)
      normal_for_battenberg = LONGPHASE.out.vcf.map{ meta, v ->
        [meta.subMap('sampleID','chr'), v]
      }

      battenberg_input = HAPLOTAGPHASE.out.vcf.map{ meta, v ->
        [meta.subMap('sampleID','chr'), meta, v]
      }.join(shapeit_idx.map{ meta, v, csi ->
        [meta.subMap('sampleID','chr'), v, csi]
      }).join(normal_for_battenberg).map{ key, meta, tumor_vcf, shapeit_vcf, shapeit_csi, normal_vcf ->
        [meta, tumor_vcf, shapeit_vcf, shapeit_csi, normal_vcf]
      }

      BATTENBERG_PHASE(battenberg_input)

      // re-haplotag tumor bam using the battenberg-corrected (GT-swapped) vcf
      input_haplotag_T_corrected = BATTENBERG_PHASE.out.vcf.map{ meta, v, idx ->
        [meta.subMap('sampleID','chr'), v, idx]
      }.join(bam_tumor, by:0).combine(ref_genome).map{ meta, v, idx, bam, bai, ref, fai ->
        meta = meta + [type:'Tumor']
        [meta, v, idx, bam, bai, ref, fai]
      }
      
      HAPLOTAG_BAM_T_CORRECTED(input_haplotag_T_corrected)
      bam_haplotag_corrected = SAMTOOLS_INDEX_CORRECTED(HAPLOTAG_BAM_T_CORRECTED.out.bam)

      // run methylation on normal and tumor (tumor uses the corrected haplotag bam)
      METYLATION_HAPLOTYPE_T(HAPLOTAG_BAM_T_CORRECTED.out.bam.join(HAPLOTAG_BAM_T_CORRECTED.out.list), ref_genome)
      METYLATION_HAPLOTYPE_N(HAPLOTAG_BAM_N.out.bam.join(HAPLOTAG_BAM_N.out.list), ref_genome)

      if (params.run_modkit.toString() == 'true') {
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
      }

      // segmentation + copy-number + methylation inference (LOCATE)
      if (params.run_locate.toString() == 'true') {
        LOCATE_CN(BATTENBERG_PHASE.out.vcf.map{ meta, v, idx ->
          [meta.subMap('sampleID','chr'), v, idx]
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
}

