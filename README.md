# TopMedImputation

[![Build Status](https://github.com/olivierlabayle/nf-topmed-imputation/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/olivierlabayle/nf-topmed-imputation/actions/workflows/CI.yml?query=branch%3Amain)


This Nextflow workflow sends the provided genotypes for imputation to [TOPMed](https://imputation.biodatacatalyst.nhlbi.nih.gov/#!pages/home), it downloads and aggregates the results per chromosome and outputs plink2 PGEN filesets. It follows the principles provided in the [TOPMed documentation](https://topmedimpute.readthedocs.io/en/latest/).

> :warning: The volume of downloaded data can be very large, so make sure you have enough disk space available before running.


## Running The Workflow

To run the workflow, run:

```bash
nextflow run main.nf -profile PROFILE -resume -with-report -with-trace -c conf/run.config
```

where:

- The `PROFILE` profile provides the platform specific parameters. For University of Edinburgh researchers, the `eddie` profile can be used to run on the [Eddie platform](https://digitalresearchservices.ed.ac.uk/resources/eddie).
- The `conf/run.config` provides the inputs to the pipeline (see Workflow Parameters)

> :warning: The `TOPMedImputation` process waits for TOPMed imputation jobs to finish, which might be longer than the maximum job duration on your platform (e.g. 48h on Eddie). In that case, the workflow will crash but all the TOPMed jobs should have been submitted. Resuming the workflow will thus not work and it will try to resubmit new jobs. In order to bypass this behaviour you can provide the optional `TOPMED_JOBS_LIST` to proceed directly to the download stage. These job ids can be obtained from the TOPMed urls.

## Workflow Parameters

This is the list of all the pipeline's parameters, they can be set in the `run.config` file under the `params` section.

### Inputs Parameters

These must be provided:

- `GENOTYPES_PREFIX`: Prefix to genotypes files in plink BED format.
- `TOPMED_TOKEN_FILE`: Path to the file containing your TOPMed API token. See [this page](http://topmedimpute.readthedocs.io/en/latest/api/#authentication)

### Important Options

- `TOPMED_ENCRYPTION_PASSWORD`: An encryption password
- `TOPMED_JOBS_LIST`: If the workflow crashes and you want to resume, list the job-ids in this file (one per line). Job ids can be obtained from the job url in TOPMed.
- `N_SAMPLES_PER_IMPUTATION_JOBS` (default: 10000): We can only send file of less than 200000 samples to TOPMed and the server only allows 3 jobs at a time. This number ideally splits your data in 3 roughly equal batches.
- `IMPUTATION_R2_FILTER` (default: 0.9): Only imputed variants passing the threshold are kept, set to 0 if you want to keep them all.
- `ZIP_FILES_STORE_DIR` (default: `${launchDir}/topmed_zip_files`): Directory where the raw outputs from TOPMed will be stored. This is useful because TOPMed deletes jobs outputs from the servers after a week.

### Secondary Options

- `TOPMED_REFRESH_RATE` (default: 180): The frequency (in seconds) with which the workflow will monitor the imputation process to send further jobs.
- `TOPMED_MAX_PARALLEL_JOBS` (default: 3): The maximum number of concurrent imputation processes, this is limited to 3 at the moment by TOPMed.

## Imputation Outputs

All outputs are produced in `PUBLISH_DIR` (defaults to `results`), the main outputs of the workflow are:

- `$PUBLISH_DIR/chr_P.qced.{pgen,pvar,psam}`: A set of imputed genotypes, one for each chromosome in PGEN format.
- `$PUBLISH_DIR/topmed_outputs/*.zip`: Downloaded complete compressed archives from TOPMed.