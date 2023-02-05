using DataFrames
using CSV


negative_prices = false

#--------------------------------------------------------------------------
#----------------------------------IMPORTS---------------------------------
#--------------------------------------------------------------------------
all_data = DataFrame(CSV.File("./data/2020_data.csv"))
include("hydrogen_prices.jl")


lambda_F = all_data[:, "forward_RE"]
lambda_F_fc = all_data[:, "forward_FC"]
lambda_UP = all_data[:, "UP"]
lambda_DW = all_data[:, "DW"]
lambda_H = hydrogen_price

if !negative_prices
    for i in collect(1:length(lambda_F))
        lambda_F[i] = max(lambda_F[i], 0)
        lambda_F_fc[i] = max(lambda_F_fc[i], 0)
        lambda_UP[i] = max(lambda_UP[i], 0)
        lambda_DW[i] = max(lambda_DW[i], 0)
    end
end


x = all_data[:, ["Offshore DK2", "Offshore DK1", "Onshore DK2", "Onshore DK1", "production_FC", "forward_RE"]]
x_rf = all_data[:, ["production_FC", "forward_RE"]]


n_features = size(x)[2]



#--------------------------------------------------------------------------
#----------------------------MODEL PARAMETERS------------------------------
#--------------------------------------------------------------------------


nominal_wind_capacity = 10.0
max_wind_capacity = nominal_wind_capacity
max_elec_capacity = 10.0
min_production = 50

deterministic_forecast = all_data[:, ["production_FC"]] .* nominal_wind_capacity
E_real = all_data[:, "production_RE"] .* nominal_wind_capacity

M = max(max_wind_capacity, max_elec_capacity) + 9999999

periods = collect(1:length(lambda_F))


# --------------Create features
q_forecast_calculated = [12.195654545757634, 0.5299454470522954, 1.2367673427003123, -0.5444726493505923, 4.9381332869069965]
q_intercept_calculated = -0.13315441932264693

x_fm = []
for t in collect(1:length(lambda_F))
    push!(x_fm, [sum(q_forecast_calculated[i] * x[t, i] for i in collect(1:(n_features-1))) + q_intercept_calculated, lambda_F[t]])
end

year = 8760
month = 24 * 30
