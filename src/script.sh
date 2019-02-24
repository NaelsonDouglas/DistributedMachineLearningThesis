functions=(f1 f2 f4)

declare -A dim_functions
dim_functions=( ["f1"]="2" ["f2"]="3" ["f4"]="5")
data_size=(1000 10000 100000)
num_nodes=(8 16 20 24 28 32 36)
seeds=(1111  2222 3333  4444  5555  6666  7777  8888  9999  1234)
num_neighboors=(2 3)

for repetitions in {1..10}
do
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
								echo $n_nodes $ds $f $sds $num_nei ${dim_functions[$f]}								
								/root/julia/bin/julia ugly_script.jl $n_nodes $ds $f $sds $num_nei ${dim_functions[$f]} summary
							done
						done
					done
				done
			done
		done   
done