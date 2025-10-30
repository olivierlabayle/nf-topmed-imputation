include { GetJuliaCmd } from './utils.nf'

process DownloadTOPMedZipFile {
    input:
        tuple val(job_id), path(md5_file), path(zip_file_info)
        path topmed_api_token_file

    output:
        path output_file

    script:
        def output_file_parts = zip_file_info.getName().tokenize(".")
        output_file_parts.remove(1)
        output_file = output_file_parts.join(".")
        """
        ${GetJuliaCmd(task.cpus)} download-topmed-file \
            ${job_id} \
            ${topmed_api_token_file} \
            ${zip_file_info} \
            --md5-file ${md5_file} \
            --refresh-rate ${params.TOPMED_REFRESH_RATE}
        """
}