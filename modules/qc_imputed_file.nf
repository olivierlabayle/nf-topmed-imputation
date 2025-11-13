include { GetPrefix } from './utils.nf'

process QCMergedImputedFile {
    input:
        path vcf_file
        tuple path(ref_genome), path(ref_genome_index)

    output:
        tuple path("${output_bcf}"), path("${output_bcf}.csi")

    script:
        output_bcf = "${GetPrefix(GetPrefix(vcf_file))}.qced.bcf"
        """
        bcftools norm \
            -m -both \
            -f ${ref_genome} \
            --check-ref wx \
            --threads ${task.cpus} \
            --output-type=b \
            --output=${output_bcf} \
            --write-index=csi \
            ${vcf_file}
        """
}