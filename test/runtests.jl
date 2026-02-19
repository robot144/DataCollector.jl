
using Test
using DataCollector

#clear cache
cache_dir = joinpath(pwd(),".cache")
if isdir(cache_dir)
   rm(cache_dir,recursive=true)
else
   mkdir(cache_dir)
end
@show cache_dir

temp_dir= joinpath(pwd(),"temp")
if isdir(temp_dir) # remove temp directory if it exists
    rm(temp_dir,recursive=true)
end
mkdir(temp_dir) # create a new empty temp directory
@show temp_dir

@testset "Tools for downloading data from external sources" begin

   @testset "Downloading of ERA5 reanalysis data from CDS" begin
      include("test_era5.jl")
   end


end