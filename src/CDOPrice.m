%% Computes CDO tranche price with the aid of Monte Carlo simulaions
%
%   Parameters:
%   upfront - Upfront premium
%   n -     Notional
%   N -     Portfolio size
%   R -     Recovery rate
%   c -     Coupon Rate
%   IR -    Risk-free interest rate
%   rho -   Corellation coefficient
%   lambda - Coefficient for hazard rate in Poisson equation
%   a -     Attachment point
%   d -     Detachment point
%   No -    Number of Monte Carlo paths
%   TM -    Maturity
%   tstep - Time step

function [fixedLegVal,floatLegVal,Value,spread,fixedLegErr,floatingLegErr]  = ...
                                    CDOPrice( upfront,n,N,R,c,IR,rho,lambda,a,d,No,TM,tstep )
                                
    nn  = n * N;                 % the total notional
    loss = n * ( 1 - R);         % the total loss
    T=0:tstep:TM;                % vector for the fixed coupon dates
    Tmod=repmat(T,N,1);          % matrix of fixed coupon dates for all N companies
    discount=exp(-IR*T(2:end));  % discounted factor
    randn('state',0);            % just to initialize the generator
    MRho = repmat(rho^2,N,N);    % initializing the correlation matrix
    for i=1:N
        MRho(i,i) = 1;           % filling diagonal entries with 1
    end
    MRho = chol(MRho)';          % doing the Cholesky factorization
    fixedtot = 0;                % initializing for fixed leg total
    floattot = 0;                % initializing for floating leg total
    sqfixtot = 0;                % for standard error estimate
    sqfltot  = 0;                % for standard error estimate
    PMat = randn(N, No);         % initialzing the Gaussian matrix
    PMat1 = MRho * PMat;         % to get the correlated Gaussian matrix
    PMat11 = normcdf(PMat1,0,1); % take the CDF to make them a copula
    PMat2 = -log(1 - PMat11)/ lambda;    % inverse function to get the default time
    for i=1:No                            % loop for different paths of MC
        PMat3=PMat2(:,i);                 % getting the i'th path
        Pmatmod=repmat(PMat3,1,TM/tstep+1);   % getting it for the fixed coupon dates
        Temp1= Pmatmod<Tmod;              % keeping default times that are only within the CDS maturity
        Lmat = loss*Temp1;                % getting the losses matrix by multiplying with the defaults                    
        Tloss= sum(Lmat);                 % summing up the losses
        Ploss= Tloss/nn;                  % getting the loss percentages
        Plossum =max(Ploss-a,0)-max(Ploss-d,0);    % getting the loss percentage in the tranche
        tempplos =Plossum(2:end)-Plossum(1:end-1); % 
        temp2 =nn * tempplos;
        temp =nn*(d-a-Plossum);                          % getting the notional left in the tranche       
        coupon = c*tstep*(temp(1:end-1)+ temp(2:end))/2; % getting the fixed coupons
        fl_flows=discount.*temp2;                        % getting the discounted floating flows
        fx_flows=discount.*coupon;                       % getting the discounted fixed flows
        Vfloat=sum(fl_flows);                            % the total floating flows for this path
        floattot = floattot + Vfloat;                    % the total floating flows until now
        sqfltot  = sqfltot  + (Vfloat^2);                % to get the standard error square term
        Vfixed=sum(fx_flows);                            % the total fixed flows for this path
        fixedtot = fixedtot + Vfixed;                    % the total fixed flows until now
        sqfixtot = sqfixtot + (Vfixed^2);                % to get the standard error square term
    end
   fixedLegVal = fixedtot/No;
   floatLegVal = floattot/No;
   Value = (floattot - fixedtot)/No - nn*(d-a)*upfront;
   %Standard errors
   fixedLegErr =  ((1/No) * sqrt(sqfixtot - ((1/No) * (fixedtot^2))))/fixedLegVal;
   floatingLegErr = ((1/No) * sqrt(sqfltot - ((1/No) * (floattot^2))))/floatLegVal;
   % Breakeaven Spread
   spread = 1.e4*(floattot-nn*(d-a)*upfront)/(fixedtot/c);
end