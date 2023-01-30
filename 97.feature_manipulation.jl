using DataFrames
using CSV

function mean(arr)
    return sum(arr) / length(arr)
end

case_study = true
negative_prices = false

if (case_study)

    #--------------------------------------------------------------------------
    #----------------------------------IMPORTS---------------------------------
    #--------------------------------------------------------------------------
    lambda_F = DataFrame(CSV.File("./data/forward.csv"))[:, 2]
    # lambda_F = DataFrame(CSV.File("./data/2020/prices_formatted.csv"))[:,6]
    lambda_UP = DataFrame(CSV.File("./data/balance_up.csv"))[:, 3]
    lambda_DW = DataFrame(CSV.File("./data/balance_dw.csv"))[:, 3]

    if !negative_prices
        for i in collect(1:length(lambda_F))
            lambda_F[i] = max(lambda_F[i], 0)
            lambda_UP[i] = max(lambda_UP[i], 0)
            lambda_DW[i] = max(lambda_DW[i], 0)
        end
    end
    lambda_bal = []
    lambda_capped = []
    for i in collect(1:length(lambda_F))
        if (lambda_DW[i] != lambda_F[i])
            push!(lambda_bal, lambda_DW[i])
        else
            push!(lambda_bal, lambda_UP[i])
        end
        push!(lambda_capped, min(lambda_F[i], 70))
    end


    realized = DataFrame(CSV.File("./data/realized.csv"))[:, 2]
    forecast = DataFrame(CSV.File("./data/forecasts.csv"))[:, 2]

    # Features are:
    # offshore_DK2 | offshore_DK1 | onshore_DK2 | onshore_DK1 | solar_DK2
    x = DataFrame(CSV.File("./data/features.csv"))
    # x = DataFrame(CSV.File("./data/features_with_realized.csv"))
    x = x[:, 2:size(x)[2]]          # Remove first column which is just the index
    n_features = size(x)[2]

    include("hydrogen_prices.jl")

    #--------------------------------------------------------------------------
    #----------------------------MODEL PARAMETERS------------------------------
    #--------------------------------------------------------------------------


    MAKE_BALANCING_PRICES_MORE_RADICAL = false

    if (MAKE_BALANCING_PRICES_MORE_RADICAL)
        lambda_UP = lambda_UP .- 10
        lambda_DW = lambda_DW .+ 10
    end


    # Normalizing so values are in [0, 1.0]
    max_value = max(maximum(realized), maximum(forecast))

    realized = realized ./ max_value
    forecast = forecast ./ max_value


else
    lambda_F = [
        50,
        41,
        43,
        59,
        62,
        5,
        15,
        14,
        43,
        80
    ]

    realized = [
        4,
        5,
        7,
        13,
        16,
        3,
        4,
        3,
        7,
        8
    ]

    noises = [0.14061535, 0.37138286, 0.07020545, -0.29961158, 0.46524342, -0.1333834, 0.15858667, -0.08122464, 0.26635708, -0.25882546]
    noises2 = [-0.40306416, -0.27295418, 0.17529272, -0.04035053, -0.06424059, -0.39669581, 0.35693065, -0.26102877, -0.31041123, -0.22175083]
    forecast = [realized[i] + noises[i] for i in eachindex(realized)]

    max_value = max(maximum(realized), maximum(forecast))

    realized = realized ./ max_value
    forecast = forecast ./ max_value

    x = DataFrame(CSV.File("./data/features.csv"))
    x = x[1:length(realized), 2:size(x)[2]]          # Remove first column which is just the index
    n_features = size(x)[2]

    lambda_UP_s = [[min(lambda_F[i] - 3, lambda_F[i] + noises[i] * 10 + noises2[j]) for i in eachindex(lambda_F)] for j in 1:10]
    lambda_DW_s = [[min(lambda_F[i] + 3, lambda_F[i] + noises[i] * 10 + noises2[j]) for i in eachindex(lambda_F)] for j in 1:10]
end



nominal_wind_capacity = 10.0    # Random decision
max_elec_capacity = 10.0        # Random decision
adj_penalty = 0.000001          # Not even used anymore

E_real = realized .* nominal_wind_capacity

max_wind_capacity = nominal_wind_capacity * 1.3     # Random decision
M = max(max_wind_capacity, max_elec_capacity)


periods = collect(1:length(lambda_F))
# periods = collect(1:730*2) # 730 is 1 month

# Random decision
lambda_H = hydrogen_price
# lambda_H = mean(lambda_F)*1.9   
# lambda_H = 40

lambda_F_checker = zeros(length(lambda_F))
for i in eachindex(lambda_F)
    if (lambda_F[i] > lambda_H)
        lambda_F_checker[i] = 1
    end
end
# print(lambda_F_checker)


#------------------------CHECK FEATURES FOR MISSING

# anymissing = false

# for i in collect(1:length(E_real))
#     for n in collect(1:n_features)
#         if (ismissing(x[i, n]))
#             print("Missing value at $(i)")
#             print("Missing value at $(i)")
#             print("Missing with feature $(n)")
#             print("Missing value at $(i)")
#             anymissing = true
#         end

#     end

# end
# if (!anymissing)
#     print("NO MISSING VALUES!")
# end

#------------------------CHECK PRICES FOR MISSING

# anymissing = false

# for i in collect(1:length(E_real))
#     if (ismissing(lambda_F[i]))
#         print("Missing value at $(i)")
#         print("Missing value at $(i)")
#         print("Missing value at $(i)")
#         anymissing = true
#     end
# end
# if (!anymissing)
#     print("NO MISSING VALUES!")
# end