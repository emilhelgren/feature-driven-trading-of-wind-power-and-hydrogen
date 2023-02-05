
using Gurobi
using JuMP
using DataFrames
using CSV

include("../data_loader_2020.jl")


function get_deterministic_plan(bidding_start)

    offset = bidding_start
    periods = collect(1:24)

    #Declare Gurobi model
    deterministic_plan = Model(Gurobi.Optimizer)

    #Definition of variables
    @variable(deterministic_plan, 0 <= hydrogen[t in periods])
    @variable(deterministic_plan, forward_bid[t in periods])

    #Maximize profit
    @objective(deterministic_plan, Max,
        sum(
            lambda_F_fc[t+offset] * forward_bid[t]
            +
            lambda_H * hydrogen[t]
            for t in periods
        )
    )

    #Max capacity
    @constraint(deterministic_plan, wind_capacity_up[t in periods], forward_bid[t] <= max_wind_capacity)
    @constraint(deterministic_plan, wind_capacity_dw[t in periods], forward_bid[t] >= -max_elec_capacity)
    @constraint(deterministic_plan, elec_capacity[t in periods], hydrogen[t] <= max_elec_capacity)

    #Min production
    @constraint(deterministic_plan, sum(hydrogen[t] for t in periods) >= min_production)

    #Based on forecasted production
    @constraint(deterministic_plan, bidding[t in periods], forward_bid[t] + hydrogen[t] == max(0, min(deterministic_forecast[t+offset, 1], max_wind_capacity)))

    optimize!(deterministic_plan)

    print("\n\n\nCheck obj: $(objective_value(deterministic_plan))")
    print("\n\n\nCheck bidding_start: $(bidding_start)")
    print("\n\n\n")

    return value.(forward_bid), value.(hydrogen)
end


validation_period = year
all_forward_bids = []
all_hydrogen_productions = []

for i in 1:(365)
    bidding_start = length(lambda_F) - (validation_period) + (i - 1) * 24 # - 24

    forward_bids, hydrogen_production = get_deterministic_plan(bidding_start)

    for j in 1:24
        push!(all_forward_bids, forward_bids[j])
        push!(all_hydrogen_productions, hydrogen_production[j])
    end
end

print("\n\nCheck first 24 forward bids:")

for i in 1:24
    print("\n$(all_forward_bids[i])")
end

print("\n\nCheck first 24 hydrogen prods:")
for i in 1:24
    print("\n$(all_hydrogen_productions[i])")
end

# # #---------------------------EXPORT RESULTS--------------------------------
include("../data_export.jl")

data = [
    all_forward_bids,
    all_hydrogen_productions
]
names = [
    "forward bid",
    "hydrogen production"
]

filename = "2020/deterministic"


easy_export(data, names, filename,)