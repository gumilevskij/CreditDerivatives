
%% Computes default and fixed legs of Nth-to-Default Swap
%
%Calculates spread of nth to default swap using procedure mentioned in Appendix of paper
%"Valuation of a CDO and an nth to Default CDS Without Monte Carlo Simulation" by John Hull and Allan White, 2004
%    
% Parameters:
% N - Number of obligors
% R - recovery rate
% c - Coupon rate
% k - seniority level, e.g. 2nd to default swap
% K2 - detachment point
% IR - risk free rate 
% rho - correlation between each pair of entities
% lambda - Default intensity for all firms
% TM - maturity of default swap
% tstep - time step
% method - Hull-White iterative method

function [fixedLeg,defaultLeg,value,spread] = NthToDefault( Notional, R, c, k, IR, rho, lambda, TM, tstep, method)

    n=TM/tstep; %time steps for indexing preminum payments
    SurvivalProbMat=zeros(n+1,1);
    defaultLeg=0; %Expected value of average default leg payments
    fixedLeg=0; %Expected value of average Premium leg payments
    
    t=0;
    for i=1:size(SurvivalProbMat,1)
        SurvivalProbMat(i,2)=integral(@(x)integrand(x,t,k,rho,lambda,method),-10,10);
        t=t+tstep;
    end
    
    for i=2:size(SurvivalProbMat,1),
        t=(i-1)*tstep;
        B=exp(-IR*t);
        defaultProb=max(0,SurvivalProbMat(i-1) - SurvivalProbMat(i));
        defaultLeg=defaultLeg + Notional*(1-R)*B*defaultProb;
        fixedLeg=fixedLeg + c*Notional*tstep*B*SurvivalProbMat(i);
    end

    value = defaultLeg - fixedLeg;
    spread=1.e4*defaultLeg/(fixedLeg/c);
end