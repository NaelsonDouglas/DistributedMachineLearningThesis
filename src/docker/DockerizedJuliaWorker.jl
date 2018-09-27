#=

This implements a version of Infra.jl (https://github.com/gsd-ufal/Infra.jl)
that works for local Docker installation.

In a nutshell, it creates a Docker container and deloys a Julia worker on it.
=#
include("DockerBackend.jl")

cids_pids_map = Dict()

function get_cid(pid::Int)
	if pid>0
		try
			return cids_pids_map[pid]
		catch
			info("There's no worker with the pid $pid")
			return false
		end
	else
		error("Getting a cid from a negative pid= $pid")
		#return cids_pids_map[pid]
	end
end

"Run Docker container(s) and use them to deploy Julia Worker(s).
If successful, return the list of the deployed Worker(s), otherwise
`exit(1)` from Julia."
function adddockerworkers(nofworkers::Int;_img="dmlt", _params="-tid",_nofcpus=1,
	 			_memlimit=2048, _prototype::Bool=false, grancoloso::Bool=false)
	ssh_key=homedir()*"/.ssh/id_rsa"
	juliabin = JULIA_HOME*"/julia"
	pids = Vector()
	ips = Vector()
	pids_cids_map = Dict()

	info("Deploying Docker $nofworkers container(s) and initialize their SSH daemon...")
	for n in 1:nofworkers
		# 1. deploy a container
		cid = dockerrun(img=_img,params=_params,nofcpus=_nofcpus,
						memlimit=_memlimit,prototype=_prototype)
		# 2. initiate SSHD on the deployed container
		println("------------------_")
		@show cid
		if ! sshup(cid)
			error("Could NOT init SSH at container $cid. Exiting Julia...")
			exit(1)
		end
		# 3. get container's IP and create a Worker by using it
		info("Getting containers' IP address(es)...")
		ip = get_containerip(cid)[1]
		push!(ips,ip)
		info("Containers' IP address is $ip")

		# 4. adding cid to a temporary pid_cid Dict
		new_cid = Dict(cid => -1)
		merge!(pids_cids_map, new_cid)
	end

	info("Creating $nofworkers Worker(s) through SSH...")
	try
		pids = addprocs(
			ips,
			sshflags=`-i $ssh_key -o "StrictHostKeyChecking no"`,
			exename="$juliabin")
	catch
		error("Could NOT create $nofworkers Worker(s)!\n
			Worker(s)' IP addresses: $ips\nExiting Julia...",
			stacktrace(), "\n\n", catch_stacktrace())
		exit(1)
	end
	info("Creating $nofworkers Worker(s) through SSH... DONE.
			Workers' PIDs are \n$pids\n")

	info("Getting Workers' container IDs to update the pids-cid Dict...")
	for w in workers()
		cid = -1
		try
			if grancoloso # Workaround to find cid at GranColoso: head -2
				cid = remotecall_fetch(readstring,w,pipeline(`head -2 /proc/self/cgroup`,`cut -d/ -f3`))
				cid = cid[2:length(cid)] #removing first \n
			else
				cid = remotecall_fetch(readstring,w,pipeline(`head -1 /proc/self/cgroup`,`cut -d/ -f3`))
			end
		catch
			error("Could NOT get container ID by calling Worker $w\nExiting Julia...",
				stacktrace(), "\n\n", catch_stacktrace())
			exit(1)
		end
		cid = chomp(cid) #removing second \n
		pids_cids_map[cid] = w # update the k-v to the right value (CID => Worker ID)
	end

	# inverting and merging the local pids_cids_map to the global cids_pids_map Dict
	pids_cids_map = Dict(zip(collect(values(pids_cids_map)),collect(keys(pids_cids_map))))
	merge!(cids_pids_map, pids_cids_map) #TODO implement a set funciton for cids_pids_map

	return pids
end

"Removes a specififc Dockerized Worker and its respective deployed container."
function rmdockerworkers(pids::Union{Int,Vector{Int}})
	try
		for p in pids
			rmprocs(p)
			dockerrm(get_cid(p))
			delete!(cids_pids_map,p) #TODO implement a set funciton for cids_pids_map
		end
	catch
		warn("No Dockerized Worker to be deleted!\n\n",
			stacktrace(), "\n\n", catch_stacktrace())
	end
	return workers()
end

"Removes all workers and all deployed containers."
function rmalldockerworkers()
	rmdockerworkers(workers())
end

function test_dockerworker()
	#TODO Andre
end
