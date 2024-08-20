//
// VARIANT_CALLING SUB-WORKFLOW
//

include { CLAIRS } from '../../modules/clairS/main.nf'
include { READ_SOMATIC } from '../../modules/read_vcf/main_somatic.nf'


workflow VARIANT_CALLING {
    take:
        tumor_bam
        tumor_bai
        normal_bam
        normal_bai
        ref_genome
        ref_fai

    main:
        clairs_ch = CLAIRS(tumor_bam_ch, tumor_bai_ch, normal_bam_ch, normal_bai_ch, ref_genome_ch, ref_fai_ch)

    emit:
        clairs_ch.vcf_files

}