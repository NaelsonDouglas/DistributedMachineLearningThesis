include("call_experiment.jl")

seeds = ["1111", "2222", "3333", "4444", "5555", "6666", "7777", "8888", "9999", "1234"]
num_data = ["100", "1000", "10000"]

for num = 1:3
  folders = String[]
  for seed = 1:5
    args =["4", num_data[num], "f1", seeds[seed], "2", "2","summary"]
    res = experiment(args)
    push!(folders,res)
    println(res)
  end

  output_folder = "./results/"*join([args[1], args[2], args[3], args[5], args[6], args[7]], "_")
  mkpath(output_folder)

  for folder in folders
    run(`mv $folder $output_folder`)
  end

end

