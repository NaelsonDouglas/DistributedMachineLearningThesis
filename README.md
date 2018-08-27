# Overview
The algorithm is describes as follows:

```
TODO
```

For more information, read the paper [TODOaXivLink]().

# Reproducing the experiments
* TODO replace all static references to files and directories to allow the reproduction of the experiments
 * e.g., workers.jl at function get_outpu_data
 * mainly in workers() 

# Documentation

## Overview

TODO explain the project and the role of each file, just an overview to let users understand what it is and how it works, cite the paper (link to download page at publisher) which presents the approach.


# Execute the experiments

* You can execute the experiments in your local machine or in the pre configured Docker we provide.
* If using your local machine, you'll need to install the dependencies (InstallDeps.jl), if using the Docker image, you'll need to install Docker and the dependencies are handled by Docker itself

# Execute directly in your machine

## Dependencies
* You must use [Julia 0.6.2](https://julialang.org/downloads/oldreleases.html), it may not work if using other versions.

* The you need to install the dependencies, there's a script for it on the repository.

> julia src/InstallDeps.jl

Nothe that When executing from the Docker, the dependencies are installed automatically. So there's no need to use InstallDeps.jl
You only need to use it in a local execution, but it will not cause any problem if you execute inside the docker container. 

* Then you are ready to execute the experiments using the pattern

> julia -L master_summary.jl -e "execute_experiment()" $n_procs $n_samples $function $seed $num_nodes $dim_func

> julia -L master.jl -e "execute_experiment()" $n_procs $n_samples $function $seed $num_nodes $dim_func

# For example:
julia -L master_summary.jl -e "execute_experiment()" 8 100 f1 1234 4 2
julia -L master.jl -e "execute_experiment()" 8 100 f1 1234 4 2

# Execute using the Dockerfile
* [Install Docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/#upgrade-docker-after-using-the-convenience-script)
* Go to src/

>cd src/

* Build the image

> sudo docker build -t dmlt .

* Execute a container with the image
> sudo docker run -it dmlt

This will leave you inside a container executing the Docker image. 
In order to execute the experiment inside the container you may use the pattern:
 
 >julia -L master_summary.jl -e "execute_experiment()" $n_procs $n_samples $function $seed $num_nodes $dim_func


 example:
 
 >julia -L master_summary.jl -e "execute_experiment()" 8 100 f1 1234 4 2






# Scenarios

## Julia workers in a single machine

* Julia workers used straightforward
* Single machine

##  Cloud workers in various machines

* Julia workers wrapped as cloud (Docker) workers by using `Infra.jl`
* 3 machines available at PUCV
* ​

# TODO

* use Julia standards
  * documentation
  * tests
  * write execution data to log files with configurable log levels
* define and implement performance metrics
  * execution time
  * speedup
  * I/O rate
  * throughput
  * …
* write experiment data to files
  * input
  * configuration
  * output
  * execution time
* write documentation in Markdown
* See `#alage:` comments in the code
* why use  `@async` and `@sync` in `for` loops?
* allow parameter configuration (n. of repetitions, data set size, etc.)
* naming
  * replace `salida` by `output`
* why `@everywhere` in many parts of the code?
  * for example, in `workers.jl` it should be only necessary to call the code in the worker, do no need for `@everywhere`.
  * ​

  ## Output Files "timestamp-function-number_of_distributed_sources-sample_size.txt"
  MSE
  MAPE
  execution_time
  network_io

  ## Experimental Setup
  Functions: f1, f2, f3, f4, f5, etc.
  Number of Distributed Sources: 4, 8, 12, 16, 20, 24, 28, 32, 36
  Sample_size in MB: 0.001, 0.01, 0.1, 1, 10, 100, 1000, 2000, 3000, etc.



### Required parameters:
* `n_of_procs` is the number of distributed nodes on which the experiment will rely.
* `n_of_examples` is the number of all examples (synthetic data sets) from which 80% will be used for training purposes and the latter 20% will be used for assessment.
* `synthetic_function` is the function that will be used to create the synthetic data sets. Currently, these are the available functions:
 * $f1(x1, x2) = sin(x1).*sin(x2)./(x1.*x2) + rand(Normal(0,0.1),size(x1)[1])$
 * $f2(x1, x2, x3) = 0.01.*x1 + 0.02.*x2.^(2) + 0.9.*x3.^(3) + rand(Normal(0,0.1),size(x1)[1])$
 * $f3(x1, x2) = 0.6.*x1 + 0.3.*x2 + rand(Normal(0,0.1),size(x1)[1])$
 * $f10(x) = 10.*sin(pi.*x[:,1].*x[:,2]) + 20(x[:,3]-0.5).^2 + 10.*x[:,4] + 5.*x[:,5] + 10.*sin(pi.*x[:,6].*x[:,7]) + 20(x[:,8]-0.5).^2 + 10.*x[:,9] + 5.*x[:,10] + rand(Normal(0,0.1),size(x[:,1])[1])$
* `seed` specifies the seed that will be used to generate the TODO.
* `number_of_neighborhoods` 
* `variances` specifies the variance value(s) that should be used for each `number_of_neighborhoods`. If `variances` is set to a single value, it will apply this value to all neighborhoods.
* `number_of_data_set_dimensions` 

### Optional arguments:
TODO move `seed` to this section

* TODO `prefix` will be used as prefix to name output files.
* TODO `suffix` will be used as suffix to name output files.
 
`
