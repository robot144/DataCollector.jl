#! /bin/bash

export PROJECT_DIR=..
#generate the config file
if [ ! -f ./config_era2zarr.toml ]; then
    julia --project=$PROJECT_DIR $PROJECT_DIR/src/convert_era2zarr.jl ./era5_*/*.nc
    echo "config_era2zarr.toml generated, you can edit it to specify the input and output files and parameters" 
    echo "after editing, run this script again to convert the data to zarr format"
else
    # convert to zarr
    julia --project=$PROJECT_DIR $PROJECT_DIR/src/convert_era2zarr.jl ./config_era2zarr.toml
fi