include("call_experiment.jl")

data_size = ["1000", "10000"]#, "100000"]
num_nodes = ["2","4","8","16","20","24","28","32","36"]
seeds = ["1111", "2222"]#, "3333, "4444", "5555", "6666", "7777", "8888", "9999", "1234"]
functions = ["f1","f2","f4"]
dim_functions = Dict("f1"=>"2","f2"=>"3","f4"=>"5")
num_neighboors = ["2","3"]
repetitions = 10


#=
idx_data_size = 1
idx_seeds = 1
idx_functions = 1
idx_dim_functions = idx_functions
idx_num_neighboors = 1
=#

  for idx_num_nodes in num_nodes
    for idx_num_neighboors in num_neighboors  
        for idx_seeds in seeds
            #for idx_functions in functions              
                for idx_data_size in data_size
                
                start_time = Dates.format(Dates.now(),"yy-mm-dd-HH:MM:SS")
                args =[idx_num_nodes, idx_data_size, "f1", idx_seeds, idx_num_neighboors, "2","summary"]     
                cids_pids_map = Dict()

                folder = execute_experiment(args)
                mv(folder,folder*"_"*start_time)
                rmalldockerworkers()
                end #data_size
                    
            #end #functions
        end #seeds  
    end #idx_num_neighboors
  end #num_nodes  




#=
exp_lim = 3
seed_lim = 3
for num = 1:exp_lim
  folders = []
  for seed = 1:seed_lim

	println("========================")
	println("Experiment $num out of $exp_lim ")
	println("Using seed $seed out of $seed_lim ")
	println("========================")

    start_time = Dates.format(Dates.now(),"yy-mm-dd-HH:MM:SS")
    args =["4", data_size[num], "f1", seeds[seed], "2", "2","summary"]
    cids_pids_map = Dict()
    folder = execute_experiment(args)
    push!(folders, folder)
  end


  output_folder = "./results/"*join([args[1], args[2], args[3], args[5], args[6], args[7]], "_")
  mkpath(output_folder)

  for folder in folders
    try
      run(`mv $folder $output_folder`)
    end
  end

end

=#