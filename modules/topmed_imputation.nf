include { GetPrefix; GetJuliaCmd } from './utils.nf'

process TOPMedImputation {
    cpus = params.TOPMED_MAX_PARALLEL_JOBS
    label "bigmem"

    input:
        path topmed_api_token_file
        path genotypes

    output:
        path "*.txt", emit: jobs_files

    script:
        genotypes_prefix = GetPrefix(genotypes[0])
        """
        ${GetJuliaCmd(task.cpus)} impute \
            topmed \
            ${topmed_api_token_file} \
            --password ${params.TOPMED_ENCRYPTION_PASSWORD} \
            --max-concurrent-submissions ${params.TOPMED_MAX_PARALLEL_JOBS} \
            --refresh-rate ${params.TOPMED_REFRESH_RATE} \
            --r2 ${params.IMPUTATION_R2_FILTER} \
            --output-prefix topmed
        """
}