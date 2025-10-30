include { GetJuliaCmd } from 'modules/utils.nf'

process GetTOPMedDownloadList {
    input:
        path topmed_api_token_file
        val job_id

    output:
        tuple val(job_id), path("*.txt"), emit: info_files
        tuple val(job_id), path("*.zip"), emit: zip_files
        tuple val(job_id), path("*.md5", arity: 1), emit: md5_file
        tuple val(job_id), path("*.html", arity: 1), emit: report_file

    script:
        """
        ${GetJuliaCmd(task.cpus)} get-topmed-download-list \
            ${job_id} \
            ${topmed_api_token_file} \
            --refresh-rate ${params.TOPMED_REFRESH_RATE}
        """
}