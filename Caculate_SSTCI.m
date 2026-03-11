%% run_SSTCI_from_nc_fullgrid.m
% Compute SSTCI for all grid cells from STI and SASMI NetCDF files.
%
% INPUT FILES (NetCDF):
%   STI.nc    : contains STI(time, lat, lon) and coordinates time, lat, lon
%   SASMI.nc  : contains SASMI(time, lat, lon) and coordinates time, lat, lon
%
% OUTPUT FILE (NetCDF):
%   SSTCI.nc
%
% VARIABLES IN OUTPUT:
%   SSTCI(time, lat, lon) : SSTCI for every grid cell
%   time, lat, lon        : copied from input files
%
% METHOD:
%   For each grid cell:
%     1) Extract STI and SASMI series
%     2) Use values from day 14 onward (first 13 days set to NaN)
%     3) ECDF -> U,V (uniform variates)
%     4) Fit Frank copula (theta) and compute copula CDF (C)
%     5) Compute P = V - C, then ECDF(P) -> F
%     6) SSTCI = norminv(F), with 13-day padding at the start
%
% REQUIREMENTS:
%   - Statistics and Machine Learning Toolbox (ecdf, copulafit, copulacdf, norminv)
%   - Input series use a 365-day calendar (leap days removed)

clear; clc;

%% ---- User settings ----
stiFile  = 'STI.nc';
stiVar   = 'STI';

sasmiFile = 'SASMI.nc';
sasmiVar  = 'SASMI';

outFile  = 'SSTCI.nc';
outVar   = 'SSTCI';

%% ---- Read coordinates (from STI file) ----
time = ncread(stiFile, 'time');
lat  = ncread(stiFile, 'lat');
lon  = ncread(stiFile, 'lon');

nTime = numel(time);
nLat  = numel(lat);
nLon  = numel(lon);

%% ---- Read STI and permute to (time, lat, lon) ----
X = read_and_permute_to_tll(stiFile, stiVar);

%% ---- Read SASMI and permute to (time, lat, lon) ----
Y = read_and_permute_to_tll(sasmiFile, sasmiVar);

% Ensure arrays are (time, lat, lon)
X = squeeze(X);
Y = squeeze(Y);

if size(X,1) ~= nTime || size(Y,1) ~= nTime
    error('Time dimension mismatch between variables and time coordinate.');
end
if size(X,2) ~= nLat || size(X,3) ~= nLon || size(Y,2) ~= nLat || size(Y,3) ~= nLon
    error('Spatial dimension mismatch between STI/SASMI and lat/lon coordinates.');
end

fprintf('Read STI and SASMI with size (time,lat,lon) = (%d, %d, %d)\n', nTime, nLat, nLon);

%% ---- Reshape to (time x nPoints) ----
X2 = reshape(X, nTime, nLat*nLon);
Y2 = reshape(real(Y), nTime, nLat*nLon);

SSTCI2 = NaN(size(X2));

%% ---- Optional process log ----
logFile = 'process_log_SSTCI.txt';
logFID  = fopen(logFile, 'w');
fprintf(logFID, '=== SSTCI Processing Log ===\nStarted: %s\n\n', datestr(now));

%% ---- Grid-wise SSTCI ----
nPoints = size(X2, 2);

for p = 1:nPoints
    X_col_full = X2(:, p);
    Y_col_full = Y2(:, p);

    % Use day 14 onward (first 13 days are NaN)
    if nTime < 14
        continue;
    end
    X_col = X_col_full(14:end);
    Y_col = Y_col_full(14:end);

    % Skip if NaN exists or constant series
    if any(isnan(X_col)) || any(isnan(Y_col)) || std(X_col) == 0 || std(Y_col) == 0
        fprintf(logFID, '%s WARNING: Skipping point %d (NaN or constant values)\n', datestr(now), p);
        continue;
    end

    % Interpolate Inf in X_col (internal points only)
    inf_idx = find(isinf(X_col));
    for k = inf_idx'
        if k > 1 && k < length(X_col)
            X_col(k) = (X_col(k-1) + X_col(k+1)) / 2;
        end
    end

    % ECDF -> uniform variates U,V
    try
        [fx, Xs] = ecdf(X_col);
        [fy, Ys] = ecdf(Y_col);

        U = spline(Xs(2:end), fx(2:end), X_col);
        V = spline(Ys(2:end), fy(2:end), Y_col);

        U = max(min(U, 0.99999999), 1e-8);
        V = max(min(V, 0.99999999), 1e-8);

        % Fit Frank copula
        theta = copulafit('Frank', [U(:), V(:)]);

        % Copula CDF and transform
        C = copulacdf('Frank', [U(:), V(:)], theta);
        P = V - C;

        [fp_ecdf, Ps] = ecdf(P);
        F = spline(Ps(2:end), fp_ecdf(2:end), P);
        F(F >= 1) = 0.99999999;

        % Store with 13-day padding
        SSTCI2(:, p) = [nan(13,1); norminv(F)];

    catch ME
        fprintf(logFID, '%s ERROR: Point %d failed (%s)\n', datestr(now), p, ME.message);
        continue;
    end

    if mod(p, 25) == 0 || p == nPoints
        fprintf('Processed %d / %d grid cells\n', p, nPoints);
    end
end

%% ---- Patch remaining ±Inf (same logic as original) ----
SSTCI3 = reshape(SSTCI2, nTime, nLat, nLon);

[rInf, cInf, zInf] = ind2sub(size(SSTCI3), find(isinf(SSTCI3)));
for k = 1:numel(rInf)
    r = rInf(k); a = cInf(k); b = zInf(k);
    if r > 2 && r < size(SSTCI3,1) - 2
        nbr = SSTCI3(r-2:r+2, a, b);
        nbr = nbr(~isinf(nbr));
        if ~isempty(nbr)
            SSTCI3(r, a, b) = (SSTCI3(r, a, b) == inf)  * max(nbr) + ...
                              (SSTCI3(r, a, b) == -inf) * min(nbr);
        end
    end
end

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
ncwrite(outFile, outVar, double(SSTCI3));

% Time attributes + 365-day calendar note
try
    tinfo = ncinfo(stiFile, 'time');
    for a = 1:numel(tinfo.Attributes)
        ncwriteatt(outFile, 'time', tinfo.Attributes(a).Name, tinfo.Attributes(a).Value);
    end
catch
end
ncwriteatt(outFile, 'time', 'calendar', '365_day');

% Basic metadata
ncwriteatt(outFile, '/', 'source_STI', stiFile);
ncwriteatt(outFile, '/', 'source_SASMI', sasmiFile);
ncwriteatt(outFile, '/', 'note', 'SSTCI computed grid-wise using Frank copula and ECDF-based transforms; first 13 days are NaN.');
ncwriteatt(outFile, outVar, 'long_name', 'Standardized Soil Moisture–Temperature Compound Index (SSTCI)');

fprintf('Saved output: %s (variable: %s)\n', outFile, outVar);

fprintf(logFID, '\nCompleted: %s\n', datestr(now));
fclose(logFID);

%% ===== Helper function: read variable and permute to (time,lat,lon) =====
function X = read_and_permute_to_tll(ncfile, varname)
    info = ncinfo(ncfile, varname);
    dimNames = {info.Dimensions.Name};

    X = ncread(ncfile, varname);

    timeDim = find(strcmpi(dimNames, 'time'), 1);
    latDim  = find(strcmpi(dimNames, 'lat'), 1);
    lonDim  = find(strcmpi(dimNames, 'lon'), 1);

    if isempty(timeDim) || isempty(latDim) || isempty(lonDim)
        error('Could not identify time/lat/lon dimensions for variable "%s" in %s.', varname, ncfile);
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
end