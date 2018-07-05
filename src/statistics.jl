@everywhere using StatsBase: Histogram, fit
@everywhere using StatsBase

@everywhere function summary_statistics(X1)
    summary = [k for k in mean(X1,1)]
    append!(summary, [k for k in var(X1,1)])
    push!(summary, kurtosis(X1,1))
    push!(summary, skewness(X1,1))
    return summary
end

@everywhere function order_statistics(dataset, k=7, pow=2)
    powers = 1:pow
    len,attributes = size(dataset)
    orders = [floor(Int,(len/k)*(i-1))+1 for i=1:k]
    statistics = []
    for attribute in 1:attributes
        sorted = sort(dataset[:,attribute])
        for p in powers
            append!(statistics, [sorted[k]^p for k in orders])
        end
    end
    statistics = reduce(hcat, statistics)
    return statistics
end
        

@everywhere function distance(X,Y,w=0)
    if weights != 0
        d = [((X[i] - Y[i]).*w[i]).^2 for i in 1:length(X)]
    else
        d = [(X[i] - Y[i]).^2 for i in 1:length(X)]
    end
    #d = sqrt(sum([[sum(d[i]) for i in 1:length(Y)]...]))
    d = sqrt(sum(d))
    return d
end

@everywhere function abs_distance(X,Y,w=0)
    if weights != 0
        d = [abs((X[i] - Y[i]).*w[i]) for i in 1:length(X)]
    else
        d = [abs(X[i] - Y[i]) for i in 1:length(X)]
    end
    #d = sqrt(sum([[sum(d[i]) for i in 1:length(Y)]...]))
    d = sum(d)
    return d
end


###
#  Calculates the mean squared error of a set of predictions.
#
#  predictions: the predicted values (y hat).
#  y: the original values.
###
@everywhere function MSE(predictions, y)
    return mean((predictions .- y).^2)
end

@everywhere function MSLE(predictions, y)
    return mean((log(predictions) .- log(y)).^2)
end

###
#  Calculates the mean percentage error of a set of predictions.
#
#  predictions: the predicted values (y hat).
#  y: the original values.
###
@everywhere function MAPE(predictions, y)
    return 100*mean(abs.((y .- predictions)./y))
end

@everywhere function R2(predictions, y)
    SSres = sum((predictions .- y).^2)
    ymean = mean(y)
    SStot = sum((y .- ymean).^2)
    return 1 - (SSres/SStot)
end

###
#  Calculates the maximum and minimum value of every column (attribute) on the
#  dataset.
#
#  dataset: input dataset. Every column is an attribute.
#  Returns: vector where every i element is a tuple with the min and max of the
#  i attribute.
###
@everywhere function get_maxmin(dataset)
    _,attributes = size(dataset)
    # we calculate max and min for each attribute of the dataset
    return [extrema(dataset[:,x]) for x in 1:attributes]
end

###
#  Calculates the intervals for an histogram created from a set of max and mins
#  values.
#
#  globalmaxmin: matrix where every column is the min (1) and max (2) value of
#                an attribute from the dataset. It should have n columns where
#                n is the number of attributes of the dataset.
#  nubs: number of nubs for the histogram.
#  Returns: array of StepRange containing every interval for the histogram.
###
@everywhere function calculate_histogram_bins(globalmaxmin; nubs=5)
    bin_limits = Array{Float64}[]
    attributes = try
        _, a = size(globalmaxmin)
        a
    catch
        1
    end

    for attribute in 1:attributes
        x = globalmaxmin[1,attribute] : (globalmaxmin[2,attribute]-globalmaxmin[1,attribute])/nubs : globalmaxmin[2,attribute]
        push!(bin_limits, x)
    end

    return tuple(bin_limits...)
end

###
#  Create a histogram of the dataset using as limits the global maximum and
#  minimum of the dataset.
#
#  dataset: input dataset. Every column is an attribute.
#  globalmaxmin: globalmaxmin: matrix where every column is the min (1) and max (2) value of
#                an attribute from the dataset. It should have n columns where
#                n is the number of attributes of the dataset.
#  Returns: vector or matrix of weights of the calculated histogram.
###
@everywhere function create_histogram(dataset, globalmaxmin)
    examples, attributes = try
        e, a = size(dataset)
    catch
        e, a = (size(dataset)[1], 1)
    end
    bin_limits = calculate_histogram_bins(globalmaxmin)

    # create tuple
    data = tuple(dataset[:,1])
    for attribute in 2:attributes
        data = tuple(data..., dataset[:,2])
    end
    histogram = fit(Histogram, data, bin_limits, closed=:left)
    return histogram.weights
end


###
#  Returns a sparse and normalized (by a factor) version of an histogram.
#
#  histogram: weights of the histogram (matrix or vector).
#  factor: factor of normalization.
#  Returns: sparse matrix representing the normalized histogram.
###
@everywhere function sparse_relative_histogram(histogram, factor)
    return sparse(histogram./factor)
end

###
#  Calculate the euclidean and city block distances from two vector x and y.
###
@everywhere function calculate_distances(x, y)
    euc = sqrt(sum((x - y) .^ 2))
    cit = sum(abs.(x - y))
    t = (euc,cit)
    return collect(t)
end
