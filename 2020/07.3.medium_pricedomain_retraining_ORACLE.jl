
using Gurobi
using JuMP
using DataFrames
using CSV

include("../95.data_loader_2022.jl")


function get_initial_plan(training_period_length, bidding_start)
    # period length is the amount of timesteps used for training
    # bidding_start is the timestep for the first bid, it is expected that 24 bids are needed

    if (training_period_length % 24 != 0)
        throw(ErrorException("Training period must be a multiple of 24 hours!"))
    end

    offset = bidding_start - training_period_length
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
    @variable(initial_plan, qF[1:(n_features+1), 1:24, 1:3])
    @variable(initial_plan, qH[1:(n_features+1), 1:24, 1:3])

    @variable(initial_plan, 0 <= hydrogen[t in periods])
    @variable(initial_plan, forward_bid[t in periods])

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
    @constraint(initial_plan, wind_capacity_up[t in periods], forward_bid[t] <= max_wind_capacity)
    @constraint(initial_plan, wind_capacity_dw[t in periods], forward_bid[t] >= -max_elec_capacity)
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
            if lambda_F[t+offset] < lambda_H
                @constraint(initial_plan, forward_bid[t] == sum(qF[i, index, 1] * x[t+offset, i] for i in 1:n_features) + qF[n_features+1, index, 1])
                @constraint(initial_plan, hydrogen[t] == sum(qH[i, index, 1] * x[t+offset, i] for i in 1:n_features) + qH[n_features+1, index, 1])
            elseif lambda_F[t+offset] < 420 # 80% quantile
                @constraint(initial_plan, forward_bid[t] == sum(qF[i, index, 2] * x[t+offset, i] for i in 1:n_features) + qF[n_features+1, index, 2])
                @constraint(initial_plan, hydrogen[t] == sum(qH[i, index, 2] * x[t+offset, i] for i in 1:n_features) + qH[n_features+1, index, 2])
            else
                @constraint(initial_plan, forward_bid[t] == sum(qF[i, index, 3] * x[t+offset, i] for i in 1:n_features) + qF[n_features+1, index, 3])
                @constraint(initial_plan, hydrogen[t] == sum(qH[i, index, 3] * x[t+offset, i] for i in 1:n_features) + qH[n_features+1, index, 3])
            end
        end
    end

    optimize!(initial_plan)

    return [[value.(qF[i, :, d]) for i in 1:(n_features+1)] for d in 1:3], [[value.(qH[i, :, d]) for i in 1:(n_features+1)] for d in 1:3]
end

function get_forecasted_plan(training_period_length, bidding_start)
    # period length is the amount of timesteps used for training
    # bidding_start is the timestep for the first bid, it is expected that 24 bids are needed

    if (training_period_length % 24 != 0)
        throw(ErrorException("Training period must be a multiple of 24 hours!"))
    end

    offset = bidding_start - training_period_length
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
    @variable(initial_plan, qF[1:3, 1:24, 1:3])
    @variable(initial_plan, qH[1:3, 1:24, 1:3])

    @variable(initial_plan, 0 <= hydrogen[t in periods])
    @variable(initial_plan, forward_bid[t in periods])

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
    @constraint(initial_plan, wind_capacity_up[t in periods], forward_bid[t] <= max_wind_capacity)
    @constraint(initial_plan, wind_capacity_dw[t in periods], forward_bid[t] >= -max_elec_capacity)
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
            if lambda_F[t+offset] < lambda_H
                @constraint(initial_plan, forward_bid[t] == sum(qF[i, index, 1] * x_max[t+offset][i] for i in 1:2) + qF[3, index, 1])
                @constraint(initial_plan, hydrogen[t] == sum(qH[i, index, 1] * x_max[t+offset][i] for i in 1:2) + qH[3, index, 1])
            elseif lambda_F[t+offset] < 420 # 80% quantile
                @constraint(initial_plan, forward_bid[t] == sum(qF[i, index, 2] * x_max[t+offset][i] for i in 1:2) + qF[3, index, 2])
                @constraint(initial_plan, hydrogen[t] == sum(qH[i, index, 2] * x_max[t+offset][i] for i in 1:2) + qH[3, index, 2])
            else
                @constraint(initial_plan, forward_bid[t] == sum(qF[i, index, 3] * x_max[t+offset][i] for i in 1:2) + qF[3, index, 3])
                @constraint(initial_plan, hydrogen[t] == sum(qH[i, index, 3] * x_max[t+offset][i] for i in 1:2) + qH[3, index, 3])
            end
        end
    end

    optimize!(initial_plan)

    return [[value.(qF[i, :, d]) for i in 1:3] for d in 1:3], [[value.(qH[i, :, d]) for i in 1:3] for d in 1:3]
end

TIME_SAVER = Dict()

include("../98.data_export.jl")

# print("\n\n")
# print("\n---------------------------BASE--------------------------------")
# print("\n---------------------------BASE--------------------------------")
# print("\n---------------------------BASE--------------------------------")
# print("\n\n")
# # # #---------------------------BASE--------------------------------
# for i in 1:1
#     starttime = time()
#     n_months = i
#     training_period = month * n_months
#     validation_period = month
#     test_period = month
#     for v in 1:(validation_period+test_period)

#         if (v % (720) == 0)
#             print("\nAnother month has passed! Retraining the models...\n")
#             bidding_start = length(lambda_F) - validation_period - test_period

#             qFs, qHs = get_initial_plan(training_period, bidding_start)

#             # # #---------------------------EXPORT RESULTS--------------------------------
#             data = vcat([qFs[d][i] for i in 1:(n_features+1) for d in 1:3], [qHs[d][i] for i in 1:(n_features+1) for d in 1:3])
#             names = vcat(["qF$(d)_$i" for i in 1:(n_features+1) for d in 1:3], ["qH$(d)_$i" for i in 1:(n_features+1) for d in 1:3])

#             filename = "2022/changing_qs_medium/$(n_months)_month_training/medium_pricedomain_retraining_ORACLE_mo$(Int(round(v/720)))"
#             easy_export(data, names, filename,)

#         end
#     end

#     endtime = time()
#     TIME_SAVER["standard model $i months training"] = endtime - starttime

# end

# --------------Create features
q_forecast_calculated = [11.741815153756818, 0.5052203334864828, 1.2665132803689987, -0.5123299439229754, -0.0004919796618249656, 5.069285841010844]
q_intercept_calculated = -0.10602052387103919
x_max = []
for t in collect(1:length(lambda_F))
    push!(x_max, [sum(q_forecast_calculated[i] * x[t, i] for i in collect(1:(n_features-1))) + q_intercept_calculated, lambda_F[t]])
end

print("\nCheck de første dele af x_max:")
print("\n\n")
print(x_max[1:5, :])

print("\n\n")
print("\n---------------------------forecast_model--------------------------------")
print("\n---------------------------forecast_model--------------------------------")
print("\n---------------------------forecast_model--------------------------------")
print("\n\n")
# # #---------------------------forecast_model--------------------------------
for i in 1:3
    starttime = time()
    n_months = i
    training_period = month * n_months
    validation_period = month
    test_period = month

    for v in 1:(validation_period+test_period)

        if (v % (720) == 0)
            print("\nAnother month has passed! Retraining the models...\n")
            bidding_start = length(lambda_F) - validation_period - test_period

            qFs, qHs = get_forecasted_plan(training_period, bidding_start)

            data = vcat([qFs[d][i] for i in 1:3 for d in 1:3], [qHs[d][i] for i in 1:3 for d in 1:3])
            names = vcat(["qF$(d)_$i" for i in 1:3 for d in 1:3], ["qH$(d)_$i" for i in 1:3 for d in 1:3])

            filename = "2022/changing_qs_medium/$(n_months)_month_training/medium_forecast_model_pricedomain_retraining_ORACLE_mo$(Int(round(v/720)))"
            easy_export(data, names, filename,)

        end
    end

    endtime = time()
    TIME_SAVER["forecasted model $i months training"] = endtime - starttime
end

# print("\n\n")
# print("\n---------------------------FP--------------------------------")
# print("\n---------------------------FP--------------------------------")
# print("\n---------------------------FP--------------------------------")
# print("\n\n")
# x = all_data[:, ["production_FC", "forward_RE"]]
# n_features = size(x)[2]
# # # #---------------------------FP--------------------------------
# for i in 1:3
#     starttime = time()
#     n_months = i
#     training_period = month * n_months
#     validation_period = month
#     test_period = month

#     for v in 1:(validation_period+test_period)

#         if (v % (720) == 0)
#             print("\nAnother month has passed! Retraining the models...\n")
#             bidding_start = length(lambda_F) - validation_period - test_period

#             qFs, qHs = get_initial_plan(training_period, bidding_start)

#             data = vcat([qFs[d][i] for i in 1:(n_features+1) for d in 1:3], [qHs[d][i] for i in 1:(n_features+1) for d in 1:3])
#             names = vcat(["qF$(d)_$i" for i in 1:(n_features+1) for d in 1:3], ["qH$(d)_$i" for i in 1:(n_features+1) for d in 1:3])

#             filename = "2022/changing_qs_medium/$(n_months)_month_training/medium_fp_pricedomain_retraining_ORACLE_mo$(Int(round(v/720)))"
#             easy_export(data, names, filename,)

#         end
#     end

#     endtime = time()
#     TIME_SAVER["fp $i months training"] = endtime - starttime
# end




print("\n\n")
print("Check times:")
print("\n")
print(TIME_SAVER)
