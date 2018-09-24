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

###
#  Create the neighborhoods for every node using the histograms of the nodes.
#  This function doesn't need to be run on every node because the master has all
#  the information to calculate de neighborhoods.
#
#  histograms: vector containing all the histograms of the nodes.
#  Returns: vector where the i-th position is the cluster of the i-th node
###

#I'm putting it after the includes because if this is the first time you are executing the code, these includes will take too long to pre-compile and this time will be measured


EXECUTING_PATH = "./results/executing/"
start_time = Dates.format(Dates.now(),"yy-mm-dd-HH:MM:SS")

try
    mkpath("./results/incomplete/")
    mv(EXECUTING_PATH, string("./results/incomplete/",randstring() ))

    mkpath(EXECUTING_PATH*"train_global_model")
    mkpath(EXECUTING_PATH*"calculate_maxmin")
    mkpath(EXECUTING_PATH*"train_local_model")
catch
    mkpath(EXECUTING_PATH*"train_global_model")
    mkpath(EXECUTING_PATH*"calculate_maxmin")
    mkpath(EXECUTING_PATH*"train_local_model")
end

function create_neighborhoods_stats(stats, tolerance=0.05)
    tolerance = 0.
    nodes = length(stats)
    distances = eye(nodes) # distances matrix
    stats = transpose(reduce(hcat, stats))
    weights = 1./median(abs(stats .- median(stats,1)),1)

    nodes_neighbors = Array{Any}(nodes)

    for i in 1:nodes
        nodes_neighbors[i] = Int32[]
        for j in 1:nodes
            # calculate distance between node i and j only if their are different
            if i != j
                # TODO: we are only using the euclidean distance...
                distances[i,j] = distance(stats[i], stats[j], weights)
                if distances[i,j] < tolerance
                    push!(nodes_neighbors[i],j)
                end
            end
        end
    end
    return nodes_neighbors
end

function create_neighborhoods_stats_kmeans(stats)
    nodes = length(stats)
    distances = eye(nodes) # distances matrix
    stats = transpose(reduce(hcat, stats))
    weights = 1./median(abs.(stats .- median(stats,1)),1)

    nodes_neighbors = Array{Any}(nodes)

    for i in 1:nodes
        for j in 1:nodes
            if i != j
                distances[j,i] = distance(stats[i], stats[j], weights)

            end
        end
    end

    #KMEANS ALGORITHM
    k_winner = round(Int,(nodes/2))
    max = 0
    for j=2:round(Int,(nodes/2))

        clust_result = kmeans(stats', j; init=:kmcen, maxiter=:300)
        result = silhouettes(clust_result, distances)

        #Measuring performance of Clustering Method 1
        perf = []
        for x in result
            if !isnan(x)
                push!(perf,x)
            end
        end
        measure = mean(perf)

        println(measure)
        if measure >= max
            max = measure
            k_winner = j
        end
    end
    #println("K Ganador: ",k_ganador)
    clust_result=kmeans(stats', k_winner; init=:kmcen, maxiter=:300)
    neigh=assignments(clust_result)
    return neigh
end


function create_neighborhoods(histograms)
    nodes = length(histograms)
    distances = eye(nodes) # distances matrix
    for i in 1:nodes
        for j in i:nodes
            # calculate distance between node i and j only if their are different
            if i != j
                # TODO: we are only using the euclidean distance...
                distances[j,i] = calculate_distances(histograms[i], histograms[j])[2]
            end
        end
    end

    # apply hierarchical clustering to the distance matrix (it should be
    # symmetric)

    data_histo=eye(nodes,length(histograms[1]))

    for i=1:nodes
        data_histo[i,:]=reshape(map(x->convert(Float64,x),histograms[i]),1,length(histograms[i]))'
    end
    #HIERARCHICAL CLUSTERING
    #h = hclust(Symmetric(distances, :L), :complete)
    #neigh2 = cutree(h; k=3)

    # Future work: try other clustering algorithms such as:
    #   * SOM-STG: to provide dynamic clustering as new input data arrives
    #     * Paper: http://www.ncbi.nlm.nih.gov/pubmed/25203996
    #   * Quick Shift and Kernel Methods for Mode Seeking
    #     * Code: https://github.com/rened/QuickShiftClustering.jl
    #     * Paper: http://link.springer.com/chapter/10.1007%2F978-3-540-88693-8_52#page-1

    #### Change 0 and 1 to Boolean

    #KMEANS ALGORITHM
    k_ganador=round(Int,(nodes/2))
    maximo=0
    for j=2:round(Int,(nodes/2))

        clust_result=kmeans(data_histo', j; init=:kmcen, maxiter=:300)
        result=silhouettes(clust_result, distances)

        #Measuring performance of Clustering Method 1
        perf=[]
        for x in result
            if !isnan(x)
                push!(perf,x)
            end
        end
        measure=mean(perf)

        #Measureing performance of Clustering Method 2
        #measure=maximum(silhouettes(clust_result, distances))

        println(measure)
        if measure>=maximo
            maximo=measure
            k_ganador=j
        end
    end
    #println("K Ganador: ",k_ganador)
    clust_result=kmeans(data_histo', k_ganador; init=:kmcen, maxiter=:300)
    neigh=assignments(clust_result)
    return neigh
end



function run_experiments(nofworkers, nofexamples, func, num_nodes = 2, dim = 2)

    info("Adding ", nofworkers, " workers...\n")
    adddockerworkers(nofworkers,_prototype=true)

    #keep_analysing_conts = false
    @async begin
        g = open("results/executing/containers.csv","w+")
        header = "CONTAINER,CPU%,MEMUSAGE/LIMIT,MEM%,NETI/O,BLOCKI/O,PIDS,TIMESTAMP"
        write(g,header)
        while(true)
            sleep(5)
	    timestamp = start_time = string(Dates.format(Dates.now(),"HH:MM:SS"))
            for a in analyse_containers()
                write(g,"\n")
                write(g,a*","*timestamp)
            end

            flush(g) #TODO move this command out of the loop to avoid I/O. I'm keeping it inside by now for test purposes
        end
        close(g)
    end



    tic() #<-----elapsed_time
    Logging.configure(level=INFO)

    #addprocs(nofworkers)
    #workers

    info("Including workers code and functions...\n")
    include("workers.jl")

    info("Generating datasets and calculating maximums and minimums\n")
    nodes_maxmin = Array{Any}(nofworkers)
    metadata = Array{Any}(1)

    n_of_procs = parse(ARGS[1])
    tic() #Master maxmim
    @sync for (idx, pid) in enumerate(workers())
        @async begin
            metadata[1] = remotecall_fetch(generate_node_data, pid, eval(parse(func)), 1000, num_nodes, dim);
            remotecall_fetch(generate_test_data, pid, eval(parse(func)), 1000, num_nodes, dim);
            # Naelson: START Maximum and Minimum Time Measure!!!!!

            #DONE --- inside calculate_maxmin
            nodes_maxmin[idx] = remotecall_fetch(calculate_maxmin, pid);
            # Naelson: STOP Maximum and Minimum Time Measure!!!!!
        end
    end
    master_maxmim_time = toc() #Master maxmim
    master_maxmim_time = floor(master_maxmim_time,2)

    store_masterlog(master_maxmim_time, string("calculate_maxmin/","temp_",myid()),"calculate_maxmin_seconds")
    info("\n Merged maxmim logs")
    mergelogs("calculate_maxmin")






    examples, attributes = metadata[1]
    info("We have $(string(attributes)) attributes and $(string(examples)) examples\n")
    info("Calculating global max and global min...\n")

    info("Calculating histograms...")
    # Naelson: START Histogram Creation Share Time!!!!!



    tic()#Histogram time
    nodes_stats = Array{Any}(nofworkers)
    @sync for (idx, pid) in enumerate(workers())
        #@async nodes_stats[idx] = remotecall_fetch(pid, calculate_statistics);
        @async nodes_stats[idx] = remotecall_fetch(calculate_order_statistics, pid)[:];
    end
    #DONE
    # Naelson: STOP Histogram Creation Share Time!!!!!
    histogram_create_time = toc()#Histogram time
    histogram_create_time = floor(histogram_create_time,2)
    store_masterlog(histogram_create_time, "histogram_create_time","create_histogram_seconds",nofworkers)


    create_neighborhoods_stats_kmeans_time = 0
    tic() #Local models
    @sync begin
        info("Training local models\n")


        for (idx, pid) in enumerate(workers())
            # Naelson: START Local Training Time!!!!!
            @async remotecall_fetch(train_local_model, pid);
            # Naelson: STOP Local Training Time!!!!!
        end


        info("Calculating neighborhoods...\n")


        # Naelson: START Calculate Neighborhood Clustering Time!!!!!
        #neighborhoods = create_neighborhoods(nodes_histograms)
        #Done

        #Clustering/Neighborhood (part 1)
        tic() #kmeans (part of the clustering/neighboorhood. Using two pairs of tic/toc due to the code residing in two differente context blocks)
        neighborhoods = create_neighborhoods_stats_kmeans(nodes_stats)
        create_neighborhoods_stats_kmeans_time = toc() #kmeans Clustering/Neighborhood (part 1)

    end

    local_training_time = toc() #Local models
    local_training_time = floor(local_training_time,2)
    store_masterlog(local_training_time, string("train_local_model/","temp_",myid()),"local_training_seconds")
    info("\n Merged train local model logs")
    mergelogs("train_local_model")

    tic()  #Clustering/Neighborhood (part 2)
    info("Done training local models")
    info("Done calculating neighborhoods")

    info("Generating neighborhoods for every node\n")

    nodes_neighbors = Array{Any}(nofworkers)
    for (idx, pid) in enumerate(workers())
        nodes_neighbors[idx] = Int32[]
        for (idx2, elem) in enumerate(neighborhoods)
            if idx != idx2 && neighborhoods[idx] == elem
                push!(nodes_neighbors[idx], idx2)
            end
        end
    end
    print(nodes_neighbors)

    # Naelson: STOP Calculate Neighborhood (Clustering) Time!!!!!

    info("Done generating neighborhoods for every node")

    #Clustering/Neighborhood (part 2) //end
    clustering_time = toc() + create_neighborhoods_stats_kmeans_time
    clustering_time = floor(clustering_time,2)

    store_masterlog(clustering_time,"clustering_time","clustering_time_seconds",nofworkers)



    # Naelson: START Train Global Model Time!!!!!
    #Done inside the train_global_model function. It is recording individually the time in each worker.
    #IF you want to grab the total time (as seen by the master), you might only  get the roof value of the worrkers execution times
    tic() #Global Model time
    nodes_global_models = Array{Any}(nofworkers)
    @sync begin
        info("Training global model")
        for (idx, pid) in enumerate(workers())
            @async nodes_global_models[idx] = remotecall_fetch(train_global_model, pid, nodes_neighbors[idx]);
        end
    end
    #Done inside the function train_global_model
    # Naelson: STOP Train Global Model Time!!!!!



    train_global_model_time = toc()
    train_global_model_time = floor(train_global_model_time ,2)

    store_masterlog(train_global_model_time,string("train_global_model/","temp_",myid(),".csv"),"train_global_model_seconds")
    info("\n Merged train global model logs")
    mergelogs("train_global_model")

    # Naelson: START Testing Model Time!!!!!
    #Done
    tic() #Testing Model
    info("Done training global model")


    nodes_outputdata = Array{Any}(nofworkers)
    @sync begin
        for (idx, pid) in enumerate(workers())
            @async nodes_outputdata[idx] = remotecall_fetch(get_output_data, pid);
        end
    end

    nodes_test_data_evaluated = Array{Any}(nofworkers)
    @sync begin
        for (idx, pid) in enumerate(workers())
            @async nodes_test_data_evaluated[idx] =  remotecall_fetch(evaluate_test_data_with_local_models, pid, nofworkers, examples);
        end
    end

    #LLAMAR FUNCION
    data_final = []

    for (idx, pid) in enumerate(workers())
        push!(data_final, final_output(nodes_test_data_evaluated[idx], idx, nodes_global_models, nodes_neighbors, examples))
    end
    # Naelson: STOP Testing Model Time!!!!!
    testing_model_time = toc() #Testing Model
    testing_model_time = floor(testing_model_time,2)
    store_masterlog(testing_model_time,"testing_model_time","testing_model_seconds",nofworkers)


     #TODO CALCULAR ISSO ---- O MOCHA USA ESSA VARIÁVEL, POR ISSO ESTOU HARDCODANDO
   elapsed_time = toc()
   elapsed_time = floor(elapsed_time,2)
   store_masterlog(elapsed_time,"elapsed_time","elapsed_time_seconds",nofworkers)


    errors=[]

    putheader("mse","MSE\n0") #The header nd a zero for the master line
    for i in 1:nofworkers
        mse =  MSE(data_final[i], nodes_outputdata[i])
        push!(errors,mse)
        store_masterlog(mse,"mse")

        if (i!= nofworkers)
            store_masterlog("\n","mse")
        end
    end


    println(errors)
    errors2=[]

    putheader("mape","MAPE\n0")

    for i in 1:nofworkers
        mape = MAPE(transpose(data_final[i]), nodes_outputdata[i])
        push!(errors2, mape)
        store_masterlog(mape,"mape")

        if (i!= nofworkers)
            store_masterlog("\n","mape")
        end
    end


    println(errors2)
    errors3=[]


    putheader("r2","R2\n0")
    for i in 1:nofworkers
        r2 = R2(transpose(data_final[i]), nodes_outputdata[i])
        push!(errors3, r2)
        store_masterlog(r2,"r2")
        if (i!= nofworkers)
            store_masterlog("\n","r2")
        end
    end



    println(errors3)

    archivo=string(func)*"-"*string(nofworkers)*"-"*string(nofexamples)*"_"*string(num_nodes)*"_"*string(dim)*"_MSE_summary.txt"
    open("results"*"/"*archivo, "a") do f
        write(f, join(map(x->string(x),errors),",")*"\n")
    end
    archivo=string(func)*"-"*string(nofworkers)*"-"*string(nofexamples)*"_"*string(num_nodes)*"_"*string(dim)*"_MAPE_summary.txt"
    open("results"*"/"*archivo, "a") do f
        write(f, join(map(x->string(x),errors2),",")*"\n")
    end
    archivo=string(func)*"-"*string(nofworkers)*"-"*string(nofexamples)*"_"*string(num_nodes)*"_"*string(dim)*"_R2_summary.txt"
    open("results"*"/"*archivo, "a") do f
        write(f, join(map(x->string(x),errors3),",")*"\n")
    end
    archivo=string(func)*"-"*string(nofworkers)*"-"*string(nofexamples)*"_"*string(num_nodes)*"_"*string(dim)*"_time_summary.txt"
    open("results"*"/"*archivo, "a") do f
        write(f, string(elapsed_time)*"\n")
    end
    find_nodes = length(counts(neighborhoods))
    archivo=string(func)*"-"*string(nofworkers)*"-"*string(nofexamples)*"_"*string(num_nodes)*"_"*string(dim)*"_node_summary.txt"
    open("results"*"/"*archivo, "a") do f
        write(f, string(find_nodes == num_nodes)*"\n")
    end
    println("Number of nodes:")
    println(length(counts(neighborhoods)))
    println(nodes_neighbors)

end



function execute_experiment()
    # params checking
    # params order N_LOCAL, N_EXAMPLES, FUNCION, SEED, N_CLUSTER, DIM


    if length(ARGS) < 3
        error("You need to specify the number of procs to use or data examples per node!")
        quit()
    end
    #for x in ARGS
    #   println(x)
    #end
    # Saving position and distributions of nodes, this can be done separately
    seed = 1234
    n_of_procs = parse(ARGS[1])
    n_of_examples = parse(ARGS[2])
    funcion=ARGS[3]
    seed = parse(ARGS[4])
    srand(seed)
    if length(ARGS) >= 5
        num_nodes = parse(Int, ARGS[5])
        println(string(num_nodes))
        if length(ARGS) >= 6
            dims = parse(Int, ARGS[6])
            println(string(dims))
            run_experiments(n_of_procs, n_of_examples, funcion, num_nodes, dims)
        else
            run_experiments(n_of_procs, n_of_examples, funcion, num_nodes)
        end
    else
        run_experiments(n_of_procs, n_of_examples, funcion)
    end

    commit = readstring(`git log --pretty=format:'%h' -n 1`)


    experiment_dir = commit*"-"*start_time*"-"*string(seed)
    results_folder = "./results/"*experiment_dir



    g = open("results/executing/containers.csv","a+")
    for a in analyse_containers()
          write(g,"\n")
          write(g,a*start_time[10:length(start_time)]*" [FINAL]") #The iteration inside start_time is to remove the days/month/year. There's probably a better way to do it
     end 
     flush(g)
     close(g)
      
    mv(EXECUTING_PATH,results_folder)
    info("Results moved into the folder: "*results_folder*"\n")
    generatetable(experiment_dir)
    rmalldockerworkers()
end

function final_output(secondleveldatatotal, site, globalmodels, neighborhoods, examples)
    salidafinal = zeros(1,examples)
    numberofsitesneigh = length(neighborhoods[site])
    vecin = copy(neighborhoods[site])
    push!(vecin, site)
    for v in vecin
        ordered_neighs = []
        push!(ordered_neighs, v)
        for i in neighborhoods[v]
            push!(ordered_neighs, i)
        end
        ordered_neighs = sort(unique(ordered_neighs))
        secondleveldata = zeros(length(ordered_neighs), examples)
        for (idx, neighbor) in enumerate(ordered_neighs)
            secondleveldata[idx,:] = secondleveldatatotal[neighbor,:]
        end
        A, b = globalmodels[v][1:end-1,:], globalmodels[v][end,:]
        salida_global = (A'*secondleveldata.+b)'
        salidafinal = salidafinal + transpose(salida_global)
    end
    salidafinal=salidafinal/length(vecin)

    return salidafinal
end
