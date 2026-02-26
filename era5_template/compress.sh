#! /bin/bash

export PROJECT_DIR=..
julia --project=$PROJECT_DIR $PROJECT_DIR/src/convert_era2zarr.jl ./era5_northsea_201312.toml