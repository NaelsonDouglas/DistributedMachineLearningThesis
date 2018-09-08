#=
This implements a version of Infra.jl (https://github.com/gsd-ufal/Infra.jl)
that works for local Docker installation.

In a nutshell, it creates a Docker container and deloys a Julia worker on it.
=#
include("DockerBackend.jl")
img="dmlt"

"TODO"
#function add_dockerworker(nofworkers::Int, nofcpus=0, mem=512; tunnel=false)
nofworkers=1; nofcpus=0; mem=512; tunnel=false;

# Deploy Docker container
cid = run_container()

1) run container detached (-d)

2) enable container run containers



3) test it and configure it if necessary

https://forums.docker.com/t/how-can-i-run-docker-command-inside-a-docker-container/337/8


4) addprocs

pid = addprocs(["root@$(SETTINGS.host)"];
tunnel=true,
sshflags=`-i $ssh_key -p $get_port()`,dir="/opt/julia/bin",exename="/opt/julia/bin/julia")
/opt/julia/bin/julia


#end

addprocs(2)
