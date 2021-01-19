using Random: shuffle!

# Pass through the population several times, replacing the oldest
# with the fittest of a small subsample
function regEvolCycle(X::Array{Float32, 2}, y::Array{Float32, 1}, baseline::Float32, pop::Population, T::Float32, curmaxsize::Integer,
                      frequencyComplexity::Array{Float32, 1}, options::Options)::Population
    # Batch over each subsample. Can give 15% improvement in speed; probably moreso for large pops.
    # but is ultimately a different algorithm than regularized evolution, and might not be
    # as good.
    if options.fast_cycle
        shuffle!(pop.members)
        n_evol_cycles = round(Integer, pop.n/options.ns)
        babies = Array{PopMember}(undef, n_evol_cycles)

        # Iterate each ns-member sub-sample
        @inbounds Threads.@threads for i=1:n_evol_cycles
            best_score = Inf32
            best_idx = 1+(i-1)*options.ns
            # Calculate best member of the subsample:
            for sub_i=1+(i-1)*options.ns:i*options.ns
                if pop.members[sub_i].score < best_score
                    best_score = pop.members[sub_i].score
                    best_idx = sub_i
                end
            end
            allstar = pop.members[best_idx]
            babies[i] = iterate(X, y, baseline, allstar, T, curmaxsize, frequencyComplexity, options)
        end

        # Replace the n_evol_cycles-oldest members of each population
        @inbounds for i=1:n_evol_cycles
            oldest = argmin([pop.members[member].birth for member=1:pop.n])
            pop.members[oldest] = babies[i]
        end
    else
        for i=1:round(Integer, pop.n/options.ns)
            allstar = bestOfSample(pop, options)
            baby = iterate(X, y, baseline, allstar, T, curmaxsize, frequencyComplexity, options)
            #printTree(baby.tree)
            oldest = argmin([pop.members[member].birth for member=1:pop.n])
            pop.members[oldest] = baby
        end
    end

    return pop
end
