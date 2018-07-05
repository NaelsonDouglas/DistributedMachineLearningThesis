# RUN
julia -L master_summary.jl -e "execute_experiment()" $n_procs $n_samples $function $seed $num_nodes $dim_func
julia -L master.jl -e "execute_experiment()" $n_procs $n_samples $function $seed $num_nodes $dim_func
# Por ejemplo:
julia -L master_summary.jl -e "execute_experiment()" 8 100 f1 1234 4 2
julia -L master.jl -e "execute_experiment()" 8 100 f1 1234 4 2

# Pkg.status()
Archivo status.txt 

# Documentation

## Overview

TODO explain the project and the role of each file, just an overview to let users understand what it is and how it works, cite the paper (link to download page at publisher) which presents the approach.

## Dependencies

> julia InstallDeps.jl

##  Run experiments

> $N_OF_NODES = 2
>
> julia -L master.jl -e 'execute_experiment()' $N_OF_NODES



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
