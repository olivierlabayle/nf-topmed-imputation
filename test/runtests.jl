using TopMedImputation
using Test
using CSV
using DataFrames

TESTDIR = joinpath(pkgdir(TopMedImputation), "test")

@testset "TopMedImputation.jl" begin
    # Test write-imputation-split-lists
    tmpdir = mktempdir()
    output_prefix = joinpath(tmpdir, "topmed")
    genotypes_prefix = joinpath(TESTDIR, "assets", "genotypes", "cohort")
    copy!(ARGS, [
        "write-imputation-split-lists",
        genotypes_prefix,
        "--output-prefix=$output_prefix",
        "--n-samples-per-file=1000"
    ])
    julia_main()
    @test readlines(string(output_prefix, ".chromosomes.txt")) == string.("chr", 1:22)
    batch_1 = CSV.read(joinpath(tmpdir, "topmed.samples_1_1000.keep"), DataFrame, header=["FID", "IID"])
    batch_2 = CSV.read(joinpath(tmpdir, "topmed.samples_1001_2000.keep"), DataFrame, header=["FID", "IID"])
    batch_3 = CSV.read(joinpath(tmpdir, "topmed.samples_2001_2293.keep"), DataFrame, header=["FID", "IID"])
    all_batched_samples = vcat(batch_1, batch_2, batch_3)
    original_samples = TopMedImputation.read_fam(string(genotypes_prefix, ".fam"))
    @test original_samples[!, [:FID, :IID]] == all_batched_samples
    rm(tmpdir, recursive=true)
end
