using Test
using Mimi

# Test that all models run
outdir = joinpath(@__DIR__, "../output")
samplesize = 10
rm(outdir, recursive=true) # NB !!cleans out the 'output' folder!!
mkdir(outdir)

include("../analysis/allscc/runmodel.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) == 88 # 4 scenario folders x 21 files + 4 SCC files = 88 files
rm(outdir, recursive=true)
mkdir(outdir)

include("../analysis/allscc/runmodel_growth.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) ==  4622
rm(outdir, recursive=true)
mkdir(outdir)

include("../analysis/allscc/runmodel_annual.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) ==  132
rm(outdir, recursive=true)
mkdir(outdir)

include("../analysis/allscc/runmodel_variability.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) ==  132
rm(outdir, recursive=true)
mkdir(outdir)

include("../analysis/allscc/runmodel_ARvariability.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) ==  124
rm(outdir, recursive=true)
mkdir(outdir)

include("../analysis/allscc/runmodel_annualGrowth.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) ==  313
rm(outdir, recursive=true)
mkdir(outdir)

include("../analysis/allscc/runmodel_annualGrowth_ARvariability.jl")
@test sum([length(files) for (root, dirs, files) in walkdir(outdir)]) == 313
rm(outdir, recursive=true)
mkdir(outdir)
