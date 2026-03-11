%% run_STI_from_nc_fullgrid.m
% Compute the Standardized Temperature Index (STI) for all grid cells in a NetCDF file.
%
% INPUT FILE (NetCDF):
%   mx2t.nc
%
% REQUIRED VARIABLES IN INPUT:
%   mx2t : daily temperature array with dimensions that include (time, lat, lon)
%          (dimension order can be any; the script detects it automatically)
%   time : daily time coordinate (leap days removed; 365-day calendar assumed)
%   lat  : latitude vector
%   lon  : longitude vector
%
% OUTPUT FILE (NetCDF):
%   STI.nc
%
% VARIABLES IN OUTPUT:
%   STI(time, lat, lon) : Standardized Temperature Index for every grid cell
%   time, lat, lon      : copied from the input file
%
% METHOD:
%   For each grid cell:
%     1) extract the daily mx2t time series
%     2) remove NaNs
%     3) compute STI using STI_func(Data, 1, 365)
%     4) put NaNs back in their original positions
%
% DEPENDENCIES:
%   - STI_func.m must be on the MATLAB path (provided in this repository)
%   - MATLAB NetCDF functions: ncinfo, ncread, nccreate, ncwrite, ncwriteatt
%   - Statistics functions: normfit, normcdf, norminv

clear; clc;

%% ---- User settings ----
inFile   = 'mx2t.nc';
varIn    = 'mx2t';

outFile  = 'STI.nc';
varOut   = 'STI';

scale = 1;      % daily
nseas = 365;    % DOY bins (365-day calendar; leap days removed)

%% ---- Read coordinate variables ----
time = ncread(inFile, 'time');
lat  = ncread(inFile, 'lat');
lon  = ncread(inFile, 'lon');

%% ---- Read mx2t and permute to (time, lat, lon) ----
% The input mx2t variable may store dimensions in any order.
% This section detects dimension names and permutes the array to (time, lat, lon).
info = ncinfo(inFile, varIn);
dimNames = {info.Dimensions.Name};

X = ncread(inFile, varIn);

timeDim = find(strcmpi(dimNames, 'time'), 1);
latDim  = find(strcmpi(dimNames, 'lat'), 1);
lonDim  = find(strcmpi(dimNames, 'lon'), 1);

if isempty(timeDim) || isempty(latDim) || isempty(lonDim)
    error('Could not identify time/lat/lon dimensions for variable "%s".', varIn);
end

% Move time -> 1
perm = 1:numel(dimNames);
perm([1, timeDim]) = perm([timeDim, 1]);
dimNames2 = dimNames(perm);

% Move lat -> 2
latPos = find(strcmpi(dimNames2, 'lat'), 1);
perm2 = 1:numel(dimNames2);
perm2([2, latPos]) = perm2([latPos, 2]);
dimNames3 = dimNames2(perm2);

% Move lon -> 3
lonPos = find(strcmpi(dimNames3, 'lon'), 1);
perm3 = 1:numel(dimNames3);
perm3([3, lonPos]) = perm3([lonPos, 3]);

finalPerm = perm(perm2(perm3));
X = permute(X, finalPerm);

% Remove singleton dimensions (e.g., level=1)
X = squeeze(X);

% Final array shape: (time, lat, lon)
nTime = size(X, 1);
nLat  = size(X, 2);
nLon  = size(X, 3);

fprintf('Read %s with size (time,lat,lon) = (%d, %d, %d)\n', varIn, nTime, nLat, nLon);

%% ---- Reshape to (time x nPoints) for grid-wise processing ----
X2 = reshape(X, nTime, nLat*nLon);
nPoints = size(X2, 2);

STI2 = NaN(size(X2));

%% ---- Compute STI for each grid cell ----
for p = 1:nPoints
    tempData = X2(:, p);

    idxValid = ~isnan(tempData);
    nonNaNData = tempData(idxValid);

    if ~isempty(nonNaNData)
        tempSTI = STI_func(nonNaNData, scale, nseas);
        STI2(idxValid, p) = tempSTI;
    end

    if mod(p, 25) == 0 || p == nPoints
        fprintf('Processed %d / %d grid cells\n', p, nPoints);
    end
end

%% ---- Reshape back to (time, lat, lon) ----
STI3 = reshape(STI2, nTime, nLat, nLon);

%% ---- Write output NetCDF ----
% Output uses dimensions (time, lat, lon) and stores the full STI field.
if exist(outFile, 'file') == 2
    delete(outFile);
end

nccreate(outFile, 'time', 'Dimensions', {'time', Inf}, 'Datatype', 'double');
nccreate(outFile, 'lat',  'Dimensions', {'lat',  nLat}, 'Datatype', 'double');
nccreate(outFile, 'lon',  'Dimensions', {'lon',  nLon}, 'Datatype', 'double');

nccreate(outFile, varOut, ...
    'Dimensions', {'time', Inf, 'lat', nLat, 'lon', nLon}, ...
    'Datatype', 'double');

ncwrite(outFile, 'time', double(time));
ncwrite(outFile, 'lat',  double(lat));
ncwrite(outFile, 'lon',  double(lon));
ncwrite(outFile, varOut, double(STI3));

%% ---- Write metadata ----
% Copy time attributes from input when available, then set calendar to 365_day.
try
    tinfo = ncinfo(inFile, 'time');
    for a = 1:numel(tinfo.Attributes)
        ncwriteatt(outFile, 'time', tinfo.Attributes(a).Name, tinfo.Attributes(a).Value);
    end
catch
end
ncwriteatt(outFile, 'time', 'calendar', '365_day');

ncwriteatt(outFile, '/', 'source_file', inFile);
ncwriteatt(outFile, '/', 'note', 'STI computed grid-wise from mx2t using STI_func(Data,1,365).');
ncwriteatt(outFile, varOut, 'long_name', 'Standardized Temperature Index');

fprintf('Saved output: %s (variable: %s)\n', outFile, varOut);