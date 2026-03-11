%% run_medianTau_from_nc_fullgrid.m
% Compute the median soil-moisture dry-down time constant (medianTau) for all grid cells
% in a NetCDF file (swvl1.nc), then save the medianTau map to medianTau.nc.
%
% INPUT FILE (NetCDF):
%   swvl1.nc
%
% REQUIRED VARIABLES IN INPUT:
%   swvl1 : daily soil moisture array with dimensions that include (time, lat, lon)
%           (dimension order can be any; the script detects it automatically)
%   time  : daily time coordinate (365-day calendar; leap days removed)
%   lat   : latitude vector
%   lon   : longitude vector
%
% OUTPUT FILE (NetCDF):
%   medianTau.nc
%
% VARIABLES IN OUTPUT:
%   medianTau(lat, lon) : median dry-down time constant (tau, in days) for each grid cell
%   lat, lon            : copied from the input file
%
% METHOD:
%   For each grid cell:
%     1) extract the daily swvl1 time series
%     2) compute tau estimates using SM_drydowns2(series)
%     3) remove NaNs from tau estimates
%     4) medianTau = median(valid tau estimates)
%
% DEPENDENCIES:
%   - SM_drydowns2.m must be on the MATLAB path
%   - MATLAB NetCDF functions: ncinfo, ncread, nccreate, ncwrite, ncwriteatt

clear; clc;

%% ---- User settings ----
inFile   = 'swvl1.nc';
varIn    = 'swvl1';

outFile  = 'medianTau.nc';
varOut   = 'medianTau';

%% ---- Read coordinates ----
lat = ncread(inFile, 'lat');
lon = ncread(inFile, 'lon');

%% ---- Read swvl1 and permute to (time, lat, lon) ----
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

medianTau_vec = NaN(1, nPoints);

%% ---- Compute medianTau for each grid cell ----
for p = 1:nPoints
    sm = X2(:, p);

    if all(isnan(sm))
        continue;
    end

    tau_vals = SM_drydowns2(sm);
    validTau = tau_vals(~isnan(tau_vals));

    if ~isempty(validTau)
        medianTau_vec(p) = median(validTau);
    end

    if mod(p, 25) == 0 || p == nPoints
        fprintf('Processed %d / %d grid cells\n', p, nPoints);
    end
end

%% ---- Reshape to (lat, lon) ----
medianTau_map = reshape(medianTau_vec, nLat, nLon);

%% ---- Write output NetCDF ----
if exist(outFile, 'file') == 2
    delete(outFile);
end

nccreate(outFile, 'lat', 'Dimensions', {'lat', nLat}, 'Datatype', 'double');
nccreate(outFile, 'lon', 'Dimensions', {'lon', nLon}, 'Datatype', 'double');

nccreate(outFile, varOut, 'Dimensions', {'lat', nLat, 'lon', nLon}, 'Datatype', 'double');

ncwrite(outFile, 'lat', double(lat));
ncwrite(outFile, 'lon', double(lon));
ncwrite(outFile, varOut, double(medianTau_map));

ncwriteatt(outFile, '/', 'source_file', inFile);
ncwriteatt(outFile, varOut, 'long_name', 'Median Dry-down Time Constant (tau)');
ncwriteatt(outFile, varOut, 'units', 'days');

fprintf('Saved output: %s (variable: %s)\n', outFile, varOut);
%%
