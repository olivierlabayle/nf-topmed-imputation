process IndexVCF {
    input:
        path vcf_file

    output:
        path "${vcf_file}.tbi"

    script:
        """
        bcftools index --tbi --threads ${task.cpus} ${vcf_file}
        """
}
