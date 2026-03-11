%% tau_to_k_map_from_nc.m
% Convert a median dry-down time constant map (medianTau) into a dry-down constant map (k),
% after clamping tau to a maximum value, then save outputs to NetCDF.
%
% INPUT FILE (NetCDF):
%   medianTau.nc
%
% REQUIRED VARIABLES IN INPUT:
%   medianTau(lat, lon) : median dry-down time constant (tau) in days
%   lat                 : latitude vector
%   lon                 : longitude vector
%
% OUTPUT FILE (NetCDF):
%   k_map.nc
%
% VARIABLES IN OUTPUT:
%   k_map(lat, lon)       : dry-down constant (daily retention), k = exp(-1/tau_clamped)
%   tau_clamped(lat, lon) : tau after clamping (days)
%   lat, lon              : copied from input file
%
% METHOD:
%   1) Clamp tau at tau_max (default 20 days).
%   2) Compute k = exp(-1 ./ tau_clamped).
%   3) Preserve NaNs (mask) throughout.

clear; clc;

%% ---- User settings ----
inFile   = 'medianTau.nc';
tauVar   = 'medianTau';

outFile  = 'k_map.nc';
tau_max  = 20;

%% ---- Read inputs ----
lat = ncread(inFile, 'lat');
lon = ncread(inFile, 'lon');
tau = ncread(inFile, tauVar);   % expected shape: (lat, lon)

% Ensure tau is 2-D (lat x lon)
tau = squeeze(tau);

%% ---- Clamp tau ----
tau_clamped = tau;
tau_clamped(tau_clamped > tau_max) = tau_max;

%% ---- Compute k = exp(-1/tau) ----
k_map = exp(-1 ./ tau_clamped);
k_map(isnan(tau_clamped)) = NaN;

%% ---- Write output NetCDF ----
if exist(outFile, 'file') == 2
    delete(outFile);
end

nLat = numel(lat);
nLon = numel(lon);

nccreate(outFile, 'lat', 'Dimensions', {'lat', nLat}, 'Datatype', 'double');
nccreate(outFile, 'lon', 'Dimensions', {'lon', nLon}, 'Datatype', 'double');

nccreate(outFile, 'tau_clamped', 'Dimensions', {'lat', nLat, 'lon', nLon}, 'Datatype', 'double');
nccreate(outFile, 'k_map',       'Dimensions', {'lat', nLat, 'lon', nLon}, 'Datatype', 'double');

ncwrite(outFile, 'lat', double(lat));
ncwrite(outFile, 'lon', double(lon));
ncwrite(outFile, 'tau_clamped', double(tau_clamped));
ncwrite(outFile, 'k_map',       double(k_map));

%% ---- Metadata ----
ncwriteatt(outFile, '/', 'source_file', inFile);
ncwriteatt(outFile, '/', 'tau_clamp_max_days', double(tau_max));

ncwriteatt(outFile, 'tau_clamped', 'long_name', 'Clamped Median Dry-down Time Constant (tau)');
ncwriteatt(outFile, 'tau_clamped', 'units', 'days');

ncwriteatt(outFile, 'k_map', 'long_name', 'Dry-down Constant');
ncwriteatt(outFile, 'k_map', 'description', 'k = exp(-1/tau_clamped)');

fprintf('Saved k map to: %s\n', outFile);