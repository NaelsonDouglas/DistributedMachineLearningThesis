@everywhere using Distributions

###
#  Generate a set of input data of a specific size based on a multivariate normal distribution.
###
@everywhere generate_inputs(mean, var, data_size) = transpose(rand(MvNormal(mean, var), data_size))
@everywhere generate_inputs_diag(mean, sigma, data_size) = transpose(rand(DiagNormal(mean, sig), data_size)) 
@everywhere generate_inputs_dir(alphas, data_size) = transpose(rand(Dirichlet(alphas), data_size))

###
#  Group of test mathematical functions to generate synthetic output (label) data.
###
@everywhere f1(x1, x2) = sin.(x1).*sin.(x2)./(x1.*x2) + rand(Normal(0,0.1),size(x1)[1])

#@everywhere f2(x1, x2, x3) = (1 + x1.^(0.5)+x2.^(-1) + x3.^(1.5)).^2 + rand(Normal(0,0.1),size(x1)[1])

@everywhere f2(x1, x2, x3) = 0.01.*x1 + 0.02.*x2.^(2) + 0.9.*x3.^(3) + rand(Normal(0,0.1),size(x1)[1])

@everywhere f3(x1, x2) = 0.6.*x1 + 0.3.*x2 + rand(Normal(0,0.1),size(x1)[1])

@everywhere f4(x1, x2, x3, x4, x5) = 10.*sin.(pi.*x1.*x2) + 20(x3-0.5).^2 + 10.*x4 + 5.*x5 + rand(Normal(0,0.1),size(x1)[1])

@everywhere f10(x) = 10.*sin.(pi.*x[:,1].*x[:,2]) + 20(x[:,3]-0.5).^2 + 10.*x[:,4] + 5.*x[:,5] + 10.*sin.(pi.*x[:,6].*x[:,7]) + 20(x[:,8]-0.5).^2 + 10.*x[:,9] + 5.*x[:,10] + rand(Normal(0,0.1),size(x[:,1])[1])
###
#  Generate a matrix of input and label data. In this work, the input data is based
#  on a multivariate normal distribution and the labels are constructed using four
#  different function choices. The output_function can be one of f1, f2, f3 or f4
#  and it should be a function object.
###
@everywhere function generate_data(output_function::Function = f1, data_size = 10000, num_nodes = 2, dims = 10, 
    positions = [])
    #positions = [0.5, 0.5, 50.]
    #distributions = ["normal", "normal"]
    config = ""
    file="dataset_config.txt"
    f = open("Data"*"/"*file, "r")
    for l in eachline(f)
        config = config*l
    end
    
    positions, distributions = split(config, "|")
    positions = map(x->parse(Float64, x), split(positions,','))
    distributions = split(replace(distributions, "\n", ""), ",")

    #archivo="dataset_outputs.txt"
    #open("Data"*"/"*archivo, "a") do f
    #    write(f, join(map(x->string(x),positions),",")*"|"*join(distributions,",")*"\n")
    #end

    node_id = myid()

    # introspecting the output_function, we want to know how many parameters it has
    out_fn_table = methods(output_function)

    mod_node = float(node_id % num_nodes)
    
    dim = length(out_fn_table)
    if dim == 1
        dim = dims
    end
    mod_distance = 2.
    
    if length(positions) == 0 
        mean_value = randn(1) * mod_node * mod_distance
    else
        mean_value = positions[Int(mod_node) + 1]
        #mean_value = randn(1) * mean_value
    end
    mean_value = mean_value[1]

    if dim == 2
        # for pair nodes mean is going to be [0.0;0.0]. For odds is [2.0;2.0].
        mean_vector = [2*mean_value;2*mean_value]
        var_vector = [1.0 0.0;0.0 1.0]
        # generating synthetic data
        dataset_input = generate_inputs(mean_vector, var_vector, data_size)
        dataset_output = output_function(dataset_input[:,1], dataset_input[:,2])
    elseif dim == 3
        # for pair nodes mean is going to be [0.0;0.0;0.0]. For odds is [1.0;1.0;1.0].
        if distributions[Int(mod_node) + 1] == "dirichlet"
            mean_vector = [0.5;0.5;0.5]
            var_vector = [1.0 0.0 0.0;0.0 1.0 0.0; 0.0 0.0 1.0]
            #var_vector = [0.025 0.0075 0.00175;0.0075 0.0070 0.00135; 0.00175 0.00135 0.00043]
            # generating synthetic data
            dataset_input = generate_inputs(mean_vector, var_vector, data_size)
            dataset_output = output_function(dataset_input[:,1], dataset_input[:,2],dataset_input[:,3])
        else
            mean_vector = [0.5;0.5;0.5]
            var_vector = [1.0 0.0 0.0;0.0 1.0 0.0; 0.0 0.0 1.0]
            # generating synthetic data
            dataset_input = generate_inputs(mean_vector, var_vector, data_size)
            dataset_output = output_function(dataset_input[:,1], dataset_input[:,2],dataset_input[:,3])
        end
    elseif dim == 4
        mean_vector = [2*mean_value;2*mean_value;2*mean_value;2*mean_value]
        var_vector = [1.0 0.0 0.0 0.0;0.0 1.0 0.0 0.0; 0.0 0.0 1.0 0.0; 0.0 0.0 0.0 1.0]
        # generating synthetic data
        dataset_input = generate_inputs(mean_vector, var_vector, data_size)
        dataset_output = output_function(dataset_input[:,1], dataset_input[:,2],dataset_input[:,3],dataset_input[:,4])
    elseif dim == 5
        mean_vector = [2*mean_value;2*mean_value;2*mean_value;2*mean_value;2*mean_value]
        var_vector = [1.0 0.0 0.0 0.0 0.0;0.0 1.0 0.0 0.0 0.0; 0.0 0.0 1.0 0.0 0.0; 0.0 0.0 0.0 1.0 0.0; 0.0 0.0 0.0 0.0 1.0]
        # generating synthetic data
        dataset_input = generate_inputs(mean_vector, var_vector, data_size)
        dataset_output = output_function(dataset_input[:,1], dataset_input[:,2],dataset_input[:,3],dataset_input[:,4],dataset_input[:,5])
    else
        # TODO: In this case we assume dim is given, I should modify old code to make it this way too
        if length(positions) == 0
            # Assume normal in this case
            mean_vector = Array{Float32}([m for m in fill(mean_value, dim)])
        else
            mean_vector = Array{Float32}(fill(mean_value, dim))
            println(mean_vector)
        end
        var_vector = eye(dim, dim)
        #var_vector = var_vector .* 10.
        if length(positions) == 0
            dataset_input = generate_inputs(mean_vector, var_vector, data_size)
        else
            if distributions[Int(mod_node) + 1] == "dirichlet"
                #mean_vector = [1.0, 0.1, 0.1, 1.0, 10., 4., 0.1, 0.1, 10., 20.]
                #mean_vector = Array{Float32}([mod_distance*m for m in fill(mod_node, dim)])
                dataset_input = generate_inputs_dir(mean_vector, data_size)
                
            else
                dataset_input = generate_inputs(mean_vector, var_vector, data_size)
            end
        end
    
        dataset_output = output_function(dataset_input)
    end


    return dataset_input, dataset_output
end
