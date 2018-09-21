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
function adddockerworkers(nofworkers::Int;_img="dmlt", _params="-tid",
							_nofcpus=1, _memlimit=2048, _prototype::Bool=false)
	#nofworkers=1
	#img="dmlt"; params="-tid"; nofcpus=1; memlimit=2000
	ssh_key=homedir()*"/.ssh/id_rsa"
	juliabin = "/root/julia/bin/julia"
	pids = Vector()

	info("Deploying Docker $nofworkers container(s) and initialize their SSH daemon...")
	for n in 1:nofworkers
		#TODO Andre params = params * " -v $HOME/results-$RANDOM:/DistributedMachineLearningThesis/src/results "
		cid = dockerrun(img=_img,params=_params,nofcpus=_nofcpus,
						memlimit=_memlimit,prototype=_prototype)
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
		new_maped_pid = Dict(pid[1] => cid)
		merge!(cids_pids_map, new_maped_pid)
	end # loop

	return pids
end

"Removes a specififc Dockerized Worker and its respective deployed container."
function rmdockerworkers(pids::Union{Int,Vector{Int}})
	try
		for p in pids
			rmprocs(p)
			dockerrm(cids_pids_map[p])
			delete!(cids_pids_map,p)
		end
	catch
			warn("There's no process with id $pid")
	end	
	return workers()	
end

"Removes all workers and all deployed containers."
function rmalldockerworkers()
	rmdockerworkers(workers())
	dockerrm_all()
	
end

function test_dockerworker()
	#TODO Andre
end
