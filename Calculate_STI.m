%% example_STI_single_location.m
% Example: compute STI for a single-location daily temperature time series.
%
% INPUT FILE:
%   mx2t.mat  (must contain variable "mx2t")
%
% VARIABLE:
%   mx2t : daily temperature time series from 1961–2023 (length = 22995),
%          already in a 365-day calendar (leap days removed).
%          Can be a row or column vector. May include NaNs.
%
% OUTPUT:
%   STI : STI values aligned to mx2t (NaNs preserved)
%   Also saves: STI.mat  (variable name inside is "STI")

clear; clc;

% Load the single-location daily series
S = load('mx2t.mat', 'mx2t');
if ~isfield(S, 'mx2t')
    error('mx2t.mat does not contain variable "mx2t".');
end
mx2t = S.mx2t;

% Ensure column vector for consistent indexing
mx2t = mx2t(:);

% STI parameters
scale = 1;      % daily
nseas = 365;    % DOY bins for a 365-day calendar

% Preserve NaNs: compute STI only on valid values, then reinsert
STI = NaN(size(mx2t));
idxValid = ~isnan(mx2t);

if any(idxValid)
    STI_vals = STI_func(mx2t(idxValid), scale, nseas);  % calls your function below
    STI(idxValid) = STI_vals;
end

% Quick sanity prints
disp('STI computed from mx2t.mat (variable: mx2t).');
disp(['Length(mx2t): ', num2str(length(mx2t))]);
disp(['NaN count   : ', num2str(sum(~idxValid))]);

% Save result
save('STI.mat', 'STI', '-v7.3');

% Optional plot
figure;
plot(STI);
xlabel('Day');
ylabel('STI');
title('STI (single location) from mx2t');
