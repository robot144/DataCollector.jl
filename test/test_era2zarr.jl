# test_era2zarr.jl
# This script tests the conversion of ERA5 NetCDF data to Zarr format using the convert_era5_to_zarr function from the DataCollector module. 

using TOML
using Zarr

function test_generation_of_toml_input_file()
    # Define the path to the test NetCDF file and the expected output directory
    netcdf_file = joinpath("..","..", "test_data", "era5_wind_201312_40_-15_65_20.nc")
    
    # Create a configuration file for the conversion
    cd(temp_dir)
    convert_era5_to_zarr([netcdf_file])
    config_file = joinpath(pwd(), "config_era2zarr.toml")
    
    # Check if the configuration file was created and contains the expected content
    @test isfile(config_file)
    config_content = TOML.parsefile(config_file)
    @test "global" in keys(config_content)
    @test "10m_v_component_of_wind" in keys(config_content)
    @test "mean_sea_level_pressure" in keys(config_content)
    @test "10m_u_component_of_wind" in keys(config_content)
    @test "netcdf_files" in keys(config_content["global"])
    ["global", "10m_v_component_of_wind", "mean_sea_level_pressure", "10m_u_component_of_wind"]
    @test config_content["10m_u_component_of_wind"]["scale_factor"]≈0.01
    
end

function test_convert_era5_to_zarr()
    # Define the path to the test NetCDF file and the expected output directory
    netcdf_file = joinpath(pwd(),"..","..", "test_data", "era5_wind_201312_40_-15_65_20.nc")
    output_dir = temp_dir
    config_file = joinpath(pwd(),"..","..","test_data", "config_era5_wind.toml")
    # copy both files to the temp directory
    netcdf_temp=joinpath(temp_dir, basename(netcdf_file))
    config_temp=joinpath(temp_dir, basename(config_file))
    cp(netcdf_file, netcdf_temp)
    cp(config_file, config_temp)
        
    # Call the conversion function with the test NetCDF file and configuration file
    convert_era5_to_zarr([config_temp])
    
    # Check if the Zarr output directory was created
    @test isdir(output_dir)
    
    # Check if the expected Zarr files were created (this is just an example, adjust as needed)
    zarr_file = joinpath(output_dir, "era5_wind.zarr")
    @test isdir(zarr_file)
    
    # Open Zarr file and check if it contains the expected variables
    zarr_data = Zarr.zopen(zarr_file)
    @test "10m_v_component_of_wind" in keys(zarr_data.arrays)
    @test "mean_sea_level_pressure" in keys(zarr_data.arrays)
    @test "10m_u_component_of_wind" in keys(zarr_data.arrays)
    @test size(zarr_data["10m_u_component_of_wind"]) == (141, 101, 744) # check dimensions of the variable
    @test size(zarr_data["10m_v_component_of_wind"]) == (141, 101, 744) # check dimensions of the variable
    @test size(zarr_data["mean_sea_level_pressure"]) == (141, 101, 744) # check dimensions of the variable
end

# era2zarr conversion for a file with wave variables
function test_convert_era5_waves_to_zarr()
    # Define the path to the test NetCDF file and the expected output directory
    netcdf_file = joinpath(pwd(),"..","..", "test_data", "era5_waves_201312_40_-15_65_20.nc")
    output_dir = temp_dir
    config_file = joinpath(pwd(),"..","..","test_data", "config_era5_waves.toml")
    # copy both files to the temp directory
    netcdf_temp=joinpath(temp_dir, basename(netcdf_file))
    config_temp=joinpath(temp_dir, basename(config_file))
    cp(netcdf_file, netcdf_temp)
    cp(config_file, config_temp)
        
    # Call the conversion function with the test NetCDF file and configuration file
    convert_era5_to_zarr([config_temp])
    
    # Check if the Zarr output directory was created
    @test isdir(output_dir)
    
    # Check if the expected Zarr files were created (this is just an example, adjust as needed)
    zarr_file = joinpath(output_dir, "era5_waves.zarr")
    @test isdir(zarr_file)
    
    # Open Zarr file and check if it contains the expected variables
    zarr_data = Zarr.zopen(zarr_file)
    @test "mean_wave_direction" in keys(zarr_data.arrays)
    @test "mean_wave_period" in keys(zarr_data.arrays)
    @test "significant_height_of_combined_wind_waves_and_swell" in keys(zarr_data.arrays)
end

# Run the tests
test_generation_of_toml_input_file()
test_convert_era5_to_zarr()
test_convert_era5_waves_to_zarr()