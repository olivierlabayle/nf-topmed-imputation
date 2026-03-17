include { GetJuliaCmd; GetPrefix } from './utils.nf'

process DownloadTOPMedZipFile {
    publishDir "${params.PUBLISH_DIR}/topmed_outputs", mode: "copy"

    input:
        tuple val(job_id), path(zip_file_info)
        path topmed_api_token_file

    output:
        path output_file

    script:
        output_file = GetPrefix(zip_file_info) + ".zip"
        """
        ${GetJuliaCmd(task.cpus)} download-topmed-file \
            ${job_id} \
            ${topmed_api_token_file} \
            ${zip_file_info} \
            --refresh-rate ${params.TOPMED_REFRESH_RATE}
        """
}