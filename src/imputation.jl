"""
    read_bim(file)

Columns Description from: https://www.cog-genomics.org/plink/1.9/formats#bim
- Chromosome code (either an integer, or 'X'/'Y'/'XY'/'MT'; '0' indicates unknown) or name
- Variant identifier
- Position in morgans or centimorgans (safe to use dummy value of '0')
- Base-pair coordinate (1-based; limited to 231-2)
- Allele 1 (corresponding to clear bits in .bed; usually minor)
- Allele 2 (corresponding to set bits in .bed; usually major)
"""
read_bim(file) = CSV.read(
    file, 
    DataFrame, 
    delim='\t', 
    header=["CHR_CODE", "VARIANT_ID", "POSITION", "BP_COORD", "ALLELE_1", "ALLELE_2"]
)

"""
    read_fam(file)

Columns Description from: https://www.cog-genomics.org/plink/1.9/formats#fam
- Family ID ('FID')
- Within-family ID ('IID'; cannot be '0')
- Within-family ID of father ('0' if father isn't in dataset)
- Within-family ID of mother ('0' if mother isn't in dataset)
- Sex code ('1' = male, '2' = female, '0' = unknown)
- Phenotype value ('1' = control, '2' = case, '-9'/'0'/non-numeric = missing data if case/control)
"""
read_fam(file) = CSV.read(
    file, 
    DataFrame, 
    header=["FID", "IID", "FATHER_ID", "MOTHER_ID", "SEX", "PHENOTYPE"]
)

function write_sample_batches(prefix; output_prefix="cohort_to_impute", samples_per_file=5_000)
    fam = read_fam(string(prefix, ".fam"))
    return map(Iterators.partition(1:nrow(fam), samples_per_file)) do indices
        filename = string(output_prefix, ".samples_", indices[1], "_", indices[end], ".keep")
        CSV.write(filename, fam[indices, [:FID, :IID]], delim=' ', header=false)
    end
end

function write_chromosome_list(genotypes_prefix; output_prefix="cohort_to_impute")
    bim = read_bim(string(genotypes_prefix, ".bim"))
    open(string(output_prefix, ".chromosomes.txt"), "w") do io
        for chr in unique(bim.CHR_CODE)
            println(io, chr)
        end
    end
end

function get_vcf_files_channel(genotypes_prefix)
    dir = dirname(genotypes_prefix)
    dir = dir == "" ? "." : dir
    vcf_files = filter(x -> occursin(genotypes_prefix, x), readdir(dir, join=true))
    samples = [split(basename(f), ".")[end-2] for f in vcf_files]
    chromosomes = [split(basename(f), ".")[2] for f in vcf_files]
    vcf_files_df = DataFrame(FILE=vcf_files, SAMPLES=samples, CHR=chromosomes)
    return Channel() do channel
        for (key, group) in pairs(groupby(vcf_files_df, :SAMPLES))
            put!(channel, (key.SAMPLES, group))
        end
    end
end

function send_job_to_topmed(group, jobname, token, password; r2=0.8, check_allele_freq="all")
    cmd = Cmd([
        "curl", 
        "https://imputation.biodatacatalyst.nhlbi.nih.gov/api/v2/jobs/submit/imputationserver2",
        "-X", "POST",
        "-H", "X-Auth-Token: $token",
        "-F", "job-name=$jobname",
        [string("-F files=@$(realpath(f))") for f in group.FILE]...,
        "-F", "refpanel=apps@topmed-r3",
        "-F", "build=hg38",
        "-F", "phasing=eagle",
        "-F", "password=$password",
        "-F", "population=all",
        "-F", "meta=yes",
        "-F", "r2Filter=$r2",
        "-F", "population=$check_allele_freq"
    ])
    job_details = JSON.parse(read(cmd, String))
    job_details["success"] == true || throw(error(job_details["message"]))
    return job_details
end

function get_job_status(job_id, token)
    cmd = Cmd([
        "curl", 
        "-H", "X-Auth-Token: $token", 
        string("https://imputation.biodatacatalyst.nhlbi.nih.gov/api/v2/jobs/$job_id")
    ])
    return JSON.parse(read(cmd, String))
end

function wait_for_completion(token, job_id; rate=60)
    while true
        status = get_job_status(job_id, token)
        state = status["state"]
        if state == 5 || state == 6
            throw(error("Job $job_id failed."))
        elseif state == 4
            return status
        else
            sleep(rate)
        end
    end
end

function get_download_list(status)
    download_list = Dict()
    for output in status["outputParams"]
        if output["name"] == "output"
            for file_dict in output["files"]
                filename = file_dict["name"]
                # Only download imputed chromosomes
                if startswith(filename, "chr")
                    chr = split(filename, ".")[1]
                    file_type = endswith(filename, "md5") ? "md5" : "data"
                    if haskey(download_list, chr)
                        download_list[chr][file_type] = file_dict
                    else
                        download_list[chr] = Dict(file_type => file_dict)
                    end
                end
            end
        end
    end
    return download_list
end

function has_download_suceeded(output_file)
    # If the number of max downloads are exceeded, then the content of the file will be a JSON with success=false
    first_line = readline(output_file)
    try
        content = JSON.parse(first_line)
        if content["success"] == false && content["message"] == "number of max downloads exceeded."
            @info "Could not download file $output_file due to max downloads exceeded. Waiting."
            return false
        end
    catch
        return true
    end
end

function _download_topmed_file(file_dict, token, jobname; refresh_rate=360)
    file_hash = file_dict["hash"]
    file_name = file_dict["name"]
    output_file = string(jobname, ".", file_name)
    while true
        read(Cmd([
            "curl", "-sL", 
            string("https://imputation.biodatacatalyst.nhlbi.nih.gov/share/results/$file_hash/$file_name"),
            "-H", "X-Auth-Token: $token",
            "-o", output_file
        ]), String)
        if has_download_suceeded(output_file)
            return output_file
        else
            sleep(refresh_rate)
        end
    end
end

function send_to_topmed_and_write_job_id(channel, token, password; refresh_rate=120, r2=0.8, output_prefix="topmed", check_allele_freq="all")
    for (jobname, group) in channel
        job_details = send_job_to_topmed(group, jobname, token, password;r2=r2, check_allele_freq=check_allele_freq)
        job_id = job_details["id"]
        status = wait_for_completion(token, job_id; rate=refresh_rate)
        write(string(output_prefix, ".", job_id, ".txt"), job_id)
    end
end

function get_token(token_file)
    token = read(token_file, String)
    return endswith(token, "\n") ? token[1:end-1] : token
end

function get_download_list_and_checksum(job_id, token_file; refresh_rate=360)
    token = get_token(token_file)
    status = wait_for_completion(token, job_id; rate=refresh_rate)
    jobname = status["name"]
    download_list = get_download_list(status)
    # Write files to be downloaded
    for (chr, chr_dict_info) in download_list
        open(string(jobname, ".", chr, ".json"), "w") do io
            JSON.print(io, chr_dict_info)
        end
    end

    return 0
end

function download_topmed_file(job_id, token_file, file_info; refresh_rate=360)
    token = get_token(token_file)
    status = wait_for_completion(token, job_id; rate=refresh_rate)
    jobname = status["name"]
    file_dict = open(JSON.parse, file_info)
    # Download MD5
    md5_file = _download_topmed_file(file_dict["md5"], token, jobname; refresh_rate=refresh_rate)
    # Download Data File
    data_file = _download_topmed_file(file_dict["data"], token, jobname; refresh_rate=refresh_rate)
    # Check MD5
    data_file_md5 = readchomp(`md5sum $data_file`)
    data_file_md5 = split(data_file_md5, r"\s+")[1]
    expected_md5 = split(readline(md5_file), r"\s+")[1]
    expected_md5 == data_file_md5 ||
            throw("Downloaded file's md5 checksum does not match expected md5 checksum. ($data_file)")

    return 0
end

function write_imputation_split_lists(genotypes_prefix; output_prefix="cohort_to_impute", samples_per_file=20_000)
    write_sample_batches(genotypes_prefix; output_prefix=output_prefix, samples_per_file=samples_per_file)
    write_chromosome_list(genotypes_prefix; output_prefix=output_prefix)
end

function impute(genotypes_prefix, token_file; 
    password="abcde", 
    max_concurrent_submissions=3,
    refresh_rate=120,
    r2=0.8,
    check_allele_freq="all",
    output_prefix="cohort_to_impute"
    )
    token = get_token(token_file)
    # Split the bed file into smaller VCF files for each chromosome
    # Group files into a channel for submission
    vcf_files_channel = get_vcf_files_channel(genotypes_prefix)
    # Send for submission and download, maximum 3 concurrent tasks running at once on topmed
    tasks = [
        Threads.@spawn send_to_topmed_and_write_job_id(
            vcf_files_channel, 
            token, 
            password;
            check_allele_freq=check_allele_freq,
            refresh_rate=refresh_rate,
            r2=r2,
            output_prefix=output_prefix
        ) for _ in 1:max_concurrent_submissions
    ]

    for task in tasks
        wait(task)
    end

    return 0
end