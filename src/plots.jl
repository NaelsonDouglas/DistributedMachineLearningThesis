using CSV

results_folder="../partial_results/"

#=
"Just an auxiliar function which converts the kwards arguments to a formated query string"
function kwargs_to_query(n_nodes=16,data_size=64000,func="f1",seed=1111,neighboors=2,dim=2)
	return string(n_nodes)*"-"*string(data_size)*"-"*func*"-"*string(seed)*"-"*string(neighboors)*"-"*string(dim)
end

"Just an auxiliar function which converts the query to kwargs"
function query_to_kwargs(query::String)
	kwargs=collect(split(query,"-"))
end


"This function returns the availabe results for the typed parameters. It returns a list of directories"
function filter_dirs(;_n_nodes=16,_data_size=64000,_func="f1",_seed=1111,_neighboors=2,_dim=2)
	all_folders = readdir(results_folder)	
	query = kwargs_to_query(_n_nodes,_data_size,_func,_seed,_neighboors,_dim)
	results = []	
	for f in all_folders
		if contains(f,query)
			push!(results,results_folder*f)
		end
	end	
	return results
end
=#


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
		push!(tables,CSV.read(i))
	end
	return tables
end