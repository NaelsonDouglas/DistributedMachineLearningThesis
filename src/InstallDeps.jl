default_packages="Mocha Logging StatsBase MultivariateStats Distributions Clustering DataFrames Distances"

clone_packages=Dict(
                    "NeuralNets"    => "https://github.com/anj1/NeuralNets.jl.git",
                    "CloudArray"    => "https://github.com/gsd-ufal/CloudArray.jl.git"
                    )

Pkg.update()
installed = Pkg.installed()

# Docker.jl must be the first package
if !haskey(installed,"Docker")
    Pkg.clone("https://github.com/Keno/Docker.jl.git")
end

for pkg in split(default_packages)
    info("Adding default package $pkg")
    Pkg.add("$pkg")
end

for pkg in keys(clone_packages)
    if !haskey(installed,pkg) # not installed? Pkg.clone!
        Pkg.clone(clone_packages[pkg])
    end
end

Pkg.update()

# precompiling
using Logging, StatsBase, MultivariateStats, Distributions, Clustering, DataFrames, Distances, NeuralNets, CloudArray, Docker
