include { GetPrefix; GetJuliaCmd } from './modules/utils.nf'
include { WriteImputationSplitLists } from './modules/imputation_list.nf'
include { MakeVCFSplit } from './modules/vcf_split.nf'
include { TOPMedImputation } from './modules/topmed_imputation.nf'
include { GetTOPMedDownloadList } from './modules/topmed_download_list.nf'
include { DownloadTOPMedZipFile } from './modules/topmed_download.nf'
include { UnzipTOPMedFile } from './modules/unzip_topmed_file.nf'
include { MergeVCFsByChr } from './modules/merge_vcfs.nf'
include { IndexVCF } from './modules/index_vcf.nf'
include { QCMergedImputedFile } from './modules/qc_imputed_file.nf'
include { BCFToPGEN } from './modules/vcf_to_pgen.nf'
include { DownloadReferenceGenome } from './modules/download_reference_genome.nf'

workflow {
    topmed_api_token = file(params.TOPMED_TOKEN_FILE)
    bed_genotypes = Channel.fromPath("${params.GENOTYPES_PREFIX}.{bed,bim,fam}").collect()
    // Send for Imputation or retrieve jobs list
    if (params.TOPMED_JOBS_LIST == "NO_TOPMED_JOBS") {
        split_files = WriteImputationSplitLists(bed_genotypes)
        chrs_samples_split_files = split_files.chromosomes.splitText(){x -> x[0..-2]}
            .combine(split_files.samples.flatten())
        vcf_splits = MakeVCFSplit(
            bed_genotypes,
            chrs_samples_split_files
        )
        jobs_files = TOPMedImputation(topmed_api_token, vcf_splits.collect())
        job_ids = jobs_files
            .flatten()
            .splitText()
            .map { it -> it.trim() }
    }
    else {
        job_ids = Channel.fromList(params.TOPMED_JOBS_LIST)
    }
    // Download Reference Genome
    ref_genome = DownloadReferenceGenome()
    // Download TOPMed files
    files_to_download = GetTOPMedDownloadList(topmed_api_token, job_ids)
    zip_files_infos = files_to_download.zip_files.transpose()
    md5_files = files_to_download.md5_file.transpose()
    md5_to_zip_files_infos = md5_files.combine(zip_files_infos, by: 0)
    zip_files = DownloadTOPMedZipFile(md5_to_zip_files_infos, topmed_api_token)
    // Unzip TOPMed files
    unziped_files = UnzipTOPMedFile(zip_files)
    // Merge VCFs by chromosome
    imputed_files = unziped_files.dose.flatten()
    indices = IndexVCF(imputed_files)
    imputed_files_and_indices_by_chr = imputed_files
        .concat(indices)
        .map { it -> [it.getName().tokenize(".")[1], it]}
        .groupTuple()
    chr_vcfs = MergeVCFsByChr(imputed_files_and_indices_by_chr)
    // QC merged VCFs
    qced_vcfs_chrs = QCMergedImputedFile(chr_vcfs, ref_genome)
    // Convert VCFs to PGEN
    BCFToPGEN(qced_vcfs_chrs)
}
