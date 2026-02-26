# convert_era2zarr.jl
# This script converts ERA5 reanalysis data in NetCDF format to Zarr format.
# It can be called from the command line with the following arguments:
# 1. One or more NetCDF files containing ERA5 data (e.g., "era5_wind_*_40_-15_65_20.nc")
# 2. A configuration file in TOML format (e.g., "config_era2zarr.toml") that specifies the output directory and other options.

using DataCollector

if !(abspath(PROGRAM_FILE) == @__FILE__)
   error("This script is not meant to be included as a module. Please run it from the command line like this: 
   julia --project=<path_to_src> convert_era2zarr.jl config_era2zarr.toml")
end
    
println("ARGS = $(ARGS)")
@time convert_era5_to_zarr(ARGS)

nothing