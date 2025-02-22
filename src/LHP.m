%% Computes expected loss of Large Homogeneous Portfolio with the aid of Gaussian Copula
%
%   Parameters:
%   R -     Recovery rate
%   cor -   Corellation coefficient
%   lambda- Coefficient for hazard rate in Poisson equation
%   A -     Attachment point
%   D -     Detachment point
%   t -     Time

function EL = LHP( R, cor, lambda, A, D, t)

    %Probabilty of default
    p = 1 - exp(-lambda*t);
    C = norminv(p,0,1);
    a1 = -norminv(min(1,A/(1-R)),0,1);
    a2 = -norminv(min(1,D/(1-R)),0,1);
    mu = [0; 0];
    sigma = [1 -sqrt(1-cor^2); -sqrt(1-cor^2) 1];
    x = [a1; C];
    f1 = mvncdf(x, mu, sigma);
    x = [a2; C];
    f2 = mvncdf(x, mu, sigma);
    EL = (1-R)*(f1-f2)/(D-A);
end

