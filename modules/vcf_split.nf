include { GetPrefix } from './utils.nf'

process MakeVCFSplit {
    label "multithreaded"

    input:
        path genotypes
        tuple path(ref_genome), path(ref_genome_index)
        tuple val(chr), path(samples)

    output:
        path("${output_prefix}.vcf.gz")

    script:
        genotypes_prefix = GetPrefix(genotypes[0])
        samples_id = samples.getName().tokenize(".")[1]
        output_prefix = "cohort_to_impute.${chr}.${samples_id}"
        """
        plink2 \
            --bfile ${genotypes_prefix} \
            --keep ${samples} \
            --chr ${chr} \
            --export vcf-4.2 id-delim=@ \
            --out ${output_prefix} \
            --threads ${task.cpus} \
            --ref-from-fa ${ref_genome} \
            --output-chr chrMT
        
        bgzip ${output_prefix}.vcf
        """
}