%% example_STI_single_location_dummydata
% Example: compute STI for a single-location daily temperature time series
% using dummy (synthetic) data in Celsius.
%
% Assumptions:
% - 1961–2023 inclusive = 63 years
% - Each year has 365 days (leap days removed)
% - Temperature units are Celsius
%
% OUTPUT:
%   STI : STI values (same length as dummy mx2t)

clear; clc;

% ---- Dummy daily temperature data (Celsius), 1961–2023 (63 years) ----
nseas  = 365;                 % DOY bins
nYears = 63;                  % 1961–2023 inclusive
N      = nYears * nseas;      % 63*365 = 22995
t      = (1:N)';

% Dummy "mx2t" in Celsius: seasonal cycle + random noise
% (This is only for demonstrating how to run the STI routine.)
mx2t = 20 + 10*sin(2*pi*(mod(t-1,nseas)+1)/nseas) + randn(N,1);

% Optional: add a few NaNs to demonstrate missing-data handling
mx2t(100:110) = NaN;

% ---- STI parameters ----
scale = 1;      % daily
nseas = 365;    % DOY bins for a 365-day calendar

% ---- Compute STI while preserving NaNs ----
STI = NaN(size(mx2t));
idxValid = ~isnan(mx2t);

if any(idxValid)
    STI_vals = STI_func(mx2t(idxValid), scale, nseas);  % calls your function below
    STI(idxValid) = STI_vals;
end

% ---- Quick sanity prints ----
disp('STI computed from dummy daily temperature (Celsius) time series.');
disp(['Length(mx2t): ', num2str(length(mx2t)), ' (should be 22995)']);
disp(['NaN count   : ', num2str(sum(~idxValid))]);

% ---- Optional plot ----
figure;
plot(STI);
xlabel('Day');
ylabel('STI');
title('STI (single location) from dummy daily temperature (°C)');
