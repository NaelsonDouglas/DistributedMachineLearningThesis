using GR
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
	if col_name == "CPU%"
		for item in column
			if length(item) > 0
				push!(result,parse(item[1:length(item)-1])) #removes the '%' symbol
			end
		end
	elseif col_name == "NETI/OD"
		for item in column
			if length(item) > 0
				data = split(item,"/")[1]

				suffix = data[length(data)-2:length(data)]

				data = data[1:(length(data)-2)]
				data = replace(data,",",".")
				data = parse(data)

				if suffix == "kB"
					data = data/1024
				end
				push!(result,data)
			end
		end
	elseif col_name == "NETI/OU"
		for item in column
			if length(item) > 0
				data = split(item,"/")[2]

				suffix = data[length(data)-2:length(data)]

				data = data[1:(length(data)-2)]
				data = replace(data,",",".")
				data = parse(data)

				if suffix == "kB"
					data = data/1024
				end

				push!(result,data)
			end
		end
	elseif col_name == "CPU%"
		for item in column
			if length(item) > 0
				item = parse(replace(item,",","."))
				push!(result,item)
			end
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

nwks2 = container_tables(n_nodes=2)
nwks8 = container_tables(n_nodes=8)
nwks16 = container_tables(n_nodes=16)


#y=[merge_columns(nwks2,"CPU%"),merge_columns(nwks8,"CPU%"),merge_columns(nwks16,"CPU%")]
#boxplot(["2 nodes" "8 nodes" "16 nodes"],y,leg=false,outliers=false)







