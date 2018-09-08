#=
This implements a version of Infra.jl (https://github.com/gsd-ufal/Infra.jl)
that works for local Docker installation.

In a nutshell, it creates a Docker container and deloys a Julia worker on it.
=#
include("DockerBackend.jl")


"TODO"
function add_dockerworker(nofworkers::Int, nofcpus=0, memlimit=512)
	#TODO for i in 1:nofworkers

	dockerrm_all()
	# Deploy Docker container
	@show cid = dockerrun()
	@show cid2 = dockerrun()
	@show ip = get_containerip(cid)
	@show ip2 = get_containerip(cid2)

	if sshup(cid) && sshup(cid2)
		println("all SSHD up!")
	end

	ssh_key=homedir()*"/.ssh/id_rsa"
	ssh_pubkey=homedir()*"/.ssh/id_rsa.pub"


	pids = addprocs(
	    #["$ip"];
		["172.17.0.3"];
	    #tunnel=true,
	    sshflags=`-i /root/.ssh/id_rsa -o "StrictHostKeyChecking no"`,
		#sshflags=`-i $ssh_key`,
	    dir="/root/julia/bin",
	    exename="/root/julia/bin/julia")

		return pids
end

"TODO"
function rm_dockerworker(todo)

end

"TODO get container I/O usage"
function dockerworker_io(todo)

end

"TODO get container net usage"
function dockerworker_net(todo)

end

"TODO get container CPU usage"
function dockerworker_cpu(todo)

end

"TODO get container mem usage"
function dockerworker_mem(todo)

end
