#@everywhere using Mocha
@everywhere using MultivariateStats
@everywhere using JLD
@everywhere using Mocha


include("datasets.jl")
include("statistics.jl")

###
#  Generate the node data.
#
#  output_function: function to generate the data
#  data_size: number of examples to generate
#  Returns: tuple where the first element is the input data and the second
#           element is the output data (labels)
###
@everywhere function generate_node_data(output_function::Function = f1, data_size = 10000, num_nodes=2, dims=2)
    # Cambie f1 por output_function
    
    # Read positions for nodes
    
    dataset_input, dataset_output = generate_data(output_function, data_size, num_nodes, dims)
    # serialize data to use it later
    if !isdir("Data")
        mkdir("Data")
    end
    id = string(myid())
    if !isdir("Data/data_"*id)
        mkdir("Data/data_"*id)
    end
    save("Data/data_"*id*"/input.jld", "dataset_input", dataset_input)
    save("Data/data_"*id*"/output.jld", "dataset_output", dataset_output)

    examples, attributes = try
        e, a = size(dataset_input)
    catch
        size(dataset_input)[1], 1
    end

    return examples, attributes
end

###
#  Generate the node test data.
#
#  output_function: function to generate the data
#  data_size: number of examples to generate
#  Returns: tuple where the first element is the input data and the second
#           element is the output data (labels)
###
@everywhere function generate_test_data(output_function::Function = f1, data_size = 10000, num_nodes=2, dims=2)
    #Cambie f1 por output_function
    dataset_input, dataset_output = generate_data(output_function, data_size, num_nodes, dims)
    # serialize data to use it later
    if !isdir("Data")
        mkdir("Data")
    end
    id = string(myid())
    if !isdir("Data/data_"*id)
        mkdir("Data/data_"*id)
    end
    save("Data/data_"*id*"/input_test.jld", "dataset_input", dataset_input)
    save("Data/data_"*id*"/output_test.jld", "dataset_output", dataset_output)

    examples, attributes = try
        e, a = size(dataset_input)
    catch
        size(dataset_input)[1], 1
    end

    return examples, attributes
end

###
#  Returns the data labels from the actual node.
###
@everywhere function get_output_data()
    id = string(myid())
    datalabels = load("Data/data_"*id*"/output_test.jld", "dataset_output")
    return datalabels
end

@everywhere function compute_stats_train(datainput)
    id = string(myid())
    stats = [mean(datainput, 1); var(datainput, 1)]
    if !isdir("Data/stats_"*id)
        mkdir("Data/stats_"*id)
    end
    save("Data/stats_"*id*"/stats_train.jld", "stats_train", stats)
    return stats
end

@everywhere function read_stats_train()
    id = string(myid()) 
    stats = load("Data/stats_"*id*"/stats_train.jld", "stats_train")
    return stats
end

@everywhere function standarize_dataset(datainput, stats)
    means = stats[1,:]
    vars = stats[2,:]
    datainput_standard = (datainput .- means') ./ vars'
    return datainput_standard
end

###
#  Calculates the maximum and minimum of the generated dataset for a node.
#
#  Returns: vector where every i element is a tuple with the min and max of the
#				    i attribute.
###
@everywhere function calculate_maxmin()
    id = string(myid())
    # load serialized data
    input_data = load("Data/data_"*id*"/input.jld", "dataset_input")
    get_maxmin(input_data)
end

###
#  Generate the histogram of the dataset on a node using as limits the global
#  maximum and minimum of the entire experiment.
#
#  globalmaxmin: globalmaxmin: matrix where every column is the min (1) and max (2) value of
#                an attribute from the dataset. It should have n columns where
#                n is the number of attributes of the dataset.
#  Returns: vector or matrix of weights of the calculated histogram.
###
@everywhere function calculate_histogram(globalmaxmin)
    id = string(myid())
    # load serialized data
    input_data = load("Data/data_"*id*"/input.jld", "dataset_input")
    create_histogram(input_data, globalmaxmin)
end

@everywhere function calculate_statistics()
    id = string(myid())
    input_data = load("Data/data_"*id*"/input.jld", "dataset_input")
    return summary_statistics(input_data)
end

@everywhere function calculate_order_statistics()
    id = string(myid())
    input_data = load("Data/data_"*id*"/input.jld", "dataset_input")
    return order_statistics(input_data)
end

@everywhere function shufflerows!{T<:Real}(a::AbstractArray{T})
    for i = size(a, 1):-1:2
        j = rand(1:i)
        a[i,:], a[j,:] = a[j,:], a[i,:]
    end
    return a
end

###
#  Trains a multi layer perceptron on the input dataset using the labels passed
#  as a parameter. Uses Mocha to train the MLP, so a model is stored on the
#  snapshot_node_id directory.
#
#  Returns: string containing the directory where the model is stored
###

@everywhere function train_local_model()
    id = string(myid())
    # load data from serialized
    datainput = load("Data/data_"*id*"/input.jld", "dataset_input")
    datalabels = load("Data/data_"*id*"/output.jld", "dataset_output")

    dataset=[datainput datalabels]


    #datainput_train=sub(datainput,1:round(Int,(*(0.8,examples))),1:atributtes)
    #datalabels_train=sub(datalabels,1:round(Int,(*(0.8,examples))),1)

    #datainput_val=sub(datainput,+(round(Int,(*(0.8,examples))),1):examples,1:atributtes)
    #exa,at=size(datainput_val)
    #datalabels_val=sub(datalabels,+(round(Int,(*(0.8,examples))),1):examples,1)
    maximo=Inf
    global neurona=0
    hidden_neurons = 20
    neurona = hidden_neurons
    
    dataset2=shufflerows!(dataset)
    examples, atributes = size(dataset2)
    datainput2=dataset2[:,1:atributes-1]
    datalabels2=dataset2[:,atributes]
    datainput_train=view(datainput2,1:round(Int,(*(0.8,examples))),1:atributes-1)
    datalabels_train=view(datalabels2,1:round(Int,(*(0.8,examples))),1)

    datainput_val=view(datainput2,+(round(Int,(*(0.8,examples))),1):examples,1:atributes-1)
    exa,at=size(datainput_val)
    datalabels_val=view(datalabels2,+(round(Int,(*(0.8,examples))),1):examples,1)

    # Standarization of dataset
    stats = compute_stats_train(datainput_train)
    datainput_train_st = standarize_dataset(datainput_train, stats)
    datainput_val_st = standarize_dataset(datainput_val, stats)
    #datainput_train_st = datainput_train
    #datainput_val_st = datainput_val
    backend = CPUBackend()
    init(backend)

    data_train_layer = MemoryDataLayer(name="data", data=Array[transpose(datainput_train_st), transpose(datalabels_train)], batch_size=100)
    data_val_layer = MemoryDataLayer(name="data", data=Array[transpose(datainput_val_st), transpose(datalabels_val)], batch_size=exa)

    ip_layer = InnerProductLayer(name="ip", output_dim=hidden_neurons, bottoms=[:data], tops=[:ip], neuron=Neurons.ReLU())
    ip2_layer = InnerProductLayer(name="ip2", output_dim=hidden_neurons, bottoms=[:ip], tops=[:ip2], neuron=Neurons.ReLU())
    aggregator = InnerProductLayer(name="aggregator", output_dim=1, tops=[:aggregator], bottoms=[:ip2] )
    layer_loss = SquareLossLayer(name="loss", bottoms=[:aggregator, :label])

    common_layers = [ip_layer, ip2_layer, aggregator]

    net = Net("MLP", backend, [data_train_layer;common_layers;layer_loss])

    method = Adam() # adam
    params = make_solver_parameters(method, max_iter=10000)
    solver = Solver(method, params)
    
    setup_coffee_lounge(solver, save_into="Snapshots/snapshots_"*id*"/statistics.jld", every_n_iter=1000)
    # report training progress every 1000 iterations
    add_coffee_break(solver, TrainingSummary(), every_n_iter=1000)

    val_net = Net("MLP", backend, [data_val_layer;common_layers;layer_loss])
    #add_coffee_break(solver, ValidationPerformance(val_net), every_n_iter=1000)  

    println("Creating snapshots dir for worker $id...")
    if !isdir("Snapshots")
        mkdir("Snapshots")
    end
    if !isdir("Snapshots/snapshots_"*id)
        mkdir("Snapshots/snapshots_"*id)
    end
    println("Adding coffee breaks...")
    add_coffee_break(solver, Snapshot("Snapshots/snapshots_"*id), every_n_iter=1000) 
    solve(solver, net)
    Mocha.dump_statistics(solver.coffee_lounge, get_layer_state(net, "loss"), true)
    destroy(net)
    destroy(val_net)
    shutdown(backend)
    directorio="Snapshots/snapshots_"*id
    open(directorio*"/"*"neuronas.txt", "w") do f
        write(f, "$neurona\n")
    end
    return "snapshots_"*id
end

###
#  Trains the global model for a worker. This is the model constructed from
#  the local models of the neighborhoods of a worker.
#
#  neighborhood: array of neighbors of the node i
#  Returns: a ridge regression model trained
###
@everywhere function train_global_model(neighborhood)
    id = string(myid())
    println("MY ID: ",id)
    # load data from serialized
    datainput = load("Data/data_"*id*"/input.jld", "dataset_input")
    datalabels = load("Data/data_"*id*"/output.jld", "dataset_output")
    stats = read_stats_train()
    datainput_st = standarize_dataset(datainput, stats)
    #datainput_st = datainput
    examples, attributes = try
        e, a = size(datainput)
    catch
        size(datainput)[1], 1
    end

    nofneighbors = length(neighborhood)
    secondleveldata = zeros(examples, nofneighbors+1)
    #backend = CPUBackend()
    #	init(backend)

    ordered_neighs = [myid()-1]
    for neighbor in neighborhood
        push!(ordered_neighs, neighbor)
    end
    ordered_neighs = sort(ordered_neighs)


    for (index, neighbor) in enumerate(ordered_neighs)

        backend = CPUBackend()
        init(backend)
        f = open("Snapshots/snapshots_"*string(neighbor+1)*"/neuronas.txt")
        lines = readlines(f)
        neuro=lines[1]
        close(f)
        neuron_number=parse(Int,neuro)
        println("Neurona: ",neuron_number)
        data_layer = MemoryDataLayer(name="data", data=Array[transpose(datainput), transpose(datalabels)], batch_size=examples)
        ip_layer = InnerProductLayer(name="ip", output_dim=neuron_number, bottoms=[:data], tops=[:ip], neuron=Neurons.ReLU())
        ip2_layer = InnerProductLayer(name="ip2", output_dim=neuron_number, bottoms=[:ip], tops=[:ip2], neuron=Neurons.ReLU())
        aggregator = InnerProductLayer(name="aggregator", output_dim=1, tops=[:aggregator], bottoms=[:ip2] )

        common_layers = [ip_layer, ip2_layer, aggregator]
        net = Net("MLP", backend, [data_layer; common_layers])

        data = "Snapshots/snapshots_"*string(neighbor+1)*"/snapshot-010000.jld"
        load_snapshot(net, data)
        forward(net)
        secondleveldata[:,index] = transpose(net.output_blobs[:aggregator].data)
        destroy(net)
        shutdown(backend)
        println("Done with: ", index)
    end

    #shutdown(backend)

    model = ridge(secondleveldata, datalabels, 10)

    return model
end

@everywhere function evaluate_test_data_with_local_models(nodes, batch_size)
    output_predictions = zeros(nodes, batch_size)
    id = string(myid())
    datainput = load("Data/data_"*id*"/input_test.jld", "dataset_input")
    dataoutput = load("Data/data_"*id*"/output_test.jld", "dataset_output")
    # Standarization of dataset
    stats = read_stats_train()
    datainput_st = standarize_dataset(datainput, stats)
    #datainput_st = datainput
    for node in 1:nodes
        backend = CPUBackend()
        init(backend)
        f = open("Snapshots/snapshots_"*string(node+1)*"/neuronas.txt")
        lines = readlines(f)
        neuro=lines[1]
        close(f)
        neuron_number=parse(Int,neuro)
        data_layer = MemoryDataLayer(name="data", data=Array[transpose(datainput_st), transpose(dataoutput)], batch_size=batch_size)
        ip_layer = InnerProductLayer(name="ip", output_dim=neuron_number, bottoms=[:data], tops=[:ip], neuron=Neurons.ReLU())
        ip2_layer = InnerProductLayer(name="ip2", output_dim=neuron_number, bottoms=[:ip], tops=[:ip2], neuron=Neurons.ReLU())
        aggregator = InnerProductLayer(name="aggregator", output_dim=1, tops=[:aggregator], bottoms=[:ip2] )

        common_layers = [ip_layer, ip2_layer, aggregator]
        net = Net("MLP", backend, [data_layer; common_layers])
        data = "Snapshots/snapshots_"*string(node+1)*"/snapshot-010000.jld"
        load_snapshot(net, data)
        forward(net)
        output_predictions[node, :] = transpose(net.output_blobs[:aggregator].data)
        destroy(net)
        shutdown(backend)
    end

    return output_predictions
end
