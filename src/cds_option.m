%{
Pricing a Single-Name CDS Option
This example shows how to price a single-name CDS option using cdsoptprice. The function cdsoptprice is based on the Black's model as described in O'Kane (2008). The optional knockout argument for cdsoptprice supports two variations of the mechanics of a CDS option. CDS options can be knockout or non-knockout options.
•	A knockout option cancels with no payments if there is a credit event before the option expiry date.
•	A non-knockout option does not cancel if there is a credit event before the option expiry date. In this case, the option holder of a non-knockout payer swaption can take delivery of the underlying long protection CDS on the option expiry date and exercise the protection, delivering a defaulted obligation in return for par. This portion of protection from option initiation to option expiry is known as the front-end protection (FEP). While this distinction does not affect the receiver swaption, the price of a non-knockout payer swaption is obtained by adding the value of the FEP to the knockout payer swaption price.
Define the CDS instrument.
%}
Settle = datenum('12-Jun-2012');
OptionMaturity = datenum('20-Sep-2012');
CDSMaturity = datenum('20-Sep-2017');
OptionStrike = 200;
SpreadVolatility = .4;
% Define the zero rate.
Zero_Time = [.5 1 2 3 4 5]';
Zero_Rate = [.5 .75 1.5 1.7 1.9 2.2]'/100;
Zero_Dates = daysadd(Settle,360*Zero_Time,1);
ZeroData = [Zero_Dates Zero_Rate]

% Define the market data.
Market_Time = [1 2 3 5 7 10]';
Market_Rate = [100 120 145 220 245 270]';
Market_Dates = daysadd(Settle,360*Market_Time,1);
MarketData = [Market_Dates Market_Rate];

ProbData = cdsbootstrap(ZeroData, MarketData, Settle)

% Define the CDS option.
[Payer,Receiver] = cdsoptprice(ZeroData, ProbData, Settle, OptionMaturity, ...
    CDSMaturity, OptionStrike, SpreadVolatility, 'Knockout', true);
fprintf('    Payer: %.0f   Receiver: %.0f  (Knockout)\n',Payer,Receiver);
[Payer,Receiver] = cdsoptprice(ZeroData, ProbData, Settle, OptionMaturity, ...
    CDSMaturity, OptionStrike, SpreadVolatility, 'Knockout', false);
fprintf('    Payer: %.0f   Receiver: %.0f  (Non-Knockout)\n',Payer,Receiver);
%{
Pricing a CDS Index Option
This example shows how to price CDS index options by using cdsoptprice with the forward spread adjustment. Unlike a single-name CDS, a CDS portfolio index contains multiple credits. When one or more of the credits default, the corresponding contingent payments are made to the protection buyer but the contract still continues with reduced coupon payments. Considering the fact that the CDS index option does not cancel when some of the underlying credits default before expiry, one might attempt to price CDS index options using the Black's model for non-knockout single-name CDS option. However, Black's model in this form is not appropriate for pricing CDS index options because it does not capture the exercise decision correctly when the strike spread (K) is very high, nor does it ensure put-call parity when (K) is not equal to the contractual spread (O'Kane, 2008). 
However, with the appropriate modifications, Black's model for single-name CDS options used in cdsoptprice can provide a good approximation for CDS index options. While there are some variations in the way the Black's model is modified for CDS index options, they usually involve adjusting the forward spread F, the strike spread K, or both. Here we describe the approach of adjusting the forward spread only. In the Black's model for single-name CDS options, the forward spread F is defined as:
where
S is the spread.
RPV01 is the risky present value of a basis point (see cdsrpv01).
t is the valuation date.
tE is the option expiry date.
T is the CDS maturity date.
To capture the exercise decision correctly for CDS index options, we use the knockout form of the Black's model and adjust the forward spread to incorporate the FEP as follows: 
where the FEP can be expressed as
In cdsoptprice, forward spread adjustment can be made with the AdjustedForwardSpread parameter. When computing the adjusted forward spread, we can compute the spreads using cdsspread and the RPV01s using cdsrpv01. 
Set up the data for the CDS index, its option, and zero curve. The underlying is a 5 year CDS index maturing on 20-Jun-2017 and the option expires on 20-Jun-2012. Note that a flat index spread is assumed when bootstrapping the default probability curve. 
%}
% CDS index and option data
Recovery = .4;
Basis = 2;
Period = 4;
CDSMaturity = datenum('20-Jun-2017');
ContractSpread = 100;
IndexSpread = 140;
BusDayConvention = 'follow';
Settle = datenum('13-Apr-2012');
OptionMaturity = datenum('20-Jun-2012');
OptionStrike = 140;
SpreadVolatility = .69;

% Zero curve data
MM_Time = [1 2 3 6]';
MM_Rate = [0.004111 0.00563 0.00757 0.01053]';
MM_Dates = daysadd(Settle,30*MM_Time,1);
Swap_Time = [1 2 3 4 5 6 7 8 9 10 12 15 20 30]';
Swap_Rate = [0.01387 0.01035 0.01145 0.01318 0.01508 0.01700 0.01868 ...
    0.02012 0.02132 0.02237 0.02408 0.02564 0.02612 0.02524]';
Swap_Dates = daysadd(Settle,360*Swap_Time,1);
ZeroBasis = 1;
ZeroCompounding = 1;

% Bootstrap the default probability curve assuming a flat index spread.
ZeroData = [MM_Dates MM_Rate;Swap_Dates Swap_Rate];
MarketDates = (Settle+1:30:CDSMaturity)';
MarketData = [MarketDates repmat(IndexSpread,length(MarketDates),1)];
ProbData = cdsbootstrap(ZeroData, MarketData, Settle);
% Compute the spot and forward RPV01s, which will be used later in the computation of the FEP and the % adjusted forward spread. For this purpose, we can use cdsrpv01. 
% RPV01(t,T)
RPV01_CDSMaturity = cdsrpv01(ZeroData,ProbData,Settle,CDSMaturity,...
    'CleanRPV01',false) 

% RPV01(t,t_E,T)
RPV01_OptionExpiryForward = cdsrpv01(ZeroData,ProbData,Settle,CDSMaturity,...
    'StartDate',OptionMaturity,'CleanRPV01',false) 

% RPV01(t,t_E) = RPV01(t,T) - RPV01(t,t_E,T)
RPV01_OptionExpiry = RPV01_CDSMaturity - RPV01_OptionExpiryForward  


% Compute the spot spreads using cdsspread.
% S(t,t_E)
Spread_OptionExpiry = cdsspread(ZeroData,ProbData,Settle,OptionMaturity,...
    'Period',Period,'Basis',Basis,'BusDayConvention',BusDayConvention,...
    'PayAccruedPremium',true,'ZeroCompounding',...
    ZeroCompounding,'ZeroBasis',ZeroBasis,'recoveryrate',Recovery) 

% S(t,T)
Spread_CDSMaturity = cdsspread(ZeroData,ProbData,Settle,CDSMaturity,...
    'Period',Period,'Basis',Basis,'BusDayConvention',BusDayConvention,...
    'PayAccruedPremium',true,'ZeroCompounding',...
    ZeroCompounding,'ZeroBasis',ZeroBasis,'recoveryrate',Recovery) 

%  The spot spreads and RPV01s are then used to compute the forward spread. 
% F = S(t,t_E,T)
ForwardSpread = (Spread_CDSMaturity.*RPV01_CDSMaturity - ...
    Spread_OptionExpiry.*RPV01_OptionExpiry)./RPV01_OptionExpiryForward

% Compute the front-end protection (FEP). 
FEP = Spread_OptionExpiry * (cdsrpv01(ZeroData,ProbData,Settle,CDSMaturity)...
    - cdsrpv01(ZeroData,ProbData,Settle,CDSMaturity,'StartDate',OptionMaturity))
% Compute the adjusted forward spread.
AdjustedForwardSpread = ForwardSpread + FEP./RPV01_OptionExpiryForward
%{
Compute the option prices using cdsoptprice with the adjusted forward spread. Note again that the Knockout parameter should be set to be true because the FEP was already incorporated into the adjusted forward spread. 
%}
[Payer,Receiver] = cdsoptprice(ZeroData, ProbData, Settle, OptionMaturity, ...
    CDSMaturity, OptionStrike, SpreadVolatility,'Knockout',true,...
    'AdjustedForwardSpread', AdjustedForwardSpread,'PayAccruedPremium',true);
fprintf('    Payer: %.0f   Receiver: %.0f  \n',Payer,Receiver);

