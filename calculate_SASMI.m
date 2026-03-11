%% run_SASMI_from_nc_fullgrid.m
% Compute SASMI for all grid cells in a NetCDF file using a k_map field.
%
% INPUT FILES (NetCDF):
%   swvl1.nc   : daily soil moisture with dimensions that include (time, lat, lon)
%   k_map.nc   : dry-down constant map with dimensions (lat, lon) and variable "k_map"
%
% REQUIRED VARIABLES:
%   swvl1.nc:
%     swvl1(time, lat, lon) : daily soil moisture (dimension order can be any)
%     time, lat, lon
%   k_map.nc:
%     k_map(lat, lon)
%     lat, lon
%
% OUTPUT FILE (NetCDF):
%   SASMI.nc
%
% VARIABLES IN OUTPUT:
%   SASMI(time, lat, lon) : SASMI for every grid cell
%   time, lat, lon        : copied from swvl1.nc
%
% METHOD:
%   For each grid cell:
%     1) extract soil moisture series D1
%     2) read k_val from k_map at the same (lat, lon)
%     3) compute SASMI using calculate_SASMI_DD(D1, k_val)
%     4) preserve NaNs
%
% REQUIREMENT:
%   SASMI_func.m must be on the MATLAB path.

clear; clc;

%% ---- User settings ----
smFile   = 'swvl1.nc';
smVar    = 'swvl1';

kFile    = 'k_map.nc';
kVar     = 'k_map';

outFile  = 'SASMI.nc';
outVar   = 'SASMI';

%% ---- Read coordinates from soil moisture file ----
time = ncread(smFile, 'time');
lat  = ncread(smFile, 'lat');
lon  = ncread(smFile, 'lon');

nLat = numel(lat);
nLon = numel(lon);

%% ---- Read k_map (lat x lon) ----
k_map = ncread(kFile, kVar);
k_map = squeeze(k_map);

%% ---- Read swvl1 and permute to (time, lat, lon) ----
info = ncinfo(smFile, smVar);
dimNames = {info.Dimensions.Name};

X = ncread(smFile, smVar);

timeDim = find(strcmpi(dimNames, 'time'), 1);
latDim  = find(strcmpi(dimNames, 'lat'), 1);
lonDim  = find(strcmpi(dimNames, 'lon'), 1);

if isempty(timeDim) || isempty(latDim) || isempty(lonDim)
    error('Could not identify time/lat/lon dimensions for variable "%s".', smVar);
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
fprintf('Read %s with size (time,lat,lon) = (%d, %d, %d)\n', smVar, nTime, nLat, nLon);

%% ---- Reshape to (time x nPoints) ----
X2 = reshape(X, nTime, nLat*nLon);
nPoints = size(X2, 2);

SASMI2 = NaN(size(X2));

%% ---- Compute SASMI for each grid cell ----
for p = 1:nPoints
    D1 = X2(:, p);

    if all(isnan(D1))
        continue;
    end

    [lat_idx, lon_idx] = ind2sub([nLat, nLon], p);
    k_val = k_map(lat_idx, lon_idx);

    if ~isnan(k_val) && any(~isnan(D1))
        SASMI2(:, p) = SASMI_func(D1, k_val);
    end

    if mod(p, 25) == 0 || p == nPoints
        fprintf('Processed %d / %d grid cells\n', p, nPoints);
    end
end

%% ---- Reshape back to (time, lat, lon) ----
SASMI3 = reshape(SASMI2, nTime, nLat, nLon);

%% ---- Write output NetCDF ----
if exist(outFile, 'file') == 2
    delete(outFile);
end

nccreate(outFile, 'time', 'Dimensions', {'time', Inf}, 'Datatype', 'double');
nccreate(outFile, 'lat',  'Dimensions', {'lat',  nLat}, 'Datatype', 'double');
nccreate(outFile, 'lon',  'Dimensions', {'lon',  nLon}, 'Datatype', 'double');

nccreate(outFile, outVar, ...
    'Dimensions', {'time', Inf, 'lat', nLat, 'lon', nLon}, ...
    'Datatype', 'double');

ncwrite(outFile, 'time', double(time));
ncwrite(outFile, 'lat',  double(lat));
ncwrite(outFile, 'lon',  double(lon));
ncwrite(outFile, outVar, double(SASMI3));

%% ---- Metadata ----
try
    tinfo = ncinfo(smFile, 'time');
    for a = 1:numel(tinfo.Attributes)
        ncwriteatt(outFile, 'time', tinfo.Attributes(a).Name, tinfo.Attributes(a).Value);
    end
catch
end
ncwriteatt(outFile, 'time', 'calendar', '365_day');

ncwriteatt(outFile, '/', 'source_file_swvl1', smFile);
ncwriteatt(outFile, '/', 'source_file_kmap',  kFile);
ncwriteatt(outFile, '/', 'note', 'SASMI computed grid-wise from swvl1 using k_map and calculate_SASMI_DD(D1,k).');
ncwriteatt(outFile, outVar, 'long_name', 'Standardized Antecedent Soil Moisture Index (SASMI)');

fprintf('Saved output: %s (variable: %s)\n', outFile, outVar);