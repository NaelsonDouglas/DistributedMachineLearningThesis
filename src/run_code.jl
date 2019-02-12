include("call_experiment.jl")


if length(ARGS) < 7
  eroor("You need to specify all variables")
  quit()

n_of_procs = ARGS[1]
n_of_examples = ARGS[2]
funcion = ARGS[3]
seed = ARGS[4]
num_nodes = ARGS[5]
dims = ARGS[6]
version = ARGS[7]
args = [n_of_procs, n_of_examples, funcion, seed, num_nodes, dims, version]
folder = execute_experiment(args)
