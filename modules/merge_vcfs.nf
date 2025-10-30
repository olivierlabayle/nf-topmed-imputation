process MergeVCFsByChr {
    input:
        tuple val(chr), path(vcf_files)

    output:
        path("${output}")

    script:
        output = "${chr}.vcf.gz"
        sorted_vcf_files_string = vcf_files
            .findAll { x -> x.getName().endsWith("vcf.gz") }
            .sort{ x -> x.getName().tokenize("_")[1].toInteger() }
            .join("\n")
        """
        echo "${sorted_vcf_files_string}" > merge_list.txt

        bcftools merge --threads ${task.cpus} -o ${output} -O z -l merge_list.txt
        """
}