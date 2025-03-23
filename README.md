
# DataCollector.jl

There are several common datasets for coastal hydrodynamics that are used very often. The aim is to assist in downloading these data within the Julia language. Since most data providers opt to provide tools written in Python, we regularly have to call Python from Julia, for which there is good support.

## Datasets

### ERA5 from CDS

First version is running for winds and pressure, but the the code needs to be cleaned for more general use.