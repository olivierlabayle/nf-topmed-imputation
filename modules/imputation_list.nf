include { GetPrefix; GetJuliaCmd } from './utils.nf'

process WriteImputationSplitLists {
    input:
        path genotypes

    output:
        path "cohort_to_impute.chromosomes.txt", emit: chromosomes
        path "*.keep", emit: samples

    script:
        genotypes_prefix = GetPrefix(genotypes[0])
        """
        ${GetJuliaCmd(task.cpus)} write-imputation-split-lists \
            ${genotypes_prefix} \
            --output-prefix cohort_to_impute \
            --n-samples-per-file ${params.N_SAMPLES_PER_IMPUTATION_JOBS}
        """
}