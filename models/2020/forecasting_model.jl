
using Gurobi
using JuMP
using DataFrames
using CSV

include("../data_loader_2020.jl")

# Not using validation year for training forecasts
periods = collect(1:8760)


psi_up = 1
psi_dw = 1

#Declare Gurobi model
prediction_model = Model(Gurobi.Optimizer)

#Definition of variables
@variable(prediction_model, E_settle[t in periods])
@variable(prediction_model, b[t in periods], Bin) # Binary variable indicating if we are deficit_settle (1) or surplus_settle (0)
@variable(prediction_model, 0 <= E_DW[t in periods])
@variable(prediction_model, 0 <= E_UP[t in periods])
@variable(prediction_model, q_forecast[1:(n_features-1)])
@variable(prediction_model, q_intercept)

#Maximize profit
@objective(prediction_model, Min,
    1 / length(periods) *
    sum(
        psi_up * E_DW[t]
        +
        psi_dw * E_UP[t]
        for t in periods)
)

# q_fixet = [1, 0, 0, 0, 0]
# Power surplus == POSITIVE, deficit == NEGATIVE
@constraint(prediction_model, settlement[t in periods], E_real[t] - (sum(q_forecast[i] * x[t, i] for i in collect(1:(n_features-1))) + q_intercept) == E_settle[t])

@constraint(prediction_model, surplus_settle1[t in periods], E_DW[t] >= E_settle[t])
@constraint(prediction_model, surplus_settle2[t in periods], E_DW[t] <= E_settle[t] + M * b[t])
@constraint(prediction_model, surplus_settle3[t in periods], E_DW[t] <= M * (1 - b[t]))

@constraint(prediction_model, deficit_settle1[t in periods], E_UP[t] >= -E_settle[t])
@constraint(prediction_model, deficit_settle2[t in periods], E_UP[t] <= -E_settle[t] + M * (1 - b[t]))
@constraint(prediction_model, deficit_settle3[t in periods], E_UP[t] <= M * (b[t]))

# @constraint(prediction_model, fixer1, q_forecast[1] == 1)
# @constraint(prediction_model, fixer2[i in collect(2:n_features)], q_forecast[i] == 0)
# @constraint(prediction_model, fixer3, q_intercept == 0)



optimize!(prediction_model)


print("\n\n\n")
print("Objective value: $(objective_value(prediction_model))")
print("\n")
print("Total surplus: $(sum(value.(E_DW)))")

print("\n")
print("Total deficit: $(sum(value.(E_UP)))")
print("\n")

print("q values: ")
print(value.(q_forecast))
print("\n")
print("intercept: $(value(q_intercept))")

