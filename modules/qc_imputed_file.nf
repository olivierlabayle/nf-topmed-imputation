include { GetPrefix } from './utils.nf'

process QCMergedImputedFile {
    input:
        path vcf_file

    output:
        path "${output}"

    script:
        output = "${GetPrefix(GetPrefix(vcf_file))}.qced.vcf.gz"
        """
        bcftools view -m2 -e '( R2 < ${params.IMPUTATION_R2_FILTER})' --threads ${task.cpus} -O z -o ${output} ${vcf_file}
        """
}