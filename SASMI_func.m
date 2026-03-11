function sasmi = SASMI_func(D1, k)
% calculate_SASMI_DD  Compute the Standardized Antecedent Soil Moisture Index (SASMI)
%
% INPUT:
%   D1 : daily soil moisture time series for one grid cell (vector, length n)
%        365-day calendar is assumed (leap days removed).
%   k  : dry-down (decay/retention) constant for the grid cell (scalar, 0<k<1)
%
% OUTPUT:
%   sasmi : SASMI time series (vector, length n)
%
% METHOD OVERVIEW:
%   1) Compute a weighted antecedent soil moisture signal using a 14-day memory window:
%        antecedent(t) = sum_{j=1..14} k^(j-1) * D1(t+14-j)
%      (NaNs in D1 are skipped during accumulation)
%   2) Stratify antecedent values by day-of-year (DOY = 1..365), using values from the
%      same DOY across years.
%   3) For each DOY bin, estimate distribution parameters (alpha, beta, gamma_) and
%      map the empirical signal into standard normal space using an approximation to
%      the inverse normal CDF.
%   4) Align standardized values back to the original daily timeline:
%      output is NaN for the first 13 days, and SASMI(Ndays:end) contains results.
%
% NOTES:
%   - Ndays is fixed at 14 (memory window).
%   - DOY stratification uses 365-day indexing (doy:365:end).
%   - The function assumes sufficient sample size per DOY (n_vals >= 10).

    % Parameters for standard normal transformation (A&S approximation)
    c = [2.515517, 0.802853, 0.010328];
    d = [1.432788, 0.189269, 0.001308];

    Ndays = 14;        % Memory window (days)
    n     = length(D1);

    % === Step 1: Compute weighted antecedent moisture ===
    antecedent = zeros(n - Ndays + 1, 1);
    for in = 1:(n - Ndays + 1)
        for jn = 1:Ndays
            val = D1(in + Ndays - jn);
            if ~isnan(val)
                antecedent(in) = antecedent(in) + k^(jn - 1) * val;
            end
        end
    end

    % === Step 2: Stratify by day-of-year (DOY) and standardize ===
    standardized = nan(size(antecedent));
    for doy = 1:365
        series = [];

        for idx = doy:365:(n - Ndays + 1)
            series(end+1) = antecedent(idx);  %#ok<AGROW>
        end

        series = sort(series);
        n_vals = numel(series);
        if n_vals < 10
            continue  % Skip if too few values
        end

        Fi = ((1:n_vals) - 0.35) ./ n_vals;

        % === Step 3: Estimate distribution parameters ===
        for m = 0:2
            w(m + 1) = mean((1 - Fi).^m .* series);
        end

        beta  = (2 * w(2) - w(1)) / (6 * w(2) - w(1) - 6 * w(3));
        alpha = ((w(1) - 2 * w(2)) * beta) / ...
                (gamma(1 + 1/beta) * gamma(1 - 1/beta));
        gamma_ = w(1) - alpha * gamma(1 + 1/beta) * gamma(1 - 1/beta);

        % === Step 4: Normalize to standard normal space ===
        for i3 = doy:365:(n - Ndays + 1)
            value = antecedent(i3);
            F = (1 + (alpha / (value - gamma_))^beta)^(-1);
            P = 1 - F;

            if P <= 0.5
                b = sqrt(-2 * log(P));
                standardized(i3) = b - ((c(1) + c(2)*b + c(3)*b^2) / ...
                                         (1 + d(1)*b + d(2)*b^2 + d(3)*b^3));
            else
                P = 1 - P;
                b = sqrt(-2 * log(P));
                standardized(i3) = - (b - ((c(1) + c(2)*b + c(3)*b^2) / ...
                                           (1 + d(1)*b + d(2)*b^2 + d(3)*b^3)));
            end
        end
    end

    % === Step 5: Re-align to original time length ===
    sasmi = nan(n, 1);
    sasmi(Ndays:end) = standardized;
end