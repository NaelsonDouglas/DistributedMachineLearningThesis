# Overview
This code runs Docker containers and deploys Julia Workers on them.

* Through `DockerizedJuliaWorkers.jl` you can add and remove Dockerized workers.
* `DockerBackend.jl` is a wrapper for calling Docker CLI commands.

## Requirements

* Docker and UNIX (Linux or MacOS).
* [DML Docker image](https://github.com/NaelsonDouglas/DistributedMachineLearningThesis#build-the-docker-image)
* Julia 0.6.x

# Usage
 
```julia
include("DockerizedJuliaWorker.jl")
adddockerworkers(5) # add 5 Docker workers
for i=1:10; @show @fetch myid(); end
rmalldockerworkers() #remove all workers and containers
```

If set true, the `DockerBackend.jl` `prototype` parameter mounts the `../src/results` container directory to the host `/tmp/results/` directory.

#TODO

* Support Julia 1.0
* Implement further Docker features
