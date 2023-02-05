
using Gurobi
using JuMP
using DataFrames
using CSV

include("./data_loader_2022.jl")
# include("./data_loader_2020.jl")

# # q_forecast_calculated = [-0.0027792641093648844, 5.3095079931734414e-5, 0.0009156337303219116, 0.00030928988309446607, 10.202692293270667]
# # q_intercept_calculated = -0.07158987201495201
q_forecast_calculated = [-0.0009697214399537231, 0.001441424240892253, -0.00011728840868511542, -0.0003482922421105428, 11.272596492303315]
q_intercept_calculated = 0.02068638333208402
forecast_model = [[sum(q_forecast_calculated[i] * x[t, i] for i in collect(1:(n_features-1))) + q_intercept_calculated for t in collect(1:length(lambda_F))]]
filename = "forecast_model"
names = ["forecast_production"]
easy_export(forecast_model, names, filename,)
print("\n\n")
print("export successful")

