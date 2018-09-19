#=

This implements a version of Infra.jl (https://github.com/gsd-ufal/Infra.jl)
that works for local Docker installation.

In a nutshell, it creates a Docker container and deloys a Julia worker on it.
=#
include("DockerBackend.jl")

cids_pids_map = Dict()

function update_maps(new_maping::Dict)
	merge!(cids_pids_map,new_maping)
end

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

	info("Deploying Docker $nofworkers container(s) and initialize their SSH daemon...")
	new_cids = Vector()
	for n in 1:nofworkers
		cid = dockerrun(img,params,nofcpus,memlimit)
		push!(new_cids,cid)
		if ! sshup(cid)
			error("Could NOT init SSH at container $cid. Exiting Julia...")
			exit(1)
		end
	end

	info("Getting containers' IP addresses...")
	ips = []
	for cid in listof_containers
		push!(ips, get_containerip(cid)[1])
	end

	info("Creating $nofworkers Worker(s) through SSH...")
	pids=String[]
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
	new_maped_ids = Dict(zip(pids,new_cids))
	println(new_maped_ids)
	update_maps(new_maped_ids)
	return pids
end

"Removes all workers and all deployed containers."
function rmalldockerworkers()
	rmprocs(workers())
	dockerrm_all()
end
