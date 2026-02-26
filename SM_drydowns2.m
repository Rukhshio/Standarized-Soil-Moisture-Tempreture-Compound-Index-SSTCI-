function tau_hat = SM_drydowns2(soilMoisture1)
    % Remove NaNs from the time series
    I = ~isnan(soilMoisture1);
    soilMoisture = soilMoisture1(I);

    sm_wp1 = min(soilMoisture); % Effective wilting point
    minObservations = 4; % Minimum number of observations for a valid drydown
    minPositiveIncrement = 2 * 0.02; % Minimum preceding positive increment for drydown
    minSlopeThreshold = 0.005; % Minimum change rate threshold to end drydown

    % Initialize variables
    tau_hat = []; % Array to store tau_hat values
    isDecreasing = false;

    % Loop through the time series to identify drydowns
    for i = 2:length(soilMoisture)
        % Check for decreasing soil moisture (drydown)
        if soilMoisture(i) < soilMoisture(i-1)
            if ~isDecreasing
                % Drydown starts here
                drydownStartIndex = i-1;
                isDecreasing = true;
            end
        else
            % Only end drydown if the increase exceeds the slope threshold
            if isDecreasing && (soilMoisture(i) - soilMoisture(i-1) >= minSlopeThreshold)
                drydownEndIndex = i - 1;
                drydownData = soilMoisture(drydownStartIndex:drydownEndIndex);

                % Check if the drydown period has enough observations
                if length(drydownData) >= minObservations
                    % Check the preceding positive increment
                    if drydownStartIndex > 1
                        positiveIncrement = soilMoisture(drydownStartIndex) - soilMoisture(drydownStartIndex - 1);

                        % Only proceed if the positive increment meets the minimum criterion
                        if positiveIncrement >= minPositiveIncrement
                            % Determine Δsm and fit the exponential model
                            sm_initial = soilMoisture(drydownStartIndex);
                            delta_sm = sm_initial - sm_wp1;

                            % Time vector for drydown (relative days)
                            t = (0:length(drydownData)-1)';

                            % Define the exponential model
                            expModel = @(tau) delta_sm * exp(-t/tau) + sm_wp1;

                            % Define the residuals (difference between model and data)
                            residuals = @(tau) norm(expModel(tau) - drydownData);

                            % Minimize the residuals to solve for tau_hat
                            options = optimset('Display','off');
                            tau_hat_est = fminsearch(residuals, 1, options); % Initial guess for tau = 1

                            % Store the tau_hat value in the array
                            tau_hat = [tau_hat; tau_hat_est];
                        end
                    end
                end
                isDecreasing = false; % Reset drydown flag
            end
        end
    end

    % % Output a message if no valid drydowns were found
    % if isempty(tau_hat)
    %     fprintf('No valid drydowns found in the time series.\n');
    % else
    %     fprintf('Found %d valid drydowns.\n', length(tau_hat));
    %     disp('Tau_hat values for each drydown:');
    %     disp(tau_hat);
    % end
end
