#TODO list
#* verify that Docker is installed
#* check Internet conection and/or image availability
#* pull dml dockerhub image to enable full test
#* docker login to pull further Dockerhub images

listof_containers = []
juliabin = "/opt/julia/bin/julia"
img="dmlt" #BUGFIX Atom: to let Atom include this file

# checking OS
if ! ( is_apple() || is_linux() )
	error("Operating system NOT supported! Should use either Linux or MacOS.
		Exiting Julia...")
	exit(1)
end

"Execute the command `cmd` and return the output."
function execute_cmd(cmd::Cmd)
	tempfile = "$(randstring(20)).tmp"
	try
		info("Executing command $cmd...")
		run(pipeline(cmd, tempfile))
	catch
		msg = "Could NOT execute command $cmd.
			See output file $tempfile"
		error(msg)
		return ["ERROR $msg"]
	end
	output = readlines(tempfile)
	rm(tempfile, force=true)
	return output
end

"Executes the command `docker pull $img`"
function docker_pull(img="hello-world")
	cmd = Cmd(`docker pull $img`)
	try
		execute_cmd(cmd)
		return true
	catch
		return false
	end
end

"Run a container by using the given parameters. Return the container ID or `false` if not sucessful."
function dockerrun(img="dmlt", params="-tid", nofcpus=1, memlimit=2048)
	#TODO param --cpuset-cpus : CPUs in which to allow execution (0-3, 0,1)
	memlimit = memlimit * 10^6 # converting mem to MB
	cmd = Cmd(`docker run $params --cpus $nofcpus -m $memlimit $img`)
	try
		o = execute_cmd(cmd)
		cid = o[1]
		push!(listof_containers,cid)
		info("Container $cid is up")
		return cid
	catch
		return false
	end
end

"Remove a Docker container whose ID is `cid`.
Return `false` if not successful."
function dockerrm(cid::String)
	cmd = Cmd(`docker rm -f $cid`)
	try
		execute_cmd(cmd)
		filter!(x -> x ≠ "$cid", listof_containers)
		info("Container $cid removed.")
		return true
	catch
		return false
	end
end

"
Delete all containers deployed by `DockerBackend.jl`.
"
function dockerrm_all()
		if isempty(listof_containers)
			warn("No container to be deleted!")
			return true
		end
		containers = copy(listof_containers)
		for c in containers
			dockerrm(c)
		end
end

"Execute a Julia `expr` on container `cid`. Return `ERROR` if not sucessfull."
function execute_julia_expr(expr::String,cid::String)
	cmd = Cmd(`docker exec $cid $juliabin -E "$expr"`)
	try
		return execute_cmd(cmd)
	catch
		return ["ERROR"]
	end
end

function get_containerip(cid::String)
	cmd = Cmd(`docker inspect
		--format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
		$cid`)
	try
		return execute_cmd(cmd)
	catch
		return ["ERROR"]
	end
end

function sshup(cid::String)
	cmd = Cmd(`docker exec $cid /usr/sbin/sshd`)
	try
		execute_cmd(cmd)
		return true
	catch
		return false
	end
end

"Return container's runtime metrics or `false` otherwise.
.Container  Container name or ID (user input)
.Name       Container name
.ID         Container ID
.CPUPerc    CPU percentage
.MemUsage   Memory usage
.NetIO      Network IO
.BlockIO    Block IO
.MemPerc    Memory percentage (Not available on Windows)
.PIDs       Number of PIDs (Not available on Windows)"
function dockerstat(metrics::String,cid::String)
	available_metrics = [".Container", ".Name", ".ID", ".CPUPerc", ".MemUsage",
		".NetIO", ".BlockIO", ".MemPerc", ".PIDs"]
	if ! contains(==,available_metrics,metrics)
		error("Metrics $metrics NOT suppoerted!")
		return false
	end
	cmd = Cmd(`docker stats --no-stream --format "{{$metrics}}"  $cid`)
	return execute_cmd(cmd)
end

"Return '_the amount of data the container has read to and written from block
devices on the host_' if successful. Return `false` otherwise."
function dockerstat_blockio(cid::String)
	cmd = Cmd(`docker stats --no-stream --format "{{.NetIO}}"  $cid`)
	return execute_cmd(cmd)
end


function test_docker_backend()
	println("\n\n== TEST > creating and removing 3 containers")
	for i in 1:3
		dockerrun()
	end
	@show listof_containers
	for cid in listof_containers
		ip = get_containerip(cid)
		println("\nContainer $cid IP ADDR is $ip")
	end
	dockerrm_all()

	@show listof_containers
	dockerrm_all() # should print a WARN only

	println("\n\n== TEST > create and execute Bash and Julia commands")
	cid = dockerrun()
	@show listof_containers
	println(run(`docker exec $cid ls`))
	println(execute_julia_expr("sqrt(144)",cid))

	println("\n\n== TEST > get container stats")
	@show dockerstat(".Container",cid)
	@show dockerstat(".Name",cid)
	@show dockerstat(".ID",cid)
	@show dockerstat(".CPUPerc",cid)
	@show dockerstat(".MemUsage",cid)
	@show dockerstat(".NetIO",cid)
	@show dockerstat(".BlockIO",cid)
	@show dockerstat(".MemPerc",cid)
	@show dockerstat(".PIDs",cid)
	dockerrm(cid)

	println("\n\n== TEST > removing an unexistent container, should print an Error")
	dockerrm("a")
end

# @time test_docker_backend()
