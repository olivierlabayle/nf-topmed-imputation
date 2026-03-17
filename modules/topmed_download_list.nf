include { GetJuliaCmd } from './utils.nf'

process GetTOPMedDownloadList {
    input:
        path topmed_api_token_file
        val job_id

    output:
        tuple val(job_id), path("*.json")

    script:
        """
        ${GetJuliaCmd(task.cpus)} get-topmed-download-list \
            ${job_id} \
            ${topmed_api_token_file} \
            --refresh-rate ${params.TOPMED_REFRESH_RATE}
        """
}