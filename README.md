# Overview

TODO

For more information, read the paper [TODOaXivLink]().

# Running the experiments

## Requirements 
### [Docker](https://www.docker.com/products/docker-desktop)
### Code and data:

>git clone https://github.com/NaelsonDouglas/DistributedMachineLearningThesis.git

### Build the Docker image
Remark: GNU/Linux users may need to call `sudo` before `docker` command.

>cd src/ 

> docker build --no-cache -t dmlt .

## Run the experiments

### Create an interactive Docker container

This will open a Bash session by using the `dmlt` Docker image:

> docker run -it dmlt 

> cd DistributedMachineLearningThesis/src/

> time ~/julia/bin/julia -L master_summary.jl -e "execute_experiment()" 8 100 f1 1234 4 2

### Test the prototype
> cd DistributedMachineLearningThesis/src/

>julia -L master_summary.jl -e "execute_experiment()" 4 100 f1 1234 4 2 

## Understand the parameters

The line bellow name all the prototype parameters which are described next:

>julia -L master_summary.jl -e "execute_experiment()" \

>$n_procs \

>$n_samples \

>$function \

>$seed \

>$num_nodes \

>$dim_func


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
* `number_of_data_set_dimensions` 

### Optional arguments:

* TODO move `seed` to this section
* TODO `prefix` will be used as prefix to name output files.
* TODO `suffix` will be used as suffix to name output files.
* `variances` specifies the variance value(s) that should be used for each `number_of_neighborhoods`. If `variances` is set to a single value, it will apply this value to all neighborhoods.
 
## Output file format

TODO

`timestamp-function-number_of_distributed_sources-sample_size.txt`


# Prototype assessment

## Performance metrics

TODO

* Accuracy metrics
 * MSE
 * MAPE
* Time-related metrics 
 * execution_time
 * network_io

## Experimental Setup

The experiments used the following parameter configuration:

* Functions: f1, f2, f3, f4, f5, etc.
* Number of Distributed Sources: 4, 8, 12, 16, 20, 24, 28, 32, 36
* Sample_size in MB: 0.001, 0.01, 0.1, 1, 10, 100, 1000, 2000, 3000, etc.
* ...

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
  * ...
* write experiment data to files
  * input
  * configuration
  * output
  * execution time
* write documentation in Markdown
* See `#alage:` comments in the code
* allow parameter configuration (n. of repetitions, data set size, etc.)
* naming
  * replace `salida` by `output`
* why `@everywhere` in many parts of the code?
  * for example, in `workers.jl` it should be only necessary to call the code in the worker, do no need for `@everywhere`.
# Overview

TODO

For more information, read the paper [TODOaXivLink]().

# Running the experiments

## Requirements 
### [Docker](https://www.docker.com/products/docker-desktop)
### Code and data:

>git clone https://github.com/NaelsonDouglas/DistributedMachineLearningThesis.git

### Build the Docker image
Remark: GNU/Linux users may need to call `sudo` before `docker` command.

>cd src/ 

> docker build --no-cache -t dmlt .

## Run the experiments

### Create an interactive Docker container

This will open a Bash session by using the `dmlt` Docker image:

> docker run -it dmlt 

> cd DistributedMachineLearningThesis/src/

> time ~/julia/bin/julia -L master_summary.jl -e "execute_experiment()" 8 100 f1 1234 4 2

### Test the prototype
> cd DistributedMachineLearningThesis/src/

>julia -L master_summary.jl -e "execute_experiment()" 4 100 f1 1234 4 2 

## Understand the parameters

The line bellow name all the prototype parameters which are described next:

>julia -L master_summary.jl -e "execute_experiment()" \

>$n_procs \

>$n_samples \

>$function \

>$seed \

>$num_nodes \

>$dim_func


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
* `number_of_data_set_dimensions` 

### Optional arguments:

* TODO move `seed` to this section
* TODO `prefix` will be used as prefix to name output files.
* TODO `suffix` will be used as suffix to name output files.
* `variances` specifies the variance value(s) that should be used for each `number_of_neighborhoods`. If `variances` is set to a single value, it will apply this value to all neighborhoods.
 
## Output file format

TODO

`timestamp-function-number_of_distributed_sources-sample_size.txt`


# Prototype assessment

## Performance metrics

TODO

* Accuracy metrics
 * MSE
 * MAPE
* Time-related metrics 
 * execution_time
 * network_io

## Experimental Setup

The experiments used the following parameter configuration:

* Functions: f1, f2, f3, f4, f5, etc.
* Number of Distributed Sources: 4, 8, 12, 16, 20, 24, 28, 32, 36
* Sample_size in MB: 0.001, 0.01, 0.1, 1, 10, 100, 1000, 2000, 3000, etc.
* ...

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
  * ...
* write experiment data to files
  * input
  * configuration
  * output
  * execution time
* write documentation in Markdown
* See `#alage:` comments in the code
* allow parameter configuration (n. of repetitions, data set size, etc.)
* naming
  * replace `salida` by `output`
* why `@everywhere` in many parts of the code?
  * for example, in `workers.jl` it should be only necessary to call the code in the worker, do no need for `@everywhere`.
