# Test era5 downloads

# Test era5 download for a range of months
function test1()
    era5 = CDS()
    filenames=get_all_months(era5,temp_dir,(1980,1),(1980,2),[43,-15,64,13],"winds",true)
    @show filenames
    @test length(filenames)==2
    @test endswith(filenames[1],"era5_winds_198001_43_-15_64_13.nc")
end

test1()
