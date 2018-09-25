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

function experiment(_args...=args)
	execute_experiment(args)
end