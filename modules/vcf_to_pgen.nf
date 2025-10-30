include { GetPrefix } from 'modules/utils.nf'

process VCFToPGEN {
    label "bigmem"
    publishDir "${params.PUBLISH_DIR}", mode: "copy"

    input:
        path vcf_file

    output:
        tuple path("${output_prefix}.pgen"), path("${output_prefix}.pvar"), path("${output_prefix}.psam")

    script:
        output_prefix = GetPrefix(GetPrefix(vcf_file))
        """
        plink2 --vcf ${vcf_file} --make-pgen --threads ${task.cpus} --out ${output_prefix}

        awk -F'\\t' 'BEGIN{OFS="\\t"} {sub(/.*@/, "", \$1); print}' ${output_prefix}.psam > ${output_prefix}.psam.tmp
        mv ${output_prefix}.psam.tmp ${output_prefix}.psam
        """
}