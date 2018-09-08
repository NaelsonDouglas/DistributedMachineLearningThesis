#=
This implements a version of Infra.jl (https://github.com/gsd-ufal/Infra.jl)
that works for local Docker installation.

In a nutshell, it creates a Docker container and deloys a Julia worker on it.
=#
include("DockerBackend.jl")


"TODO"
#function add_dockerworker(nosfworkers::Int, nofcpus=0, mem=512; tunnel=false)
nofworkers=1; nofcpus=0; mem=512; tunnel=false;

dockerrm_all()
# Deploy Docker container
@show cid = dockerrun()
@show cid2 = dockerrun()
@show ip = get_containerip(cid)
@show ip2 = get_containerip(cid2)

if sshup(cid) && sshup(cid2)
	println("all SSHD up!")
end

ssh -o "StrictHostKeyChecking no" localhost

#TODO create SSH keys at host and containers
ssh_key=homedir()*"/.ssh/id_rsa"
ssh_pubkey=homedir()*"/.ssh/id_rsa.pub"

pid = addprocs(
    #["$ip"];
	["172.17.0.3"];
    #tunnel=true,
    sshflags=`-i /root/.ssh/id_rsa -o "StrictHostKeyChecking no"`,
	#sshflags=`-i $ssh_key`,
    dir="/root/julia/bin",
    exename="/root/julia/bin/julia")



#end

addprocs(2)
