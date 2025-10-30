process UnzipTOPMedFile {    
    input:
        path(zip_file)

    output:
        path("*.dose.vcf.gz"), emit: dose
        path("*.empiricalDose.vcf.gz"), emit: empirical_dose
        path("*.info.gz"), emit: info

    script:
        jobname = zip_file.getName().tokenize(".")[0]
        """
        unzip -P ${params.TOPMED_ENCRYPTION_PASSWORD} ${zip_file} -d temp_extract

        for f in temp_extract/*; do
            mv "\$f" "./${jobname}.\$(basename "\$f")"
        done
        """
}
