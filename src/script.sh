functions=(f1 f2 f4)
declare -A dim_functions
dim_functions=( ["f1"]="2" ["f2"]="3")
data_size=(16000)
num_nodes=(8 16 32)
seeds=(1111 2222 3333  4444  5555  6666  7777  8888  9999  1234)
num_neighboors=(4 2)
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
								for repetitions	 in {1..10}
								do						
									echo $n_nodes $ds $f $sds $num_nei ${dim_functions[$f]}								
									timeout 3000 /root/julia/bin/julia ugly_script.jl $n_nodes $ds $f $sds $num_nei ${dim_functions[$f]} summary
									nodes=$(docker ps -q | grep -v $(hostname))
									docker kill $nodes
								done
							done
						done
					done
				done
			done
		done  
