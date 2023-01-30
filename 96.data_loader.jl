using DataFrames
using CSV


negative_prices = false

#--------------------------------------------------------------------------
#----------------------------------IMPORTS---------------------------------
#--------------------------------------------------------------------------
prices = DataFrame(CSV.File("./data/prices_and_status.csv"))
lambda_DW = prices[:, 2] # Up and down is reversed compared to what  they are called in the dataframe!
lambda_UP = prices[:, 3]
lambda_F = prices[:, 4]
lambda_bal = prices[:, 5]
system_deficit = prices[:, 6]
system_surplus = prices[:, 7]
hydrogen_status = prices[:, 8]
hydrogen_max_pred = prices[:, 9]
hydrogen_min_pred = prices[:, 10]
hydrogen_max_real = prices[:, 9]
hydrogen_min_real = prices[:, 10]
lambda_F_fc = prices[:, 13]

if !negative_prices
    for i in collect(1:length(lambda_F))
        lambda_F[i] = max(lambda_F[i], 0)
        lambda_UP[i] = max(lambda_UP[i], 0)
        lambda_DW[i] = max(lambda_DW[i], 0)
        lambda_bal[i] = max(lambda_bal[i], 0)
    end
end

features_all = DataFrame(CSV.File("./data/features.csv"))
x = features_all[:, ["offshore_DK2", "offshore_DK1", "onshore_DK2", "onshore_DK1", "forecast"]]
# x = features_all[:, ["forecast"]]
deterministic_forecast = features_all[:, ["forecast"]]
x[!, "forward"] = lambda_F
realized = features_all[:, "realized"]

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

nominal_wind_capacity = 10.0    # Random decision
max_wind_capacity = nominal_wind_capacity
max_elec_capacity = 10.0        # Random decision
adj_penalty = 0.000001          # Not even used anymore
min_production = 50             # Random decision
penalty = 137.36

E_real = realized .* nominal_wind_capacity

M = max(max_wind_capacity, max_elec_capacity) + 9999999

periods = collect(1:length(lambda_F))

# Random decision
lambda_H = hydrogen_price

lambda_F_checker = zeros(length(lambda_F))
for i in eachindex(lambda_F)
    if (lambda_F[i] > lambda_H)
        lambda_F_checker[i] = 1
    end
end

year = 8760
month = 24 * 30

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
#     print("NO MISSING FEATURE VALUES!")
# end

# #------------------------CHECK PRICES FOR MISSING

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
#     print("NO MISSING PRICE VALUES!")
# end

