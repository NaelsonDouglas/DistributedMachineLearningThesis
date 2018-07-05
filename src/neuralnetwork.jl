@everywhere using Mocha

"""
  Train a multi-layer perceptron model using the specified number of hidden
  neurons and the input and label sets. It uses the implementation from the
  Mocha framework, so after the training a snapshot is saved in a folder
  using the id of the actual worker as the folder name.

  input: the input set.
  output: the labels of the input set.
  hidden_neurons: the number of neurons in the hidden layer.
  n_iter: max number of iterations of the solver (stochastic gradient descent).

  returns: the name of the folder where the snapshots are stored.
"""
@everywhere function train_mlp(input, output, hidden_neurons, n_iter = 1000)
	backend = CPUBackend()
	init(backend)

	data_layer = MemoryDataLayer(name="data", data=Array[input, output], batch_size=100)
	ip_layer = InnerProductLayer(name="ip", output_dim=hidden_neurons, bottoms=[:data], tops=[:ip], neuron=Neurons.Tanh())
	aggregator = InnerProductLayer(name="aggregator", output_dim=1, tops=[:aggregator], bottoms=[:ip] )
	layer_loss = SquareLossLayer(name="loss", bottoms=[:aggregator, :label])

	common_layers = [ip_layer, aggregator]

	net = Net("MLP", backend, [data_layer, common_layers, layer_loss])

	method = SGD() # stochastic gradient descent
	params = make_solver_parameters(method, max_iter=n_iter)
	solver = Solver(method, params)

	# report training progress every 1000 iterations
	add_coffee_break(solver, TrainingSummary(), every_n_iter=100)
	id = string(myid())
	println("Creating snapshots dir for worker $id...")
	mkdir("snapshots_" * id)
	#mkdir("snapshots")
	println("Adding coffee breaks...")
	add_coffee_break(solver, Snapshot("snapshots_" * id), every_n_iter=n_iter)
	solve(solver, net)
	Mocha.dump_statistics(solver.coffee_lounge, get_layer_state(net, "loss"), true)
	destroy(net)
	shutdown(backend)

	return "snapshots_" * id
end
