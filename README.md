# TopMedImputation

[![Build Status](https://github.com/olivierlabayle/TopMedImputation.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/olivierlabayle/TopMedImputation.jl/actions/workflows/CI.yml?query=branch%3Amain)


This Nextflow workflow sends the genotypes for imputation to [TOPMed](https://imputation.biodatacatalyst.nhlbi.nih.gov/#!pages/home), downloads and aggregates the results per chromosome. It follows the principles provided in their [documentation](https://topmedimpute.readthedocs.io/en/latest/).

!!! note "Platform"
    The volume of data downloaded can be very large, so make sure you have enough disk space available.


## Running The Workflow

If the previous steps have been completed successfully you can run:

```bash
nextflow run main.nf -profile eddie -resume -with-report -with-trace -c conf/run.config
```

- The `eddie` profile provides the platform specific parameters and is only to be used by University of Edinburgh researchers on the [Eddie platform](https://digitalresearchservices.ed.ac.uk/resources/eddie).
- The `conf/run.config` provides the inputs to the pipeline (see below)

!!! note "Crash"
    The `TOPMedImputation` process waits for TOPMed imputation jobs to finish, which might be longer than the maximum eddie job duration (48h) depending on the server's queue size. In that case, the workflow will crash but all the TOPMed jobs should have been submitted. Resuming the workflow will thus not work and it will try to resubmit new jobs. In order to bypass this behaviour you can pass an optional `TOPMED_JOBS_LIST` to proceed directly to the download stage. These job ids can be obtained from the TOPMed urls.

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

### Secondary Options

- `TOPMED_REFRESH_RATE` (default: 180): The frequency (in seconds) with which the workflow will monitor the imputation process to send further jobs.
- `TOPMED_MAX_PARALLEL_JOBS` (default: 3): The maximum number of concurrent imputation processes, this is limited to 3 at the moment by TOPMed.

## Imputation Outputs

All outputs are produced in `PUBLISH_DIR` (defaults to `results`), the main outputs of the workflow are:

- `chr_P.qced.{pgen,pvar,psam}`: A set of imputed genotypes, one for each chromosome in PGEN format.