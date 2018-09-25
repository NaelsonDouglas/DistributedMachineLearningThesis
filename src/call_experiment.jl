args =["3", "20", "f1", "1234", "4", "2"]
include("master_summary.jl")

function experiment(_args...=args)
	execute_experiment(args)
end