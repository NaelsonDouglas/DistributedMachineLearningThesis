#=

This implements a version of Infra.jl (https://github.com/gsd-ufal/Infra.jl)
that works for local Docker installation.

In a nutshell, it creates a Docker container and deloys a Julia worker on it.
=#
include("DockerBackend.jl")

cids_pids_map = Dict()

function workerstat(pid::Int)
	if pid>0
		try
			return cids_pids_map[pid]
		catch
			info("There's no worker with the pid $pid")
		end
	else
		return cids_pids_map
	end

end
"Run Docker container(s) and use them to deploy Julia Worker(s).
If successful, return the list of the deployed Worker(s), otherwise
`exit(1)` Julia."
function adddockerworkers(nofworkers::Int,img="dmlt", params="-tid",
							nofcpus=1, memlimit=2048)
	#nofworkers=1
	#img="dmlt"; params="-tid"; nofcpus=1; memlimit=2000
	ssh_key=homedir()*"/.ssh/id_rsa"
	juliabin = "/root/julia/bin/julia"
	pids = Vector()

	info("Deploying Docker $nofworkers container(s) and initialize their SSH daemon...")
	for n in 1:nofworkers
		#TODO Andre params = params * " -v $HOME/results-$RANDOM:/DistributedMachineLearningThesis/src/results "
		cid = dockerrun(img,params,nofcpus,memlimit)
		if ! sshup(cid)
			error("Could NOT init SSH at container $cid. Exiting Julia...")
			exit(1)
		end

		info("Getting containers' IP address(es)...")
		ip = get_containerip(cid)[1]
		info("Containers' IP address is $ip")

		info("Creating $n-th Worker(s) through SSH...")
		pid = -1
		try
			pid = addprocs(
				[ip],
				sshflags=`-i $ssh_key -o "StrictHostKeyChecking no"`,
				exename="$juliabin")
		catch
			error("Could NOT create $n-th Worker! \n
				Worker(s)' IP addresses: $ip \n
				Exiting Julia...")
			exit(1)
		end
		info("Deployed workers ID is: $pid")

		push!(pids, pid)
		new_maped_pid = Dict(pid => cid)
		merge!(cids_pids_map, new_maped_pid)
	end # loop

	return pids
end

"Removes all workers and all deployed containers."
function rmalldockerworkers()
	rmprocs(workers())
	dockerrm_all()
	#TODO Naelson: remove from the cids_pids_map
end

"Removes a specific Dockerized Worker and its respective deployed container."
function rmdockerworkers()
	error("TODO not implemented!")
	#TODO Naelson
end

function test_dockerworker()
	#TODO Andre
end
