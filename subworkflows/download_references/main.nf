#!/usr/bin/env nextflow

include { DOWNLOAD_DBSNP; SPLIT_DBSNP_BY_CHR } from "${baseDir}/modules/download_dbsnp/main"
include { DOWNLOAD_MAP } from "${baseDir}/modules/download_map/main"
include { DOWNLOAD_1000G } from "${baseDir}/modules/download_1000g/main"

workflow DOWNLOAD_REFERENCES {

    take:
      chromosome // channel of ['chrN'] lists, chr1..chr22

    main:
      chr_val = chromosome.map { it[0] }

      // vcf: dbSNP common SNPs, split by chromosome -> [meta(chr), file]
      if (params.vcf) {
        vcf = Channel.fromPath("${params.vcf}/chr*").map { file ->
            meta = [chr: file.getSimpleName()]
            [meta, file]
        }
      } else {
        dbsnp = DOWNLOAD_DBSNP()
        vcf = SPLIT_DBSNP_BY_CHR(chr_val.combine(dbsnp)).vcf.map { chr, file ->
            [[chr: chr], file]
        }
      }

      // map: SHAPEIT4 genetic maps -> [chr, gmap]
      if (params.map) {
        gmap = chr_val.map { chr ->
            [chr, file("${params.map}/${chr}.b38.gmap_CHR.gz")]
        }
      } else {
        gmap = DOWNLOAD_MAP().map.flatten().map { f ->
            [f.getSimpleName().tokenize('.')[0], f]
        }
      }

      // bcf: 1000G phase3 GRCh38 reference panel -> [chr, vcf, csi]
      if (params.bcf) {
        panel = chr_val.map { chr ->
            [chr,
             file("${params.bcf}/ALL.${chr}.phase3_shapeit2_mvncall_integrated_v5.20130502.genotypes_chr_38.vcf.gz"),
             file("${params.bcf}/ALL.${chr}.phase3_shapeit2_mvncall_integrated_v5.20130502.genotypes_chr_38.vcf.gz.csi")]
        }
      } else {
        panel = DOWNLOAD_1000G(chr_val).panel
      }

    emit:
      vcf   = vcf
      gmap  = gmap  // [chr, gmap]
      panel = panel // [chr, vcf, csi]
}
