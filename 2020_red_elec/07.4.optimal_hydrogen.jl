
using Gurobi
using JuMP
using DataFrames
using CSV

include("../95.data_loader_2020.jl")


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
    @variable(initial_plan, 0 <= E_sold[t in periods])
    @variable(initial_plan, 0 <= E_bought[t in periods])
    @variable(initial_plan, b[t in periods], Bin) # Binary variable indicating if we are buying (1) or selling (0)
    @variable(initial_plan, E_T[t in periods])

    @variable(initial_plan, 0 <= hydrogen[t in periods])
    @variable(initial_plan, 0 <= forward_bid[t in periods])

    #Maximize profit
    @objective(initial_plan, Max,
        sum(
            lambda_F[t+offset] * forward_bid[t]
            + lambda_H * hydrogen[t]
            + lambda_UP[t+offset] * E_sold[t]
            -
            lambda_DW[t+offset] * E_bought[t]
            for t in periods
        )
    )

    #Max capacity
    @constraint(initial_plan, wind_capacity[t in periods], forward_bid[t] <= max_wind_capacity)
    @constraint(initial_plan, elec_capacity[t in periods], hydrogen[t] <= max_elec_capacity)

    # Power SOLD == POSITIVE, BOUGHT == NEGATIVE
    @constraint(initial_plan, trade[t in periods], E_real[t+offset] - forward_bid[t] - hydrogen[t] == E_T[t])

    @constraint(initial_plan, selling1[t in periods], E_sold[t] >= E_T[t])
    @constraint(initial_plan, selling2[t in periods], E_sold[t] <= E_T[t] + M * b[t])
    @constraint(initial_plan, selling3[t in periods], E_sold[t] <= M * (1 - b[t]))

    @constraint(initial_plan, buying1[t in periods], E_bought[t] >= -E_T[t])
    @constraint(initial_plan, buying2[t in periods], E_bought[t] <= -E_T[t] + M * (1 - b[t]))
    @constraint(initial_plan, buying3[t in periods], E_bought[t] <= M * (b[t]))

    for day in days
        @constraint(initial_plan, sum(hydrogen[t] for t in day) >= min_production)
        for t in day
            index = mod(t, 24)
            if (index == 0)
                index = 24
            end
            # @constraint(initial_plan, forward_bid[t] == lambda_F_checker[t+offset] * (x_max[t+offset][1] * q_F1[index] + q_F2[index] * x_max[t+offset][2] + q_F3[index]))
            # @constraint(initial_plan, hydrogen[t] == x_max[t+offset][1] * q_H1 + q_H2 * x_max[t+offset][2] + q_H3)
        end
    end

    optimize!(initial_plan)

    for day in days
        print("\n")
        print("\nCheck hydrogen prod: $(sum(value(hydrogen[t]) for t in day)) >= $(min_production)?")
        print("\nTotal bid: $(sum(value(forward_bid[t]) for t in day)), total prod: $(sum(E_real[t+offset] for t in day))")
        print("\nTotal bought: $(sum(value(E_bought[t]) for t in day)), total sold: $(sum(value(E_sold[t]) for t in day))")
    end

    negative_bid = false
    for t in periods
        if (value(forward_bid[t]) < 0)
            negative_bid = true
            print("\n")
            print("\nFor index $t forward bid is: $(value(forward_bid[t]))")
            print("\nForecast was: $(x_max[t+offset][1])")
            print("\nForward price was: $(x_max[t+offset][2])")
        end
    end
    if (!negative_bid)
        print("\n\n")
        print("THERE WAS NO NEGATIVE BIDS")
    end

    print("\n\n")
    print("Check offset: $offset")


    # qF = [[value(q_F1[hour]), value(q_F2[hour]), value(q_F3[hour])] for hour in collect(1:24)]
    # qH = [[value(q_H1[hour]), value(q_H2[hour]), value(q_H3[hour])] for hour in collect(1:24)]
    # for hour in collect(1:24)
    #     print("\n\nFor hour $hour")
    #     print("\nCheck qF: $(qF[hour])")
    #     print("\nCheck qH: $(qH[hour])")

    # end

    # For checking if indeces in python are correct 
    for day in days[1]
        for t in day
            print("\n\nCurrently t=$t")
            index = mod(t, 24)
            if (index == 0)
                index = 24
            end
            # lambda_DW is BOUGHT
            # lambda_UP is SOLD
            if lambda_F[t+offset] < lambda_H
                print("\n")
                print("We want a zero-valued forward bid")
            else
                print("\n")
                print("We want a non-zero forward bid")
            end
            if (lambda_UP[t+offset] > lambda_H)
                print("\n")
                print("We want to SELL with no hydro")
            end
            if (lambda_DW[t+offset] < lambda_H)
                print("\n")
                print("We want to BUY with full hydro")
            end
            print("\n")
            print("b-price: $(lambda_DW[t+offset]), s-price: $(lambda_UP[t+offset]), f-price: $(lambda_F[t+offset]), real: $(E_real[t+offset])")
            print("\n")
            print("We ended up with hydro: $(value(hydrogen[t])), buy: $(value(E_bought[t])), sell: $(value(E_sold[t])), forward: $(value(forward_bid[t]))")
            # print("\nFor t=$t, hydrogen=$(value(hydrogen[t])), forecast=$(x_max[t+offset][1])")
        end
    end


    print("\n\n\nCheck obj: $(objective_value(initial_plan))")
    return value.(forward_bid), value.(hydrogen)
end

is_2020 = true
# training_period = month
training_period = year
if is_2020
    validation_period = year
else
    validation_period = 0
end
bidding_start = length(lambda_F) - validation_period
forward_bid, hydrogen_production = get_initial_plan(training_period, bidding_start, 0, true)


for i in 1:60
    print("\n")
    print("t=$i, hydro=$(hydrogen_production[i])")

end
# # #---------------------------EXPORT RESULTS--------------------------------
include("../98.data_export.jl")

data = [
    hydrogen_production,
    forward_bid
]
names = [
    "hydrogen production",
    "forward bid"
]
if is_2020
    filename = "2020_red_elec/RES_05.2_o_everything"
else
    filename = "RES_05.2_o_everything"
end

easy_export(data, names, filename,)