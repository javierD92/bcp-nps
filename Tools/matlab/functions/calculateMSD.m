function [msd, tau] = calculateMSD(x, y, t)
% calculateMSD Calculates the Mean Squared Displacement for 2D trajectories
%
% Inputs:
%   x, y - Vectors of coordinates
%   t    - Vector of time stamps
%
% Outputs:
%   msd  - Calculated Mean Squared Displacement
%   tau  - Elapsed time (time lags)

N = length(x);
dt = t(2) - t(1); % Assumes constant time steps
msd = zeros(N-1, 1);
tau = (1:N-1)' * dt;

for p = 1:N-1
    % Calculate squared displacements for a lag of 'p' steps
    dx = x(1+p:end) - x(1:end-p);
    dy = y(1+p:end) - y(1:end-p);
    
    % Average the squared distances for this specific lag
    msd(p) = mean(dx.^2 + dy.^2);
end
end