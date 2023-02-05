# Feature-driven trading of wind and hydrogen

This repository contains the entire code-base associated with the Master thesis "Feature-driven trading of wind and hydrogen" by Emil Helgren at the Technical University of Denmark (DTU), February 2023.

## Guide to the code

This README file is divided into the following sections:

- Important general comments
- Overview of files
- Running the models
- Evaluating the models

### Important general comments

All string values throughout the code refers to specific filenames or headers in data files that are specific to the data being used. The researcher should thus be aware of all occurrences of strings, since the filenames of input data or model results will be dependent on what the researcher has called their files, and in which specific relative paths they are located. All code containing paths to data and model results should thus be expected to cause errors if run directly without considering the actual location of the files being referred to.

To keep the code base to a manageable size and respect the confidentiality required for some of the data, only a few key results are provided, and none of the data is provided in the repository. The code files containing references to specific data or results no longer appearing in the repository thus serves as a reference for how the formatting and testing was performed, and should be modified to the data available for the researcher, and the results produced by the researcher, in order to be usable.

### Overview of files

All optimization problems are calculated using Julia (.jl files), and Python (.ipynb files) is used to create the dataset and perform evaluations and investigations of the data and results. All models are found in separate .jl files the "models" folder. Each feature-driven model contains all three feature-vectors in each file. All python files are created as jupyter notebooks, with the content divided into appropriate sections, and with all functions having a description comment explaining the functionality. 

In the root of the project, 2 python notebooks for data formatting are found:

- "synthetic_forecasts.ipynb"
  - This file fits theoretical distributions to the forecast data provided by Siemens Gamesa.
- "data_formatter.iypnb"
  - This file formats price and production data from ENTSO-E transparency platform, and utilizes the distributions found in "synthetic_forecasts.ipynb" to create the final dataset. The file generate the data for 2020 as an example.

Three other python notebooks for evaluation are found:

- "evaluation_2020.ipynb"
- "evaluation_2020_1MW_electrolyzer.ipynb"
- "evaluation_2022.ipynb"

These notebooks perform evaluations of all models in the three different contexts given by the filenames.

Finally, 5 julia files are found in the root as well:

- "data_export.jl"
  - This file holds generic functions for exporting model parameters for feature-driven models, and results for deterministic and hindsight models.
- "data_loader_2020.jl"
  - This files loads and formats data for 2019-2020 so the models can use it directly.
- "data_loader_2022.jl"
  - This files loads and formats data for 5 months in 2022 so the models can use it directly.
- "hydrogen_prices.jl"
  - This file calculates a MWh-equivalent hydrogen price.
- "save_improved_forecasts.jl"
  - This file exports the improved forecasts provided by the forecasting model, so the evaluation files can import the values.

Inside the "models" folder, the models follow the naming convention of the report.

Inside the "results" folder are the results of the deterministic, hindsight and best performing learned model in each evaluation context.

### Running the models

To run the models, two steps are required: (1): Create an appropriate data_loader file, and (2): Create a "results" folder to hold the trained model parameters (for feature-driven models) or results (for deterministic and hindsight models).

#### Creating a data_loader file

The first step is to create an appropriate data_loader file for the data at hand. By reusing the exact parameter names from the existing data_loader files "data_loader_2020.jl" and "data_loader_2022.jl", the model training (feature-driven) and application (deterministic and hindsight) can be run directly without modification.

#### Saving the results

In each model file, the results are exported as a .csv file. The location within the "results" folder and the filename of the exported results should be reviewed by the researcher to ensure the location for saving exists in the project structure, and that the filename is appropriate.

### Evaluating the models

The three evaluation notebooks are divided into explanatory sections, with the section "Testing the models" performing comparative evaluation of all the models. The files primarily focus on the "Total test period revenue" metric by which the models are compared to each other, but also perform in-depth statistical and operational analyses of the models that were not included in the final report.
