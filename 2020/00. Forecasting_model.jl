
using Gurobi
using JuMP
using DataFrames
using CSV

include("../95.data_loader_2020.jl")

# Not using validation year for training forecasts
periods = collect(1:8760)


psi_up = 1
psi_dw = 1

#Declare Gurobi model
prediction_model = Model(Gurobi.Optimizer)

#Definition of variables
@variable(prediction_model, E_T[t in periods])
@variable(prediction_model, b[t in periods], Bin) # Binary variable indicating if we are buying (1) or selling (0)
@variable(prediction_model, 0 <= E_sold[t in periods])
@variable(prediction_model, 0 <= E_bought[t in periods])
@variable(prediction_model, q_forecast[1:(n_features-1)])
@variable(prediction_model, q_intercept)

#Maximize profit
@objective(prediction_model, Min,
    1 / length(periods) *
    sum(
        psi_up * E_sold[t]
        +
        psi_dw * E_bought[t]
        for t in periods)
)

# q_fixet = [1, 0, 0, 0, 0]
# Power SOLD == POSITIVE, BOUGHT == NEGATIVE
@constraint(prediction_model, trade[t in periods], E_real[t] - (sum(q_forecast[i] * x[t, i] for i in collect(1:(n_features-1))) + q_intercept) == E_T[t])

@constraint(prediction_model, selling1[t in periods], E_sold[t] >= E_T[t])
@constraint(prediction_model, selling2[t in periods], E_sold[t] <= E_T[t] + M * b[t])
@constraint(prediction_model, selling3[t in periods], E_sold[t] <= M * (1 - b[t]))

@constraint(prediction_model, buying1[t in periods], E_bought[t] >= -E_T[t])
@constraint(prediction_model, buying2[t in periods], E_bought[t] <= -E_T[t] + M * (1 - b[t]))
@constraint(prediction_model, buying3[t in periods], E_bought[t] <= M * (b[t]))

# @constraint(prediction_model, fixer1, q_forecast[1] == 1)
# @constraint(prediction_model, fixer2[i in collect(2:n_features)], q_forecast[i] == 0)
# @constraint(prediction_model, fixer3, q_intercept == 0)



optimize!(prediction_model)


print("\n\n\n")
print("Objective value: $(objective_value(prediction_model))")
print("\n")
print("Total sold: $(sum(value.(E_sold)))")

print("\n")
print("Total bought: $(sum(value.(E_bought)))")
print("\n")

print("q values: ")
print(value.(q_forecast))
print("\n")
print("intercept: $(value(q_intercept))")

