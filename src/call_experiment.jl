ARGS =["3", "20", "f1", "1234", "4", "2"]
include("master_summary.jl")

function experiment(args...)
	global ARGS = collect(map(string,args))
	execute_experiment()
end