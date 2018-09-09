# Overview

This repository has the reproducible material for running the experiments of the TODO paper [TODOpaperLink]().


## Requirements 
* Linux or MacOS operating system
* [Docker](https://www.docker.com/products/docker-desktop)
* Code and data:

```bash
git clone https://github.com/NaelsonDouglas/DistributedMachineLearningThesis.git
```

# Running the experiments

## Build the Docker image

After cloning this repository, execute the following commands.

Remark: GNU/Linux users may need to call `sudo` before `docker` command.

```bash
cd src/ 
docker build --no-cache -t dmlt .
```
Remark: it is **mandatory** that this image should be tagged to `dmlt`, so do NOT change the `dmlt` name in the command above.

### Create an interactive Docker container and start a Bash session on it

First, let's set the `DOCKERBIN` variable according to your OS:

```bash
export DOCKERBIN="/usr/bin/docker" # Linux users
export DOCKERBIN="/usr/local/bin/docker" # MacOS users
```

The following command will create a container and run a Bash session on it by using the `dmlt` Docker image:

```bash
export CID=$(docker run -tid -v /var/run/docker.sock:/var/run/docker.sock -v $DOCKERBIN:/usr/bin/docker dmlt) && docker exec -ti $CID /bin/bash
```

The `-v` parameters are necessary to allow the prototype to create further containers from the just-created container. 

### Run the prototype

From the running container, run the following commands:

```bash
cd DistributedMachineLearningThesis/src/
#TODO  git pull to the right tag
julia -L master_summary.jl -e "execute_experiment()" 4 100 f1 1234 4 2 
```
In order to run a customized experiment, please read the next Sections.

## Performance metrics

This research prototype is assessed by using the following metrics:

* Statistics metrics (accuracy)
 * MSE
 * MAPE
* System metrics 
 * Execution time: time to run the experiments
 * Exchanged data rate: refers to the network I/O among Julia Workers



## Understand the parameters

The command used to run the prototype includes its parameters as described next.

```bash
julia -L master_summary.jl -e "execute_experiment()" \
TODO review this!
$n_procs \
$n_samples \
$function \
$seed \
$num_nodes \
$dim_func
```
* `n_of_procs` is the number of distributed nodes on which the experiment will rely.
* `n_of_examples` is the number of all examples (synthetic data sets) from which 80% will be used for training purposes and the latter 20% will be used for assessment.
* `synthetic_function` is the function that will be used to create the synthetic data sets. Currently, these are the available functions:
 * $f1(x1, x2) = sin(x1).*sin(x2)./(x1.*x2) + rand(Normal(0,0.1),size(x1)[1])$
 * $f2(x1, x2, x3) = 0.01.*x1 + 0.02.*x2.^(2) + 0.9.*x3.^(3) + rand(Normal(0,0.1),size(x1)[1])$
 * $f3(x1, x2) = 0.6.*x1 + 0.3.*x2 + rand(Normal(0,0.1),size(x1)[1])$
 * $f10(x) = 10.*sin(pi.*x[:,1].*x[:,2]) + 20(x[:,3]-0.5).^2 + 10.*x[:,4] + 5.*x[:,5] + 10.*sin(pi.*x[:,6].*x[:,7]) + 20(x[:,8]-0.5).^2 + 10.*x[:,9] + 5.*x[:,10] + rand(Normal(0,0.1),size(x[:,1])[1])$
* `seed` specifies the seed that will be used to generate the TODO.
* `number_of_neighborhoods` 
* `number_of_data_set_dimensions` 
* TODO move `seed` to this section
* TODO `prefix` will be used as prefix to name output files.
* TODO `suffix` will be used as suffix to name output files.
* `variances` specifies the variance value(s) that should be used for each `number_of_neighborhoods`. If `variances` is set to a single value, it will apply this value to all neighborhoods.
 
## Output file format

The output file is named based on this standard:

`timestamp-function-number_of_distributed_sources-sample_size.txt`

TODO ...

# Prototype assessment as presented in paper [TODO]()

## Experimental Setup

The experiments used the following parameter configuration:

* Functions: f1, f2, f3, f4, f5, etc.
* Number of Distributed Sources: 4, 8, 12, 16, 20, 24, 28, 32, 36
* Sample_size in MB: 0.001, 0.01, 0.1, 1, 10, 100, 1000, 2000, 3000, etc.
* ...

# TODO MISC

* use Julia standards
  * documentation
  * tests
  * write execution data to log files with configurable log levels
* define and implement performance metrics
  * execution time
  * speedup
  * I/O rate
  * throughput
  * ...
* write experiment data to files
  * input
  * configuration
  * output
  * execution time
* write documentation in Markdown
* allow parameter configuration (n. of repetitions, data set size, etc.)
* naming
  * replace `salida` by `output`
* why `@everywhere` in many parts of the code?
  * for example, in `workers.jl` it should be only necessary to call the code in the worker, do no need for `@everywhere`.
