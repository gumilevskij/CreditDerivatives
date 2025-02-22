%% Computes expected loss of CDO tranche with Gaussian Copula
%
%  Parameters:
%   upfront - Upfront premium
%   N -     Notional
%   R -     Recovery rate
%   c -     Coupon Rate
%   IR -    Risk-free interest rate
%   cor -   Corellation coefficient
%   lambda - Coefficient for hazard rate in Poisson equation
%   K1 -    Attachment point
%   K2 -    Detachment point
%   Mat -   Maturity
%   tstep - Time step

function [fixedLegVal,floatLegVal,Value,spread] = ...
    LHPPrice( upfront, N, R, c, IR, cor, lambda, A, D, TM, tstep )

    M = TM/tstep;
    fixedLegVal = 0;
    floatLegVal = 0;
    prevEL = 0;
    for i = 0:M
        t = i*tstep;
        disc = exp(-IR*t);
        EL = LHP( R, cor, lambda, A, D, t);
        fixedLegVal = fixedLegVal + c*N*tstep*disc*(1-EL);
        floatLegVal = floatLegVal + N*(EL-prevEL)*disc;
        prevEL = EL;
    end
    Value = floatLegVal - fixedLegVal - N*(D-A)*upfront;
    % Breakeaven Spread
    spread = 1.e4*(floatLegVal-N*(D-A)*upfront) / (fixedLegVal/c);
end

