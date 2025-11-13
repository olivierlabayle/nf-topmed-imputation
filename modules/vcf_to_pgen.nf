include { GetPrefix } from './utils.nf'

process BCFToPGEN {
    label "bigmem"
    publishDir "${params.PUBLISH_DIR}", mode: "copy"

    input:
        tuple path(bcf_file), path(csi_file)

    output:
        tuple path("${output_prefix}.pgen"), path("${output_prefix}.pvar"), path("${output_prefix}.psam")

    script:
        output_prefix = GetPrefix(GetPrefix(bcf_file))
        """
        plink2 \
            --bcf ${bcf_file} dosage=DS \
            --make-pgen \
            --set-missing-var-ids @:#\$r,\$a \
            --threads ${task.cpus} \
            --out ${output_prefix}

        awk -F'\\t' 'BEGIN{OFS="\\t"} {sub(/.*@/, "", \$1); print}' ${output_prefix}.psam > ${output_prefix}.psam.tmp
        mv ${output_prefix}.psam.tmp ${output_prefix}.psam
        """
}