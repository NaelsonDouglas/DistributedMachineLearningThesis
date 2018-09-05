listof_containers = []
juliabin = "/opt/julia/bin/julia"
img="hello-world"

"Executes the command `docker pull $img`"
function pullimage()
	try
		run(`docker pull $img`)
	catch
		error("Could NOT pull Docker image `$img`. Check Internet connection. System will quit now.")
		exit(1)
	end
end

"
Run a container with the specified resources [memory (MB), cpus].
The defautl values for memory and CPU is 512MB and 1 core.
Return the `container_id` or `-1 ` if not sucessful.
"
function run_container(res_requirements=[512,1])
	temp_cont_filename = string(randstring(10)) #	temp_dir = mktempdir(pwd())
	#It will be rand for a  while. The name will be changed after the container creation
	memory = string("-m=",res_requirements[1],"MB")
	cpus = string("--cpus=",res_requirements[2])
	cmd = "docker run -itd $memory $cpus $img"

	info("Running docker image $img")
	temp_cont_filename_string = string(temp_cont_filename)
	try
		run(pipeline(`docker run -itd $memory $cpus $img`, temp_cont_filename_string))
	catch
		error("Container NOT deployed: could not execute: $cmd")
		return -1
	end
	info("Output from docker `$cmd` command was stored at $temp_cont_filename_string")
	f = open(temp_cont_filename_string)
	container_id =readlines(f)[1]
	info("Container ID is $container_id")
	push!(listof_containers,container_id)

	rm(temp_cont_filename, force=true)
	info("Container $container_id is up")
	return container_id
end

"
Remove a Docker container by Docker container ID.
This function froces a container to stop.
Return `false` if not successful.
Example:
```julia
rmcontainer("3c14525d994426c4a0cd1af6189f8bd40a034a70e3ad84d3a287181db18ce014")
```
"
function rmcontainer(container_id::String)
		filename = "docker_output.tmp"
		try
			info("Removing container $container_id")
			run(pipeline(`docker rm -f $container_id`, filename)) #, append=true))
		catch
			warn("Container NOT delete container $container_id: could not execute 'docker rm' command. See $filename")
		end
		filter!(x -> x ≠ "$container_id", listof_containers)
		info("Container $container_id removed.")

	return true
end

"
Delete all Docker deployed containers.
This function froces a container to stop.
Return `false` if not successful.
"
function deletecontainers()
		if isempty(listof_containers)
			info("No container to be deleted!")
			return true
		end

		containers = copy(listof_containers)
		for c in containers
			rmcontainer(c)
		end
end

"""
Execute a Julia `code` on the previsouly deployed Docker container.
Return `false` if not sucessfull.
"""
function execute_code(code,container_id)
	filename = "docker_output.tmp"
	try
		println("docker exec $container_id $juliabin $code")
		run(pipeline(`docker exec $container_id $juliabin $code`, filename)) #, append=true))
	catch
		error("Could NOT `docker exec` code on Docker container $container_id. See $filename")
		return false
	end

	return readlines(filename)
end



function test_docker_backend()

	# creating and removing 3 containers
	for i in 1:3
		run_container()
	end
	@show listof_containers
	deletecontainers()
	@show listof_containers
	deletecontainers() # should print an INFO

	# creating a customized container and removing it
	cid = run_container(["512","2"])
	@show listof_containers
	rmcontainer(cid)

	rmcontainer("a") # should print an Error

	global img = "dmlt"
	cid = run_container()
	println(run(`docker exec $cid ls`))
	println(execute_code("-E \"println(sqrt(144));1+13\"",cid)) # buggy: should print the result
	rmcontainer(cid)

end

test_docker_backend()
