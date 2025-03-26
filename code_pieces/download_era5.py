#!/usr/bin/env python
# download ERA5 surface data using the CDS API.

import cdsapi

c = cdsapi.Client()

# area:  starting latitude and longitude followed by the ending latitude and longitude
c.retrieve(
    'reanalysis-era5-single-levels',
    {
        'product_type':'reanalysis',
        'format':'netcdf',
        'variable':[
            '10m_u_component_of_wind','10m_v_component_of_wind','mean_sea_level_pressure','sea_ice_cover'
        ],
        'area':'70/0/85/40',
        'year':'2014',
        'month':['03'],
        'day':[
            '01','02','03',
            '04','05','06'
        ],
        'time':[
            '00:00','01:00','02:00',
            '03:00','04:00','05:00',
            '06:00','07:00','08:00',
            '09:00','10:00','11:00',
            '12:00','13:00','14:00',
            '15:00','16:00','17:00',
            '18:00','19:00','20:00',
            '21:00','22:00','23:00'
        ]
    },
    'era5_wind_20140301_06.nc')

[{'type': 'dict_type', 'loc': ['body', 'inputs'], 'msg': 'Input should be a valid dictionary', 'input': ''
''
'{
   "day":["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"],
   "format":"netcdf",
   "month":["12"],
   "time":["00:00","01:00","02:00","03:00","04:00","05:00","06:00","07:00","08:00","09:00","10:00","11:00","12:00","13:00","14:00","15:00","16:00","17:00","18:00","19:00","20:00","21:00","22:00","23:00"],
   "area":"40/-15/65/20",
   "year":"2013",
   "product_type":"reanalysis",
   "variable":["10m_u_component_of_wind","10m_v_component_of_wind","mean_sea_level_pressure"]
   }'
