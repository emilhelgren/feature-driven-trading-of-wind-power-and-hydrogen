
using Gurobi
using JuMP
using DataFrames
using CSV

include("../data_loader_2020.jl")
max_elec_capacity = 1
min_production = 5

function get_initial_plan(training_period_length, bidding_start, burned=0, two_price=true)
    # period length is the amount of timesteps used for training
    # bidding_start is the timestep for the first bid, it is expected that 24 bids are needed
    # burned is the amount of hours before the actual starting time the bid has to be submitted ()

    if (training_period_length % 24 != 0)
        throw(ErrorException("Training period must be a multiple of 24 hours!"))
    end

    offset = bidding_start - burned - training_period_length
    periods = collect(1:training_period_length)
    days = []
    n_days = Int(training_period_length / 24)
    for i in collect(1:n_days)
        day_offset = (i - 1) * 24
        push!(days, collect(1+day_offset:24+day_offset))
    end

    #Declare Gurobi model
    initial_plan = Model(Gurobi.Optimizer)

    #Definition of variables
    @variable(initial_plan, 0 <= E_DW[t in periods])
    @variable(initial_plan, 0 <= E_UP[t in periods])
    @variable(initial_plan, b[t in periods], Bin) # Binary variable indicating if we are deficit_settle (1) or surplus_settle (0)
    @variable(initial_plan, E_settle[t in periods])

    @variable(initial_plan, 0 <= hydrogen[t in periods])
    @variable(initial_plan, 0 <= hydrogen_extra[t in periods])
    @variable(initial_plan, forward_bid[t in periods])

    #Maximize profit
    @objective(initial_plan, Max,
        sum(
            lambda_F[t+offset] * forward_bid[t]
            + lambda_H * hydrogen[t]
            + lambda_DW[t+offset] * E_DW[t]
            -
            lambda_UP[t+offset] * E_UP[t]
            for t in periods
        )
    )

    #Max capacity
    @constraint(initial_plan, wind_capacity_up[t in periods], forward_bid[t] <= max_wind_capacity)
    @constraint(initial_plan, wind_capacity_dw[t in periods], forward_bid[t] >= -max_elec_capacity)
    @constraint(initial_plan, elec_capacity[t in periods], hydrogen[t] <= max_elec_capacity)

    # Power surplus == POSITIVE, deficit == NEGATIVE
    @constraint(initial_plan, settlement[t in periods], E_real[t+offset] - forward_bid[t] - hydrogen[t] == E_settle[t])

    @constraint(initial_plan, surplus_settle1[t in periods], E_DW[t] >= E_settle[t])
    @constraint(initial_plan, surplus_settle2[t in periods], E_DW[t] <= E_settle[t] + M * b[t])
    @constraint(initial_plan, surplus_settle3[t in periods], E_DW[t] <= M * (1 - b[t]))

    @constraint(initial_plan, deficit_settle1[t in periods], E_UP[t] >= -E_settle[t])
    @constraint(initial_plan, deficit_settle2[t in periods], E_UP[t] <= -E_settle[t] + M * (1 - b[t]))
    @constraint(initial_plan, deficit_settle3[t in periods], E_UP[t] <= M * (b[t]))

    for day in days
        @constraint(initial_plan, sum(hydrogen[t] for t in day) >= min_production)
        for t in day
            index = mod(t, 24)
            if (index == 0)
                index = 24
            end
        end
    end

    optimize!(initial_plan)

    print("\n\n\nCheck obj: $(objective_value(initial_plan))")
    return value.(forward_bid), value.(hydrogen)
end


training_period = year

bidding_start = length(lambda_F)
forward_bid, hydrogen_production = get_initial_plan(training_period, bidding_start, 0, true)
offset = bidding_start - training_period

for i in 95:105
    print("\n\n")
    print("i=$i")
    print("\n")
    print("Forward $(lambda_F[i+offset]), up=$(lambda_UP[i+offset]), dw=$(lambda_DW[i+offset])")
    print("\n")
    print("bid=$(forward_bid[i]), h_prod=$(hydrogen_production[i])")
    print("\n")

end



# # #---------------------------EXPORT RESULTS--------------------------------
include("../data_export.jl")

data = [
    hydrogen_production,
    forward_bid
]
names = [
    "hydrogen production",
    "forward bid"
]
filename = "2020_red_elec/optimal_everything"


easy_export(data, names, filename,)