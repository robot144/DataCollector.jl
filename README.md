
# DataCollector.jl

There are several common datasets for coastal hydrodynamics that are used very often. The aim is to assist in downloading these data within the Julia language. Since most data providers opt to provide tools written in Python, we regularly have to call Python from Julia, for which there is good support.

## Datasets

### ERA5 from CDS

First version is running for winds and pressure, but the the code needs to be cleaned for more general use.
The folder `era5_template` contains a template for downloading ERA5 data from the Copernicus Climate Data Store (CDS). The scripts assume that credentials are stored in `~/.cdsapirc`.
The template also contains a script to convert the downloaded NetCDF files to Zarr format, which is more efficient for reading in Julia.

### Matroos timeseries database 

The Matroos database is maintained by Rijkswaterstaat and contains a lot of coastal measurements. The database is not open, but one can request access. There is only a test using a bash script at the moment. This will be converted to Julia later.

### Copernicus Marine Environment Monitoring Service (CMEMS)

