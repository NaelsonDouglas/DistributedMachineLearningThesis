#@everywhere using Mocha
@everywhere using MultivariateStats
@everywhere using JLD
@everywhere using Keras

@everywhere import Keras.Layers: Dense, Activation
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
    datalabels = load("Data/data_"*id*"/output.jld", "dataset_output")
    return datalabels
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
    
    dataset2=shufflerows!(dataset)
    examples, atributes = size(dataset2)
    datainput2=dataset2[:,1:atributes-1]
    datalabels2=dataset2[:,atributes]
    datainput_train=sub(datainput2,1:round(Int,(*(0.8,examples))),1:atributes-1)
    datalabels_train=sub(datalabels2,1:round(Int,(*(0.8,examples))),1)

    datainput_val=sub(datainput2,+(round(Int,(*(0.8,examples))),1):examples,1:atributes-1)
    exa,at=size(datainput_val)
    datalabels_val=sub(datalabels2,+(round(Int,(*(0.8,examples))),1):examples,1)

    model = Sequential()
    add!(model, Dense(25, input_dim=attributes))
    add!(model, Activation(:relu))

    add!(model, Dense(10))
    
    compile!(model; loss=:mse, optimizer=:sgd, metrics=[:mse])
    
    h = fit!(model, datainput_train, datalabels_train; nb_epoch=100, batch_size=32, verbose=1)    

    println("Creating snapshots dir for worker $id...")
    if !isdir("Snapshots")
        mkdir("Snapshots")
    end
    if !isdir("Snapshots/snapshots_"*id)
        mkdir("Snapshots/snapshots_"*id)
    end
    #model.save_weights("Snapshots/snapshots_"*id"/weights_memn2n_sumproduct.hdf5", overwrite=True)    
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


    model = ordered_neighs
    return model
end

@everywhere function evaluate_test_data_with_local_models(nodes, batch_size)
    output_predictions = zeros(nodes, batch_size)
    id = string(myid())
    datainput = load("Data/data_"*id*"/input_test.jld", "dataset_input")
    dataoutput = load("Data/data_"*id*"/output_test.jld", "dataset_output")
    output_predictions = dataoutput
    return output_predictions
end
