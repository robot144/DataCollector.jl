module DataCollector

# Load required packages
using PythonCall
using CondaPkg
using Plots
using Dates
using NetCDF
using Zarr
using JSON

include("era5.jl")
export CDS, get_all_months, check_cdsapirc, check_conda_packages
export standard_variables

end # module DataCollector
