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

"Executes the command `docker pull $img`"
function dockerpull(img="hello-world")
	try
		run(`docker pull $img`)
	catch
		error("Could NOT pull Docker image `$img`. Check Internet connection. System will quit now.")
		exit(1)
	end
end

"Run a container.
Return the `container_id` or `-1 ` if not sucessful."
function dockerrun(img="dmlt", params="-tid", nofcpus=1, memlimit=2000)
	#TODO param --cpuset-cpus : CPUs in which to allow execution (0-3, 0,1)
	memlimit = memlimit * 10^6 # converting mem to MB
	temp_cont_filename = string(randstring(10))
	temp_cont_filename_string = string(temp_cont_filename)


	cmd="docker run $params --cpus $nofcpus -m $memlimit $img"
	#info("Running docker command: $cmd")
	try
		run(pipeline(`docker run $params --cpus $nofcpus -m $memlimit $img`, temp_cont_filename_string))
	catch
		error("Container NOT deployed: could not execute Docker command: $cmd")
		return -1
	end
	#debug("Output from docker command was stored at $temp_cont_filename_string")
	f = open(temp_cont_filename_string)
	container_id =readlines(f)[1]
	#debug("Container ID is $container_id")
	push!(listof_containers,container_id)

	rm(temp_cont_filename, force=true)
	info("Container $container_id is up")
	return container_id
end

"Remove a Docker container by Docker container ID.
This function froces a container to stop.
Return `false` if not successful.
Example: TODO"
function dockerrm(container_id::String)
		filename = "docker_output.tmp"
		try
			#debug("Removing container $container_id")
			run(pipeline(`docker rm -f $container_id`, filename)) #, append=true))
		catch
			warn("Container NOT deleted (container ID=$container_id):
				could not execute 'docker rm' command. See $filename")
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

"""
Execute a Julia `code` on the previsouly deployed Docker container.
Return `false` if not sucessfull.
"""
function execute_code(code,container_id::String)
	filename = "docker_execute_code_output.txt"
	try
		#debug("Running command: docker exec $container_id $juliabin $code")
		run(pipeline(`docker exec $container_id $juliabin $code`, filename)) #, append=true))
	catch
		error("Could NOT `docker exec` code on Docker container $container_id. See $filename")
		return false
	end

	return readlines(filename)
end


function get_containerip(cid::String)
	tempfile = "$(randstring(20)).tmp"
	try
		#debug("Running command: docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cid")
		run(pipeline(`docker inspect
			--format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
			$cid`, tempfile))
	catch
		error("Could NOT `docker inspect` to get container IP address. See file $tempfile")
		return false
	end
	f = open(tempfile)
	ip =readlines(f)[1]
	rm(tempfile, force=true)

	return ip
end

function sshup(cid::String)
	try
		run(`docker exec $cid /usr/sbin/sshd`)
	catch
		error("Could NOT `docker exec $cid /usr/sbin/sshd` to init SSHD.")
		return false
	end
	info("SSH on container $cid is up")
	return true
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
	dockerrm_all() # should print an INFO

	println("\n\n== TEST > create and execute Bash and Julia commands")
	cid = dockerrun()
	@show listof_containers
	println(run(`docker exec $cid ls`))
	println(execute_code("-E \"1+1\"",cid)) #TODO BUGFIX should print the result
	dockerrm(cid)

	println("\n\n== TEST > removing an unexistent container, should print an Error")
	dockerrm("a")
end
