###
#  Create the neighborhoods for every node using the histograms of the nodes.
#  This function doesn't need to be run on every node because the master has all
#  the information to calculate de neighborhoods.
#
#  histograms: vector containing all the histograms of the nodes.
#  Returns: vector where the i-th position is the cluster of the i-th node
###

#I'm putting it after the includes because if this is the first time you are executing the code, these includes will take too long to pre-compile and this time will be measured

EXECUTING_PATH = "./results2/executing/"
start_time = Dates.format(Dates.now(),"yy-mm-dd-HH:MM:SS")

try
    mkpath("./results2/incomplete/")
    mv(EXECUTING_PATH, string("./results2/incomplete/",randstring() ))

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
        if measure >= max
            max = measure
            k_winner = j
        end
    end
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

    data_histo=eye(nodes,length(histograms[1]))

    for i=1:nodes
        data_histo[i,:]=reshape(map(x->convert(Float64,x),histograms[i]),1,length(histograms[i]))'
    end
    
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

function run_experiments(nofworkers, nofexamples, func, num_nodes = 2, dim = 2, version = "summary")

    info("Adding ", nofworkers, " workers...\n")
    try
        adddockerworkers(nofworkers,_prototype=true,grancoloso=true)
    catch
        warn("Error, could not add the workers, trying again in 10 seconds.")
        rmalldockerworkers()
        rmprocs(workers())
        sleep(10)
        adddockerworkers(nofworkers,_prototype=true,grancoloso=true)
        info("Error fixed. Workers added.")
    end
    #addprocs(nofworkers)
    
    #keep_analysing_conts = false
    cont_daemon = @async begin
        g=-1
        try
            g = open("results2/executing/containers.csv","w+")
        catch
            println("Creating executing folder")
            mkpath("./results2/executing")
            g = open("results2/executing/containers.csv","w+")
        end
        header = "CONTAINER,NAME,CPU%,MEMUSAGE/LIMIT,MEM%,NETI/O,PIDS_JULIA,BLOCKI/O,PIDS_DOCKER,TIMESTAMP"
        write(g,header)
        keep_task = true
        task_failures = 0
        while((nworkers() > 1) && keep_task)
            sleep(1)
            timestamp = start_time = string(Dates.format(Dates.now(),"HH:MM:SS"))
            try
                for a in analyse_containers()
                    if a == false
                        close(g)
                        keep_task = false
                    end
                    write(g,"\n")
                    write(g,a*","*timestamp)
                end

                flush(g) #TODO move this command out of the loop to avoid I/O. I'm keeping it inside by now for test purposes

            catch
                task_failures+=1
                if (task_failures >2 || nworkers() == 1)
                    keep_task = false
                end
            sleep(1)
            end
            
            if nworkers() == 1
                    keep_task = false
            end
        end
    close(g)
    end

    tic() #<-----elapsed_time
    Logging.configure(level=INFO)

    info("Including workers code and functions...\n")
    include("workers.jl")

    info("Generating datasets and calculating maximums and minimums\n")
    nodes_maxmin = Array{Any}(nofworkers)
    metadata = Array{Any}(1)

    n_of_procs = parse(args[1]) -1
    tic() #Master maxmim
    @sync for (idx, pid) in enumerate(workers())
        @async begin
            metadata[1] = remotecall_fetch(generate_node_data, pid, eval(parse(func)), nofexamples, num_nodes, dim);
            remotecall_fetch(generate_test_data, pid, eval(parse(func)), nofexamples, num_nodes, dim);
            try
                nodes_maxmin[idx] = remotecall_fetch(calculate_maxmin, pid)
            catch
                println("DIDNT work\n")
                @show idx
                @show workers()
                @show n_of_procs
            end
        end
    end
    master_maxmim_time = toc() #Master maxmim
    master_maxmim_time = floor(master_maxmim_time,2)

    store_masterlog(master_maxmim_time, string("calculate_maxmin/","temp_",myid()),"calculate_maxmin_seconds")
    info("\n Merged maxmim logs")
    mergelogs("calculate_maxmin")

    examples, attributes = metadata[1]
    info("We have $(string(attributes)) attributes and $(string(examples)) examples\n")
    
    if version == "histogram"
        println("USING HISTOGRAMS!!!")
        info("Calculating global max and global min...\n")
        globalextremas = Array{Float64}(2, attributes)
        for node in 1:nofworkers
            for attribute in 1:attributes
                minnode, maxnode = nodes_maxmin[node][attribute]
                try
                    globalextremas[1, attribute] = minimum([globalextremas[1, attribute], minnode])
                    globalextremas[2, attribute] = maximum([globalextremas[2, attribute], maxnode])
                catch
                    globalextremas[1, attribute] = minnode
                    globalextremas[2, attribute] = maxnode
                end
            end
        end
        tic()#Histogram time

        info("Calculating histograms...")
        nodes_histograms = Array{Any}(nofworkers)
        @sync for (idx, pid) in enumerate(workers())
            @async nodes_histograms[idx] = remotecall_fetch(calculate_histogram, pid, globalextremas)
        end
        histogram_create_time = toc() #Histogram time
        histogram_create_time = floor(histogram_create_time,2)
        store_masterlog(histogram_create_time, "histogram_create_time","create_histogram_seconds",nofworkers)
        tic()
        @sync begin

            info("Calculating neighborhoods...\n")

            neighborhoods = create_neighborhoods(nodes_histograms)
        end  

        info("Generating neighborhoods for every node\n")

        nodes_neighbors = Array{Any}(nworkers())
        for (idx, pid) in enumerate(workers())
            nodes_neighbors[idx] = Int32[]
            for (idx2, elem) in enumerate(neighborhoods)
                if idx != idx2 && neighborhoods[idx] == elem
                    push!(nodes_neighbors[idx], idx2)
                end
            end
        end
        println(nodes_neighbors)

        info("Done generating neighborhoods for every node")

        clustering_time = toc() 
        clustering_time = floor(clustering_time,2)
        store_masterlog(clustering_time,"clustering_time","clustering_time_seconds",nofworkers)

    else
        println("USING STATISTICS!!!")
        tic()#Histogram time
        nodes_stats = Array{Any}(length(workers()))
        @sync for (idx, pid) in enumerate(workers())
            #@async nodes_stats[idx] = remotecall_fetch(pid, calculate_statistics);
            @async nodes_stats[idx] = remotecall_fetch(calculate_order_statistics, pid)[:];
        end

        histogram_create_time = toc() #Histogram time
        histogram_create_time = floor(histogram_create_time,2)
        store_masterlog(histogram_create_time, "histogram_create_time","create_histogram_seconds",nofworkers)

        tic()
        @sync begin

            info("Calculating neighborhoods...\n")

            neighborhoods = create_neighborhoods_stats(nodes_stats)
        end  

        info("Generating neighborhoods for every node\n")

        nodes_neighbors = Array{Any}(nworkers())
        for (idx, pid) in enumerate(workers())
            nodes_neighbors[idx] = Int32[]
            for (idx2, elem) in enumerate(neighborhoods)
                if idx != idx2 && neighborhoods[idx] == elem
                    push!(nodes_neighbors[idx], idx2)
                end
            end
        end
        println(nodes_neighbors)

        info("Done generating neighborhoods for every node")

        clustering_time = toc() 
        clustering_time = floor(clustering_time,2)
        store_masterlog(clustering_time,"clustering_time","clustering_time_seconds",nofworkers)

    end

    tic() #Local models
    @sync begin
        info("Training local models\n")
        for (idx, pid) in enumerate(workers())
            @async remotecall_fetch(train_local_model, pid);
        end
    end

    local_training_time = toc() #Local models
    local_training_time = floor(local_training_time,2)
    store_masterlog(local_training_time, string("train_local_model/","temp_",myid()),"local_training_seconds")
    info("\n Merged train local model logs")
    mergelogs("train_local_model")
    info("Done training local models")

    tic() #Global Model time
    nodes_global_models = Array{Any}(nworkers())
    @sync begin
        info("Training global model")
        for (idx, pid) in enumerate(workers())
            @async nodes_global_models[idx] = remotecall_fetch(train_global_model, pid, nodes_neighbors[idx]);
        end
    end

    train_global_model_time = toc()
    train_global_model_time = floor(train_global_model_time ,2)

    store_masterlog(train_global_model_time,string("train_global_model/","temp_",myid(),".csv"),"train_global_model_seconds")
    info("\n Merged train global model logs")
    mergelogs("train_global_model")

    tic() #Testing Model
    info("Done training global model")

    nodes_outputdata = Array{Any}(nworkers())
    @sync begin
        for (idx, pid) in enumerate(workers())
            @async nodes_outputdata[idx] = remotecall_fetch(get_output_data, pid);
        end
    end

    nodes_test_data_evaluated = Array{Any}(nworkers())
    @sync begin
        for (idx, pid) in enumerate(workers())
            @async nodes_test_data_evaluated[idx] =  remotecall_fetch(evaluate_test_data_with_local_models, pid, nofworkers, examples);
        end
    end
    data_final = []

    for (idx, pid) in enumerate(workers())
        push!(data_final, final_output(nodes_test_data_evaluated[idx], idx, nodes_global_models, nodes_neighbors, examples))
    end
    testing_model_time = toc() #Testing Model
    testing_model_time = floor(testing_model_time,2)
    store_masterlog(testing_model_time,"testing_model_time","testing_model_seconds",nofworkers)

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

    println("Number of nodes:")
    println(nodes_neighbors)

    info("Stopping the container analyser daemon")

    rmalldockerworkers()
    #rmprocs(workers());
    info("Removed all workers and containers")
    info("EXPERIMENT INTERACTION COMPLETE")
end

function execute_experiment(args)
    # params order N_LOCAL, N_EXAMPLES, FUNCION, SEED, N_CLUSTER, DIM

    if length(args) < 6
        error("You need to specify the number of procs to use or data examples per node!")
        quit()
    end
    seed = 1234
    n_of_procs = parse(args[1])
    n_of_examples = parse(args[2])
    funcion = args[3]
    seed = parse(args[4])
    num_nodes = parse(Int, args[5])
    dims = parse(Int, args[6])
    version = "summary"
    srand(seed)
    if length(args) >= 7
        version = args[7]
    end
    run_experiments(n_of_procs, n_of_examples, funcion, num_nodes, dims, version)


    commit = readstring(`git log --pretty=format:'%h' -n 1`)

    #experiment_dir = commit*"-"*start_time*"-"*string(seed)*"-"*version
    experiment_dir = string(n_of_procs)*"-"*string(n_of_examples)*"-"*string(funcion)*"-"*string(seed)*"-"*string(num_nodes)*"-"*string(dims)*"-"*string(version)
    results_folder = "./results2/"*experiment_dir

    g = open("results2/executing/containers.csv","a+")
    
    analysis = ones(1) #initializer
   
    analysis = analyse_containers()
        # The iteration inside start_time is to remove the 
        # days/month/year. There's probably a better way to do it
	if analysis != false
	        for a in analysis
        	  write(g,"\n")
	          write(g,string(a)*","*string(
        	            start_time[10:length(start_time)])*"[FINAL]") 
	        end
	        flush(g)
        	close(g)
	end
    
       # warn("Could not write the final analysis in master_summary.jl")
        try
        mv(EXECUTING_PATH,results_folder)
    catch
        warn("The folder: "*results_folder*" is being replaced\n")
        mv(EXECUTING_PATH, results_folder, remove_destination=true)
    end
    info("Results moved into the folder: "*results_folder*"\n")
    generatetable(experiment_dir)
    rmalldockerworkers()
    #rmprocs(workers());
    return results_folder
end
