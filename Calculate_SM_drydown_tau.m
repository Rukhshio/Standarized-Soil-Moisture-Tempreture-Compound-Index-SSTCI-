%% example_medianTau_single_location_dummydata.m
% Example: compute the median soil-moisture dry-down time constant (medianTau)
% for a single location using dummy (synthetic) daily soil moisture data.
%
% Why this example exists:
% - In the full workflow, this exact calculation is repeated for every location
%   globally (processed efficiently in latitude slices). For each location, we
%   estimate tau values from the daily soil-moisture time series using
%   SM_drydowns2, then store the median tau.
% - The set of medianTau values over all locations forms the global median-tau
%   dataset used later as the spatially varying soil-moisture memory field in
%   SASMI/SSTCI processing.
%
% Assumptions (matching your dataset setup):
% - 1961–2023 inclusive = 63 years
% - Each year has 365 days (leap days removed)
%
% OUTPUT:
%   medianTau : a single scalar value (median of tau estimates for this location)
%
% NOTE:
%   Requires SM_drydowns2.m to be on the MATLAB path.

clear; clc;

% ---- Dummy daily soil moisture for one location (1961–2023) ----
nYears = 63;
nseas  = 365;
N      = nYears * nseas;     % 22995
t      = (1:N)';

% Dummy soil moisture (volumetric units typical, but this is just a demo)
% Add a weak seasonal pattern + noise
swvl1 = 0.25 + 0.03*sin(2*pi*(mod(t-1,nseas)+1)/nseas) + 0.01*randn(N,1);

% Optional: add some NaNs to mimic missing days
swvl1(100:110) = NaN;

% ---- Compute tau values and take the median (same workflow as global run) ----
tau_vals = SM_drydowns2(swvl1);

validTau = tau_vals(~isnan(tau_vals));
if isempty(validTau)
    medianTau = NaN;
    warning('No valid tau values returned by SM_drydowns2 for this time series.');
else
    medianTau = median(validTau);
end

disp('medianTau (single location) computed:');
disp(medianTau);

% Optional save
save('medianTau_single_location.mat', 'medianTau', '-v7.3');