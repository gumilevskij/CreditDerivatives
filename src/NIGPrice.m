%% Computes expected loss of CDO tranche with Normal-Inverse Gaussian Copula
%
%   upfront - Upfront premium
%   Notional - Notional
%   R -     Recovery rate
%   c -     Coupon Rate
%   IR -    Risk-free interest rate
%   cor -   Corellation coefficient
%   lambda - Coefficient for hazard rate in Poisson equation
%   K1 -    Attachment point
%   K2 -    Detachment point
%   Mat -   Maturity
%   tstep - Time step
%   alpha - Tail heavyness in NIG distribution
%   beta -  Asymmetry parameter in NIG distribution
%   mu -    Location parameter in NIG distribution
%   delta - Scale parameter in NIG distribution

function [fixedLegVal,floatLegVal,Value,spread] = ...
    NIGPrice( upfront, Notional, R, c, IR, a, lambda, K1, K2, Mat, tstep, alpha, beta, mu, delta )

    s=sqrt(1-a^2)/a;
    % Calculate the discount factor & Default threshold
    N = Mat/tstep;
    DefProb = zeros(N,1);DiscFact=ones(1+N,1);intFtK1=zeros(N,1);EL=zeros(1+N,1);
    for i=1:N
        t = i*tstep;
        DefProb(i) = 1 -exp(-lambda*t);
        DiscFact(i+1)=exp(-IR*t);
    end
    C_NIG=niginv(DefProb,alpha/a,beta/a,-(1/a)*mu,(1/a)*delta);
    % Determine the expected loss EL(t)
    bounds=niginv([K1; K2]/(1-R),s*alpha,s*beta,-s*mu,s*delta);
    lowerbound=max(-10,bounds(1));
    upperbound=min(10,bounds(2));
    FtK2=1-nigcdf((C_NIG-sqrt(1-a^2)*upperbound)/a,alpha,beta,-mu,delta);
    for i=1:N
        intFtK1(i)=integral(@(x)intfunc(x,K1,R,C_NIG(i),a,alpha,beta,mu,delta),lowerbound,upperbound);
        EL(i+1)=((1-R)/(K2-K1))*intFtK1(i)+(1-FtK2(i));
    end
    % Protection Leg
    floatLegVal=Notional*sum(diff(EL).*DiscFact(2:end));
    % Premium Leg
    fixedLegVal=Notional*c*sum((1-EL(2:end)).*DiscFact(2:end)*tstep);
    Value = floatLegVal-fixedLegVal-Notional*(K2-K1)*upfront;
    % Breakeaven Spread
    spread=1.e4*(floatLegVal-Notional*(K2-K1)*upfront)/(fixedLegVal/c);

end

