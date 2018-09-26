# Overview
This code runs Docker containers and deploys Julia Workers on them.

* Through `DockerizedJuliaWorkers.jl` you can add and remove Dockerized workers.
* `DockerBackend.jl` is a wrapper for calling Docker CLI commands.

## Requirements

* Docker and UNIX (Linux or MacOS).
* [DML Docker image](https://github.com/NaelsonDouglas/DistributedMachineLearningThesis#build-the-docker-image)
* Julia 0.6.x

# Usage

### 1. Log in at host and enter the following commands:

```bash
git clone https://github.com/NaelsonDouglas/DistributedMachineLearningThesis.git
cd DistributedMachineLearningThesis/src/
docker build --no-cache -t dmlt .
export DOCKERBIN="/usr/bin/docker" # Linux users
#export DOCKERBIN="/usr/local/bin/docker" # MacOS users
export CID=$(docker run --cpus 1 -tid -v /var/run/docker.sock:/var/run/docker.sock -v $DOCKERBIN:/usr/bin/docker -v /tmp/results:/DistributedMachineLearningThesis/src/results dmlt) && docker exec -ti $CID /bin/bash
```


### 2. From the running container, run the following commands:

```bash
export JULIABIN="/root/julia/bin/julia"
cd DistributedMachineLearningThesis/src/
git pull #TODO specify the right tag
$JULIABIN
```

### 3. From the running Julia session at the container, do:

```julia
include("docker/DockerizedJuliaWorker.jl")
adddockerworkers(5) # add 5 Docker workers
#adddockerworkers(5,_prototype=true,grancoloso=true) # for DML prototyping at GranColoso
for i=1:10; @show @fetch myid(); end
rmalldockerworkers() #remove all workers and containers
```
### Remarks

**Mandatory** flags to run experiments in GranColoso server:

* If set true, the `DockerizedWorkerBackend.jl` `_prototype` parameter mounts the `../src/results` container directory to the host `/tmp/results/` directory.
* If set true, the `DockerizedWorkerBackend.jl` `grancoloso` parameter allows to proper get the container ID.


# TODO

* Support Julia 1.0
* Implement further Docker features
