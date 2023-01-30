using DataFrames
using CSV


negative_prices = false

#--------------------------------------------------------------------------
#----------------------------------IMPORTS---------------------------------
#--------------------------------------------------------------------------
all_data = DataFrame(CSV.File("./data/2020_data.csv"))


lambda_F = all_data[:, "forward_RE"]
lambda_F_fc = all_data[:, "forward_FC"]
lambda_UP = all_data[:, "UP"]
lambda_DW = all_data[:, "DW"]

if !negative_prices
    for i in collect(1:length(lambda_F))
        lambda_F[i] = max(lambda_F[i], 0)
        lambda_F_fc[i] = max(lambda_F_fc[i], 0)
        lambda_UP[i] = max(lambda_UP[i], 0)
        lambda_DW[i] = max(lambda_DW[i], 0)
    end
end


x = all_data[:, ["Offshore DK2", "Offshore DK1", "Onshore DK2", "Onshore DK1", "production_FC", "forward_RE"]]
x_fp = all_data[:, ["production_FC", "forward_RE"]]


n_features = size(x)[2]


# # --------------------For forecast model-------------------------------
# forecast_production = []
# for t in collect(1:length(lambda_F))
#     push!(forecast_production, sum(q_forecast_calculated[i] * x[t, i] for i in collect(1:(n_features-1))) + q_intercept_calculated)
# end

# include("98.data_export.jl")
# names = [
#     "forecast_production"
# ]
# filename = "2020_forecast_model"
# easy_export([forecast_production], names, filename)
# print("\n 2020_forecast_model should be exported successfully")
# ---------------------------------------------------


include("hydrogen_prices.jl")

#--------------------------------------------------------------------------
#----------------------------MODEL PARAMETERS------------------------------
#--------------------------------------------------------------------------


nominal_wind_capacity = 10.0    # Random decision
max_wind_capacity = nominal_wind_capacity
max_elec_capacity = 10.0        # Random decision
adj_penalty = 0.000001          # Not even used anymore
min_production = 50             # Random decision
penalty = 80.61

realized = all_data[:, "production_RE"]

deterministic_forecast = all_data[:, ["production_FC"]] .* nominal_wind_capacity
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


# --------------Create features
q_forecast_calculated = [12.195654545757634, 0.5299454470522954, 1.2367673427003123, -0.5444726493505923, 4.9381332869069965]
q_intercept_calculated = -0.13315441932264693

x_max = []
for t in collect(1:length(lambda_F))
    push!(x_max, [sum(q_forecast_calculated[i] * x[t, i] for i in collect(1:(n_features-1))) + q_intercept_calculated, lambda_F[t]])
end

year = 8760
month = 24 * 30



# forecasted_values = []
# q_forecast_calculated = [12.195654545757634, 0.5299454470522954, 1.2367673427003123, -0.5444726493505923, 4.9381332869069965]
# q_intercept_calculated = -0.13315441932264693

# for t in collect(1:length(lambda_F))
#     push!(forecasted_values, sum(q_forecast_calculated[i] * x[t, i] for i in collect(1:(n_features-1))) + q_intercept_calculated)
# end
# include("./98.data_export.jl")
# data = [
# forecasted_values
# ]
# names = [
#     "forecast_production"
# ]
# filename = "2020_forecast_model"
# easy_export(data, names, filename,)