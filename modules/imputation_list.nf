include { GetPrefix; GetJuliaCmd } from 'modules/utils.nf'

process WriteImputationSplitLists {
    input:
        path genotypes

    output:
        path "genomicc.chromosomes.txt", emit: chromosomes
        path "*.keep", emit: samples

    script:
        genotypes_prefix = GetPrefix(genotypes[0])
        """
        ${GetJuliaCmd(task.cpus)} write-imputation-split-lists \
            ${genotypes_prefix} \
            --output-prefix genomicc \
            --n-samples-per-file ${params.N_SAMPLES_PER_IMPUTATION_JOBS}
        """
}