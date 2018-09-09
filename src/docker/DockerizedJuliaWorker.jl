#=
This implements a version of Infra.jl (https://github.com/gsd-ufal/Infra.jl)
that works for local Docker installation.

In a nutshell, it creates a Docker container and deloys a Julia worker on it.
=#
include("DockerBackend.jl")

"Run Docker container(s) and use them to deploy Julia Worker(s).
If successful, return the list of the deployed Worker(s), otherwise
`exit(1)` Julia."
function add_dockerworker(nofworkers::Int,img="dmlt", params="-tid",
							nofcpus=1, memlimit=2048)
	 # nofworkers=1
	 # img="dmlt"; params="-tid"; nofcpus=1; memlimit=2000
	ssh_key=homedir()*"/.ssh/id_rsa"
	juliabin = "/root/julia/bin/julia"

	info("Deploying Docker $nofworkers container(s) and initialize their SSH daemon...")
	for n in 1:nofworkers
		cid = dockerrun(img,params,nofcpus,memlimit)
		if ! sshup(cid)
			error("Could NOT init SSH at container $cid. Exiting Julia...")
			exit(1)
		end
	end

	info("Getting containers' IP addresses...")
	ips = []
	for cid in listof_containers
		push!(ips, get_containerip(cid))
	end

	info("Creating $nofworkers Worker(s) through SSH...")
	pids=[]
	try
		pids = addprocs(
			ips,
			sshflags=`-i $ssh_key -o "StrictHostKeyChecking no"`,
			exename="$juliabin")
	catch
		error("Could NOT create $nofworkers Worker(s)! \n
			Worker(s)' IP addresses: $ips \n
			Exiting Julia...")
		exit(1)
	end
	info("List of deployed workers is: \n$pids")
	return pids
end

"TODO"
function rm_dockerworker(todo)
	#TODO
end

"TODO get container net usage"
function dockerworker_net(cid::String)
	
end

"TODO get container I/O usage"
function dockerworker_io(todo)
	#TODO
end

"TODO get container CPU usage"
function dockerworker_cpu(todo)
	#TODO
end

"TODO get container mem usage"
function dockerworker_mem(todo)
	#TODO
end
