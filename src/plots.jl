using StatPlots
using Plots
using CSV

results_folder="../partial_results/"

function check_token(tokens,variable_value,position::Int)
	if string(variable_value) == "*" || string(tokens[position]) == string(variable_value)
		return true
	else		
		return false
	end

end
"This function returns the availabe results for the typed parameters. It returns a list of directories"
function filter_dirs(;_n_nodes="*",_data_size="*",_func="*",_seed="*",_neighboors="*",_dim="*")
	all_folders = readdir(results_folder)
	positions = Dict{String,Int}("_n_nodes"=>1,"_data_size"=>2,"_func"=>3,"_seed"=>4,"_neighboors"=>5,"_dim"=>6)
	
	results = []	
	for f in all_folders
		tokens = split(f,"-")

		#The ugliest if statement ever made
		if	(check_token(tokens, _n_nodes,positions["_n_nodes"]) &&
				check_token(tokens, _data_size,positions["_data_size"]) &&
					check_token(tokens, _func,positions["_func"]) &&
						check_token(tokens, _seed,positions["_seed"]) &&
							check_token(tokens, _neighboors,positions["_neighboors"]) &&
								check_token(tokens, _dim,positions["_dim"]))
			push!(results,results_folder*"/"*f)
		end
	end	
	return results
end

"Gets a vector with result paths and returns a vector with all the result tables on each row. You can get teh table_paths param using the funciton filter_dirs.
You can set the param table_name with system or containers"
function filter_tables(table_dirs,table_name)
	table_name = table_name*".csv"
	files=[]
	for folder in table_dirs
		file = folder*"/"*table_name
		push!(files,file)
	end
	return files
end

"Returns a vector where each row contains a dataframe for a iteration of the experiment.
The table_name variable can be 'system' or 'containers', it says what table you want
The key arguments are used to filter the experiment you wanna fetch the data"
function get_tables(table_name;n_nodes="*",data_size="*",func="*",seed="*",neighboors="*",dim="*")	
	dirs = filter_dirs(_n_nodes=n_nodes,_data_size=data_size,_func=func,_seed=seed,_neighboors=neighboors,_dim=dim)
	table_files = filter_tables(dirs,table_name)

	tables = []

	for i in table_files
		tb = CSV.read(i)
		if length(tb[1]) > 0
			push!(tables,tb)
		end
	end
	return tables
end

"Return the dataframes with the container tables.
You can filter the results using the keywords, '*' is the usual unix wildcard, ie. all results for that token"
function container_tables(;n_nodes="*",data_size="*",func="*",seed="*",neighboors="*",dim="*")
	tables = get_tables("containers",n_nodes=n_nodes,data_size=data_size,func=func,seed=seed,neighboors=neighboors,dim=dim)
end
"Return the dataframes with the system tables.
You can filter the results using the keywords, '*' is the usual unix wildcard, ie. all results for that token"
function system_tables(;n_nodes="*",data_size="*",func="*",seed="*",neighboors="*",dim="*")
	get_tables("system",n_nodes=n_nodes,data_size=data_size,func=func,seed=seed,neighboors=neighboors,dim=dim)
end


"This wouldn't be necessary if I had formated the tables on the file itself when they were being created"
function clear_column(column, col_name)
	result=[]
	if col_name == "CPU%" || col_name == "MEM%"
		for item in column
			if length(item) > 0
				push!(result,parse(item[1:length(item)-1])) #removes the '%' symbol
			end
		end
	elseif col_name == "NETI/OD" || col_name == "NETI/OU"
		for item in column
			if length(item) > 0				
				if col_name == "NETI/OD"
					data = split(item,"/")[1]
				else
					data = split(item,"/")[2]
				end

				suffix = ""

				if contains(data,"MB")
					suffix = "MB"
				elseif contains(data,"kB")
					suffix = "kB"
				elseif contains(data, "B")
					suffix = "B"
				elseif contains(data, "GB")
					suffix = "GB"
				end


				data = split(data,suffix)[1]
				data = replace(data,",",".")
				data = parse(data)

				if suffix == "kB"					
					data = data/1024
				elseif suffix == "B"
					data = (data/1024)/1024
				elseif suffix == "GB"
					data = 1024*data
				end
				push!(result,data)
			end
		end	
	elseif col_name == "BLOCKI/OW" || col_name == "BLOCKI/OR"
		for item in column
			if length(item) > 0
				data=""
				try #In some tables the column colum header is swapet with JULIA/PIDS. It was an error (now corrected), but a few tables are yet affected by it.
					#TODO fix the tables and remove this try block
					if col_name == "BLOCKI/OW"					
						data = split(item,"/")[1]
					else
						data = split(item,"/")[2]
					end

					suffix = ""

					if contains(data,"MB")
						suffix = "MB"
					elseif contains(data,"kB")
						suffix = "kB"
					elseif contains(data, "B")
						suffix = "B"
					elseif contains(data, "GB")
						suffix = "GB"
					end
					

					data = split(data,suffix)[1]
					data = replace(data,",",".")
					data = parse(data)

					if suffix == "kB"
						data = data/1024
					elseif suffix == "B"
						data = (data/1024)/1024
					end
				end

				push!(result,data)
			end
		end	
	elseif (col_name == "calculate_maxmin_secondsT" || col_name == "clustering_time_seconds"||  col_name == "elapsed_time_seconds" || col_name == "create_histogram_seconds"  || col_name == "testing_model_seconds" || col_name == "train_global_model_secondsT" || col_name == "local_training_secondsT")
		item = column[1] #only 	the master, I.E. the first line, calculates thodr variables
		if length(item) > 0			
			push!(result,item)
		end		
	elseif (col_name == "calculate_maxmin_seconds" ||  col_name == "train_global_model_seconds" || col_name == "local_training_seconds")		
		for idx =2:length(column) #The first index is the master total/result. It's plotted only using the 'T' version
			push!(result,column[idx])
		end		
	end
	return result
end


"An auxiliar function to format the output of a single table column.
It takes the column as a vector and the name of the column and returns well formated vector"
function merge_columns(tables,col_name,modifier="")	
	result=[]
	for tbl in tables
		column = tbl[Symbol(col_name)]
		column = clear_column(column,col_name*modifier)
		result = vcat(result,column)
	end	
	return result
end


"Plots a boxplot for the specified variable
The tables parameter  is a vector with the tables you wanna use as source for the plot.
* You must use system_tables(...) or container_tables(...) to filter this data.
* Variable is the variable within the tables used to make the boxplot"
function boxplot_experiment(tables,col_name)
	all_columns = merge_columns(tables,col_name)
	boxplot(all_columns)
end

nwks2 = system_tables(n_nodes=2)
nwks8 = system_tables(n_nodes=8)
nwks16 = system_tables(n_nodes=16)

function create_boxplot(dataset,variable_name,modifier,id;_title="",_outlier=true,_color="#D3D3D3",_legend=:topleft,_ylabel="Seconds",_axis_label=false)
	plot_data = [merge_columns(dataset,variable_name,modifier)]
	
	full_modifier=""
	if modifier == "W"
		full_modifier = " (WRITE)"
	elseif modifier == "R"
		full_modifier = " (READ)"
	elseif modifier == "D"
		full_modifier = " (DOWN)"
	elseif modifier == "U"
		full_modifier = " (UP)"		
	end
	lbl = split(variable_name,"_seconds")[1]*full_modifier
	if _axis_label
		boxplot([lbl],plot_data,label="",title=_title,outliers=_outlier,legend=_legend,color=_color,ylabel=_ylabel)
	else
		lbl = string(id)*" "*lbl
		boxplot(plot_data,label=lbl,title=_title,outliers=_outlier,legend=_legend,color=_color,ylabel=_ylabel)
	end
end

function add_boxplot!(dataset,variable_name,modifier,id;_outlier=true,_color="#D3D3D3",_axis_label=false)
	plot_data = [merge_columns(dataset,variable_name,modifier)]
	full_modifier=""
	if modifier == "W"
		full_modifier = " (WRITE)"
	elseif modifier == "R"
		full_modifier = " (READ)"
	elseif modifier == "D"
		full_modifier = " (DOWN)"
	elseif modifier == "U"
		full_modifier = " (UP)"		
	end
	lbl = split(variable_name,"_seconds")[1]*full_modifier
	if _axis_label		
		boxplot!([lbl],plot_data,label="",outliers=_outlier,color=_color)
	else
		lbl = string(id)*" "*lbl
		boxplot!(plot_data,label=lbl,outliers=_outlier,color=_color)
	end
end


function join_boxplots(dataset,variables,configuration="",unit="Seconds",subfolder::String="system";axis_label=false)
	p=-1
	for var_idx = 1:length(variables)		
		if var_idx == 1			
						p=create_boxplot(dataset,variables[var_idx][1],variables[var_idx][2],var_idx,_title=configuration,_ylabel=unit,_axis_label=axis_label)
		else
			
			add_boxplot!(dataset,variables[var_idx][1],variables[var_idx][2],var_idx,_axis_label=axis_label)
		end
	end
	if p.n>=1
		Plots.savefig(p,"../plots/"*subfolder*"/"*configuration*".png")
	end
end


data_size = ["1000", "16000","32000","64000","*"]
num_nodes = ["8","16","*"]
seeds = ["1111", "2222", "3333", "4444", "5555", "6666", "7777", "8888", "9999", "1234","*"]
functions = ["f1","f2","f4","*"]
dim_functions = Dict("f1"=>"2","f2"=>"3","f4"=>"5","*"=>"*")
num_neighboors = ["2","4","*"]



system_variables = [["local_training_seconds",""],
					["calculate_maxmin_seconds","T"],
					["clustering_time_seconds",""],
					["create_histogram_seconds",""],
					["testing_model_seconds",""],
					["train_global_model_seconds","T"],
					["local_training_seconds","T"],
					["elapsed_time_seconds",""]]


container_variables_1 = [["MEM%",""],
						 ["CPU%",""]]

container_variables_2 = [["NETI/O","D"],
						 ["NETI/O","U"]]

container_variables_3 = [["BLOCKI/O","W"],
						 ["BLOCKI/O","R"]]


#system_tables(;n_nodes="*",data_size="*",func="*",seed="*",neighboors="*",dim="*")
containers_dataset=-1
for idx_functions in functions              
    for idx_num_nodes in num_nodes
        for idx_num_neighboors in num_neighboors  
          for idx_seeds in seeds
            for idx_data_size in data_size      
            	system_dataset = system_tables(n_nodes=idx_num_nodes,data_size=idx_data_size,func=idx_functions,seed=idx_seeds,dim=dim_functions[idx_functions])
            	containers_dataset = container_tables(n_nodes=idx_num_nodes,data_size=idx_data_size,func=idx_functions,seed=idx_seeds,dim=dim_functions[idx_functions])
				
				config = idx_num_nodes*"-"*idx_data_size*"-"*idx_functions*"-"*idx_seeds*"-"*idx_num_neighboors*"-"* dim_functions[idx_functions]*"-summary"
				config = replace(config,"*","[ALL]")	
				if length(system_dataset)>0
					join_boxplots(system_dataset,system_variables,config,"Seconds","system",axis_label=false)
				end	

				if length(containers_dataset) > 0
					join_boxplots(containers_dataset,container_variables_1,config,"Megabytes","containers/mem_cpu",axis_label=true)
					join_boxplots(containers_dataset,container_variables_2,config,"Megabytes","containers/net_io",axis_label=true)
					join_boxplots(containers_dataset,container_variables_3,config,"Megabytes","containers/disk",axis_label=true)
				end	

              end #data_size                    
            end #seeds  
        end #idx_num_neighboors
    end #num_nodes  
  end #functions














