%% Cummulative Gaussian Loss Distribution of Large Homogenous Portfolio
%
% Parameters:
% x - fraction of loss 
% rho - correlation parameter
% PD - probability of default

function ret = CDL_LHP( x, rho, PD )
    % Returns cummulative loss distribution
    ret = normcdf((sqrt(1-rho^2)*norminv(x,0,1) - norminv(PD,0,1))/rho);
end

