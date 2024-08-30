#!/usr/bin/env nextflow

include { MODKIT } from '../../modules/modkit/main'
include { GET_POSITIONS } from '../../modules/get_positions/main'
//include { METH_PILEUP } from '../../modules/pileup_methylation/main'
//include { READ_BED } from '../../modules/read_bed/main'
//include { COMBINE } from '../../modules/combine_methylation/main'

params.bam = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/data/raw/COLO829/chr22-COLO829.bam'
params.bai = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/data/raw/COLO829/chr22-COLO829.bam.bai'
params.ref_genome = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna'
params.ref_fai = '/orfeo/LTS/LADE/LT_storage/lvaleriani/CNA/ref/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai'

params.bam_split_data = '/u/area/ffabris/fast/long_reads_pipeline/tests/pielup_pipeline/results/split_bam'
params.rscript_readbed = "/u/area/ffabris/fast/long_reads_pipeline/LR_Pipeline_DNA/bin/read_bed.R"
params.rscript_combine = '/u/area/ffabris/fast/long_reads_pipeline/LR_Pipeline_DNA/bin/combine.R'

bam_ch = Channel.fromPath(params.bam, checkIfExists: true) 
bai_ch = Channel.fromPath(params.bai, checkIfExists: true) 
ref_genome_ch = Channel.fromPath(params.ref_genome, checkIfExists: true) 
ref_fai_ch = Channel.fromPath(params.ref_fai, checkIfExists: true)

chr_ch = Channel.from(1..22)
name_ch = Channel.from("COLO829")
rscript_readbed_ch = Channel.fromPath(params.rscript_readbed, checkIfExists: true) 
rscript_combine_ch = Channel.fromPath(params.rscript_combine, checkIfExists: true)


workflow METYLATION {
    take:
        bam_ch
        bai_ch
        ref_genome_ch
        ref_fai_ch
        rscript_readbed_ch
        rscript_combine_ch
       
    
    main:
        input_modkit_ch = name_ch.combine(bam_ch)
                .combine(bai_ch)
                .combine(ref_genome_ch)
                .combine(ref_fai_ch)

        modkit_ch = MODKIT(input_modkit_ch)
        

        input_getpositions_ch = chr_ch.combine(modkit_ch.bed)
        get_positions_ch = GET_POSITIONS(input_getpositions_ch)


        //input_pilupmet_ch = chr_ch
          //              .combine(Channel.fromPath(params.bam_split_data, checkIfExists: true) )
            //            .combine(get_positions_ch.bed.flatten())
              //          .combine(ref_genome_ch)
                //        .combine(ref_fai_ch)
        //pileupmet_ch = METH_PILEUP(input_pilupmet_ch)
        //vcf_ch = pileupmet_ch.vcf.flatten()


        //input_readbed_ch = rscript_readbed_ch
          //              .combine(chr_ch)
            //            .combine(bed_modkit_ch)
        //readbed_ch = READ_BED(input_readbed_ch)
        //readbed_rds_ch = readbed_ch.RDS.flatten()


        //input_ch = rscript_combine_ch
         //   .combine(chr_ch)
          //  .combine(readbed_rds_ch)
           // .combine(vcf_ch)
            //combine_ch = COMBINE(input_ch)

   // emit:
     //   combine_ch.RDS.flatten()
}

workflow {
    METYLATION(bam_ch, bai_ch, ref_genome_ch, ref_fai_ch, rscript_readbed_ch, rscript_combine_ch)
    }
