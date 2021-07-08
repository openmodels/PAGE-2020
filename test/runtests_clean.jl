## Primary testing file for CI, slower and more thorough testing, including two tests 
## that are not run in `runtests.jl`:

# (1) We only run tests for the SCC here since they are fairly slow
# (2) We only run tests for the extensions here since they too are slow, and 
#     also clean out the output folders

using Test
using Mimi

# include the main model
include("../src/main_model.jl")

@testset "MimiPAGE2020-main" begin
    include("runtests.jl")
end

@testset "MimiPAGE2020-extra" begin
    include("test_scc.jl") # Takes very long to run.
    include("test_extensions.jl") # NB will currently clean out the 'output' folder! - tests number of model extension output files for PAGE2020 update
end
