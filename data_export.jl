using CSV, DataFrames

# This file defines some generic functions used for exporting results

function createDF(list_of_dataseries, list_of_names)
    df = DataFrame(
        list_of_dataseries, :auto
    )
    rename!(df, Symbol.(list_of_names))
    return df
end

function export_dataframe(df, name)
    CSV.write("$(pwd())\\results\\$name.csv", df)
end

function easy_export(list_of_dataseries, list_of_names, filename)
    typed_dataseries = [[list_of_dataseries[i][t] for t = 1:length(list_of_dataseries[i])] for i = 1:length(list_of_dataseries)]
    df = createDF(typed_dataseries, list_of_names)
    export_dataframe(df, filename)
    print("\n\nExported file: $filename\n\n")
end
