include("96.data_loader.jl")


# --------------Create features
q_forecast_calculated = [11.741815153756818, 0.5052203334864828, 1.2665132803689987, -0.5123299439229754, -0.0004919796618249656, 5.069285841010844]
q_intercept_calculated = -0.10602052387103919
x_max = []
for t in collect(1:length(lambda_F))
    push!(x_max, [sum(q_forecast_calculated[i] * x[t, i] for i in collect(1:(n_features-1))) + q_intercept_calculated, lambda_F[t]])
end


export_features = false

if (export_features)
    x_max1 = []
    x_max2 = []
    for t in collect(1:length(lambda_F))
        push!(x_max1, sum(q_forecast_calculated[i] * x[t, i] for i in collect(1:n_features)) + q_intercept_calculated)
        push!(x_max2, lambda_F[t])
    end
    include("98.data_export.jl")
    data = [
        x_max1,
        x_max2
    ]
    names = [
        "x_max1",
        "x_max2"
    ]
    filename = "x_max"
    easy_export(data, names, filename,)
    print("\n Features should be exported successfully")
end
