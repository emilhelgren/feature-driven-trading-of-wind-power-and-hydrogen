using DataFrames
using CSV


negative_prices = false

#--------------------------------------------------------------------------
#----------------------------------IMPORTS---------------------------------
#--------------------------------------------------------------------------
all_data = DataFrame(CSV.File("./data/2022_data.csv"))
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

year = 8760
month = 24 * 30
