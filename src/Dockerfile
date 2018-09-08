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

# Docker
RUN apt update
RUN apt-get install -y docker.io

# sshd 
 RUN apt-get install -y openssh-server
 RUN mkdir /var/run/sshd \
	 && echo 'AuthorizedKeysFile %h/.ssh/authorized_keys' >> /etc/ssh/sshd_config \
     && sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd \
     && sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
     && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
	 && echo 'root:root' |chpasswd
 EXPOSE 22
 CMD    ["/usr/sbin/sshd", "-D"]
 # SSH key
RUN ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -q -N ""
#RUN mkdir -p $HOME/.ssh \
#	&& chmod 700 $HOME/.ssh \
RUN cat $HOME/.ssh/id_rsa.pub > $HOME/.ssh/authorized_keys \
	&& chmod 600 $HOME/.ssh/authorized_keys 

#TODO uncomment the first comment column
# #
# # DML stuff
# #
# RUN git clone https://github.com/NaelsonDouglas/DistributedMachineLearningThesis.git
# # adding packages
# RUN ~/julia/bin/julia -e 'Pkg.add("CSV")'
# RUN ~/julia/bin/julia -e 'Pkg.add("DataFrames")'
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
# RUN ~/julia/bin/julia -e 'Pkg.pin("CSV", v"0.2.5")'
# RUN ~/julia/bin/julia -e 'Pkg.pin("DataFrames", v"0.11.7")'
# RUN ~/julia/bin/julia -e 'Pkg.pin("Mocha", v"0.3.1")'
# RUN ~/julia/bin/julia -e 'Pkg.pin("Clustering", v"0.7.0")'
# RUN ~/julia/bin/julia -e 'Pkg.pin("MultivariateStats", v"0.3.0")'
# RUN ~/julia/bin/julia -e 'Pkg.pin("Debug", v"0.1.5")'
# RUN ~/julia/bin/julia -e 'Pkg.pin("Distributions", v"0.15.0")'
#TODO Pkg.clone("https://github.com/ararslan/OperatingSystems.jl.git")

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/root/julia/bin/"
