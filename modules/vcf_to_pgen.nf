include { GetPrefix } from './utils.nf'

process BCFToPGEN {
    label "bigmem"
    label "hyperthreaded"
    publishDir "${params.PUBLISH_DIR}", mode: "copy"

    input:
        tuple path(bcf_file), path(csi_file)

    output:
        tuple path("${output_prefix}.pgen"), path("${output_prefix}.pvar"), path("${output_prefix}.psam")

    script:
        output_prefix = GetPrefix(GetPrefix(bcf_file))
        var_ids_option = '@:#\\$r:\\$a' // In single quotes to avoid interpolation
        awk_script = '{sub(/.*@/, "", $1); print}'
        """
        plink2 \
            --bcf ${bcf_file} dosage=DS \
            --make-pgen \
            --output-chr chr26 \
            --new-id-max-allele-len 150 \
            --set-all-var-ids ${var_ids_option} \
            --threads ${task.cpus} \
            --out ${output_prefix}

        awk -F'\\t' 'BEGIN{OFS="\\t"} ${awk_script}' ${output_prefix}.psam > ${output_prefix}.psam.tmp
        mv ${output_prefix}.psam.tmp ${output_prefix}.psam
        """
}