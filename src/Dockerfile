FROM julialang/julia:v0.4.7

MAINTAINER Naelson Douglas

# Julia
RUN wget https://julialang-s3.julialang.org/bin/linux/x64/0.6/julia-0.6.2-linux-x86_64.tar.gz
RUN tar -xvf julia*.tar.gz
RUN rm julia*.tar.gz
RUN mv julia* julia
RUN mv julia ~/julia
RUN export PATH=$PATH:/root/julia/bin

RUN apt-get install -y cmake
RUN apt-get install -y hdf5-tools

RUN apt update
RUN apt-get install -y docker.io

# #
# # DML stuff
# #
# RUN git clone https://github.com/NaelsonDouglas/DistributedMachineLearningThesis.git
# # adding packages
# RUN ~/julia/bin/julia -e 'Pkg.add("Clustering")'
# RUN ~/julia/bin/julia -e 'Pkg.add("Distributions")'
# RUN ~/julia/bin/julia -e 'Pkg.add("MultivariateStats")'
# RUN ~/julia/bin/julia -e 'Pkg.add("Debug")'
# #RUN ~/julia/bin/julia -e 'Pkg.add("HDF5")'
# RUN ~/julia/bin/julia -e 'Pkg.add("Mocha")'
# RUN ~/julia/bin/julia -e 'Pkg.add("DataFrames")'
# RUN ~/julia/bin/julia -e 'Pkg.add("Distances")'
# RUN ~/julia/bin/julia -e 'Pkg.add("Logging")'
# # pinning packages
# RUN ~/julia/bin/julia -e 'Pkg.pin("Mocha", v"0.3.1")'
# RUN ~/julia/bin/julia -e 'Pkg.pin("Clustering", v"0.7.0")'
# RUN ~/julia/bin/julia -e 'Pkg.pin("MultivariateStats", v"0.3.0")'
# RUN ~/julia/bin/julia -e 'Pkg.pin("Debug", v"0.1.5")'
# RUN ~/julia/bin/julia -e 'Pkg.pin("Distributions", v"0.15.0")'
#TODO Pkg.clone("https://github.com/ararslan/OperatingSystems.jl.git")

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/root/julia/bin/"
