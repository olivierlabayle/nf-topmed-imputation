function cli_settings()
    s = ArgParseSettings(
        description="TopMedImputation",
        add_version = true,
        commands_are_required = false,
        version=string(pkgversion(TopMedImputation))
    )

    @add_arg_table! s begin
        "write-imputation-split-lists"
            action = :command
            help = "Writes imputation split lists for TOPMed API."
        
        "impute"
            action = :command
            help = "Imputes genotypes using the TOPMed API."

        "get-topmed-download-list"
            action = :command
            help = "Download results list using the TOPMed API."

        "download-topmed-file"
            action = :command
            help = "Downloads a file from TOPMed."
    end

    @add_arg_table! s["download-topmed-file"] begin
        "job-id"
            arg_type = String
            required = true
            help = "job-id"

        "token-file"
            arg_type = String
            required = true
            help = "Path to TOPMed API token file."

        "file-info"
            arg_type = String
            required = true
            help = "Info of the file to be downloaded."

        "--md5-file"
            arg_type = String
            default = nothing
            help = "Optional file to check MD5 against (for imputed .zip files)."

        "--refresh-rate"
            arg_type = Int
            help = "Rate at which to refresh the job status."
            default = 120
    end

    @add_arg_table! s["write-imputation-split-lists"] begin
        "genotypes-prefix"
            arg_type = String
            required = true
            help = "Prefix to genotypes"

        "--output-prefix"
            arg_type = String
            help = "Prefix to output files."
            default = "topmed"

        "--n-samples-per-file"
            arg_type = Int
            help = "Number of samples per file."
            default = 20_000
    end

    @add_arg_table! s["get-topmed-download-list"] begin
        "job-id"
            arg_type = String
            required = true
            help = "job-id"

        "token-file"
            arg_type = String
            required = true
            help = "Path to TOPMed API token file."

        "--refresh-rate"
            arg_type = Int
            help = "Rate at which to refresh the job status."
            default = 120
    end

    @add_arg_table! s["impute"] begin
        "genotypes-prefix"
            arg_type = String
            required = true
            help = "Prefix to genotypes"

        "token-file"
            arg_type = String
            required = true
            help = "Path to TOPMed API token file."

        "--password"
            arg_type = String
            help = "Password for the TOPMed API."
            default = "abcde"

        "--max-concurrent-submissions"
            arg_type = Int
            help = "Maximum number of concurrent submissions to the TOPMed API."
            default = 3

        "--refresh-rate"
            arg_type = Int
            help = "Rate at which to refresh the job status."
            default = 120

        "--r2"
            arg_type = Float64
            help = "R2 threshold for imputation."
            default = 0.8

        "--samples-per-file"
            arg_type = Int
            help = "Number of samples per file."
            default = 10_000

        "--output-prefix"
            arg_type = String
            help = "Output prefix for jobs files."
            default = "."
    end

    return s
end

function julia_main()::Cint
    settings = parse_args(ARGS, cli_settings())
    cmd = settings["%COMMAND%"]
    cmd_settings = settings[cmd]
    if cmd == "write-imputation-split-lists"
        write_imputation_split_lists(
            cmd_settings["genotypes-prefix"]; 
            output_prefix=cmd_settings["output-prefix"],
            samples_per_file=cmd_settings["n-samples-per-file"]
        )
    elseif cmd == "impute"
        impute(
            cmd_settings["genotypes-prefix"],
            cmd_settings["token-file"];
            password=cmd_settings["password"],
            max_concurrent_submissions=cmd_settings["max-concurrent-submissions"],
            refresh_rate=cmd_settings["refresh-rate"],
            r2=cmd_settings["r2"],
            output_prefix=cmd_settings["output-prefix"]
        )
    elseif cmd == "get-topmed-download-list"
        get_download_list_and_checksum(
            cmd_settings["job-id"], 
            cmd_settings["token-file"];
            refresh_rate=cmd_settings["refresh-rate"], 
        )
    elseif cmd == "download-topmed-file"
        download_topmed_file(
            cmd_settings["job-id"], 
            cmd_settings["token-file"],
            cmd_settings["file-info"];
            md5_file=cmd_settings["md5-file"],
            refresh_rate=cmd_settings["refresh-rate"]
            )
    else
        throw(ArgumentError(string("Unknown command: ", cmd)))
    end
    return 0
end