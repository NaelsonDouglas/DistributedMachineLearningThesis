using Clustering
using Mocha
using MultivariateStats
using JLD
using Logging
using CSV
using DataFrames
include("datasets.jl")
include("statistics.jl")
include("results_handler.jl")
include("docker/DockerizedJuliaWorker.jl")


args =["3", "20", "f1", "1234", "4", "2"]
include("master_summary.jl")

cids_pids_map  = Dict()
function experiment(_args...=args)
	cids_pids_map = Dict()
	rmalldockerworkers()
	execute_experiment(args)
end
