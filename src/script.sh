functions=(f1)
declare -A dim_functions
dim_functions=( ["f1"]="2")
data_size=(16000)
num_nodes=(8 16)
seeds=(1111)
num_neighboors=(2)
		for  f in ${functions[@]}
		do
			for ds in ${data_size[@]}
			do
				for n_nodes in ${num_nodes[@]}
				do
					for s in ${seeds[@]}
					do
						for sds in ${seeds[@]}
						do
							for num_nei in ${num_neighboors[@]}
							do	
								for repetitions	 in {1..11}
								do						
									echo $n_nodes $ds $f $sds $num_nei ${dim_functions[$f]}								
									timeout 1800 /root/julia/bin/julia ugly_script.jl $n_nodes $ds $f $sds $num_nei ${dim_functions[$f]} summary
									echo "reseting the environment"
									nodes=$(docker ps -q | grep -v $(hostname))
									pkill julia
									docker kill $nodes									
									echo "Environment reset"
									docker ps
									echo "Sleeping for 10 seconds"
									sleep 10
								done
							done
						done
					done
				done
			done
		done  
