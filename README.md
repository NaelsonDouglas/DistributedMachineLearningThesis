# Overview

This repository has the reproducible material for running the experiments of the TODO paper [TODOpaperLink]().


## Requirements 
* Linux or MacOS operating system
* [Docker](https://www.docker.com/products/docker-desktop) version 18.06.1-ce or higher
* Code and data:

```bash
git clone https://github.com/NaelsonDouglas/DistributedMachineLearningThesis.git
```

# Running the experiments

## Build the Docker image

After cloning this repository, execute the following commands.

Remark: GNU/Linux users may need to call `sudo` before `docker` command.

```bash
cd DistributedMachineLearningThesis/src/
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
export CID=$($DOCKERBIN run --cpus 1 -tid -v /var/run/docker.sock:/var/run/docker.sock -v $DOCKERBIN:/usr/bin/docker -v /tmp/results:/DistributedMachineLearningThesis/src/results dmlt) && $DOCKERBIN exec -ti $CID /bin/bash
```

The `-v` parameters are necessary to allow the prototype to create further containers from the just-created container and to allow them to access the shared memory (i.e., the host file system). 

### Run the prototype

From the running container, run the following commands:

```bash
export JULIABIN="/root/julia/bin/julia"
cd DistributedMachineLearningThesis/src/
git pull #TODO specify the right tag
$JULIABIN
include("call_experiment.jl")
args =["4", "1000", "f1", "1234", "2", "2","summary"]
experiment(args)
```

The 'args' vector is a vector containing
*  The number of workers
*  Number of samples
*  The function name
*  Seed
*  n_cluster
*  dim
*  version of code to run: summary | histogram

You can select different configurations for 'args' and execute it as many times as you want. For a session you need to call include("call_experiments.jl") only once.

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

Open a Julia session and run the following command:

```julia
include("script.jl")
```

Edit the vectors in the `script.jl` file to set up the experiment parameters which are explained next.

* `nof_nodes` is the number of distributed nodes which experiment will launch.
* `nof_samples` is the number of all examples (synthetic data sets) from which 80% will be used for training purposes and the latter 20% will be used for assessment.
* `function` is the synthetic function that will be used to create the synthetic data sets. Currently, these see [here the available functions](TODO).
* `seed` specifies the seed that will be used to generate the TODO.
* `nof_neighborhoods` 
* `number_of_dataset_dimensions` the number of function parameters, MUST be fixed in this way: $f1=2, f2=3, f3=2, f4=5, f10=1$ ([more info here](TODOdatasets.jl))
* `data_representation` specifies whether to use histograms ("histogram") or summary statistics ("summary") to build the neighborhood. If not set, it is assumed to be "summary".

## Output file format

The output file is named based on this standard:

TODO-Naelson 

`timestamp-function-number_of_distributed_sources-sample_size.txt`



# Prototype assessment as presented in paper [TODO]()

## Experimental Setup

The experiments used the following parameter configuration:

* `nof_nodes` = [4, 8, 12, 16, 20, 24, 28, 32, 36]
* `nof_samples` = [10^3, 10^4, 10^5]  
* `function` = [f1, f2, f4]
* `seed` = [1..10]
* `nof_neighborhoods` = [2, 3]
* `number_of_dataset_dimensions` = according to each function 
* `data_representation` = ["histogram", "summary"]


# Running the experiments

To run the experiments use the file `script.jl`:

```julia
include("script.jl")
```

Those parameters are explained in the section *Understand the parameters* 

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
