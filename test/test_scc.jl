using Test
using Mimi

m = getpage("RCP4.5 & SSP2", true, true, true)
run(m)
uds = [undiscount_scc(m, 2020), undiscount_scc(m, 2040), undiscount_scc(m, 2075)]
uds_compare = [0.8765, 0.5279, 0.2162] # From Excel PAGE-ICE
@test uds ≈ uds_compare rtol=1e-4

function checksccs(sccs, scccomp; n::Int = 1000)
    sccobs = [quantile(sccs, [.05, .25, .5, .75, .95]); mean(sccs)]
    sccerror = abs.((sccobs - scccomp) ./ [10, 1, 1, 1, 10, 1])
    sccsd = std(sccs) / sqrt(n)
    @test all(sccerror .< 3*sccsd) # average off by < 3x SD
end

n = 1000

m = getpage("RCP4.5 & SSP2", true, true, true)
sccs = compute_scc_mcs(m, n, year=2020)
# TODO - get the baseline values to test against!
# checksccs(sccs, [37.031, 89.742, 161.868, 299.439, 847.020, 261.739]; n = n)

m = getpage("RCP8.5 & SSP5", true, true, true)
sccs = compute_scc_mcs(m, n, year=2020)
# TODO - get the baseline values to test against!
# checksccs(sccs, [], n = n)

m = getpage("RCP4.5 & SSP2", true, true, false)
sccs = compute_scc_mcs(m, n, year=2020)
# TODO - get the baseline values to test against!
# checksccs(sccs, [53.903, 129.330, 217.337, 361.739, 886.998, 306.914], n = n)

m = getpage("RCP8.5 & SSP5", true, true, false)
sccs = compute_scc_mcs(m, n, year=2020)
# TODO - get the baseline values to test against!
# checksccs(sccs, [], n = n)
