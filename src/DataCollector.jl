module DataCollector

# Load required packages
using PythonCall
using CondaPkg
using Plots
using Dates
using NetCDF
using Zarr
using JSON
using NCDatasets
using CommonDataModel
using TOML

include("era5.jl")
export CDS, get_all_months, check_cdsapirc, check_conda_packages
export standard_variables

include("era2zarr.jl")
export convert_era5_to_zarr

end # module DataCollector
