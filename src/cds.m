
%% Credit Derivative Swap

Settle = '17-Jul-2009'; % valuation date for the CDS
MarketDates = datenum({'20-Sep-10','20-Sep-11','20-Sep-12','20-Sep-14','20-Sep-16'});
MarketSpreads = [140 175 210 265 310]';
MarketData = [MarketDates MarketSpreads];
ZeroDates = datenum({'17-Jan-10','17-Jul-10','17-Jul-11','17-Jul-12','17-Jul-13','17-Jul-14'});
ZeroRates = [1.35 1.43 1.9 2.47 2.936 3.311]'/100;
ZeroData = [ZeroDates ZeroRates];

[ProbData,HazData] = cdsbootstrap(ZeroData,MarketData,Settle);
% The bootstrapped default probability curve is plotted against time, in years, from the valuation date.
ProbTimes = yearfrac(Settle,ProbData(:,1));

scrsz = get(groot,'ScreenSize');
figure('Position',[scrsz(4)/16 scrsz(4)/8 7*scrsz(3)/8 scrsz(4)/2]);
subplot(1,3,1)
plot(MarketDates, MarketSpreads, 'o')
grid on
%Set Ticks
labels = datestr(MarketDates, 12);
set(gca, 'XTick', MarketDates);
set(gca, 'XTickLabel', labels);
xlabel('Date')
ylabel('Spread (bp)')
title('Market Spread')
subplot(1,3,2)
plot([0; ProbTimes],[0; ProbData(:,2)])
grid on
axis([0 ProbTimes(end,1) 0 ProbData(end,2)])
xlabel('Time (years)')
ylabel('Cumulative Default Probability')
title('Bootstrapped Default Probability Curve')

% The following plot displays the bootstrapped hazard rates, plotted against time, in years, from the valuation %date
HazTimes = yearfrac(Settle,HazData(:,1));
subplot(1,3,3)
stairs([0; HazTimes(1:end-1,1); HazTimes(end,1)+1],...
[HazData(:,2);HazData(end,2)])
grid on
axis([0 HazTimes(end,1)+1 0.9*HazData(1,2) 1.1*HazData(end,2)])
xlabel('Time (years)')
ylabel('Hazard Rate')
title('Bootstrapped Hazard Rates')

%% Breakeven spread
% Finding Breakeven Spread for New CDS Contract
Settle = '17-Jul-2009';  % valuation date for the CDS
[ProbData,HazData] = cdsbootstrap(ZeroData,MarketData,Settle);
Maturity1 = datestr(daysadd('17-Jul-09',360*(3.25:0.25:5),1));
Spread1 = cdsspread(ZeroData,ProbData,Settle,Maturity1,'RecoveryRate',0.4);

figure('Position',[scrsz(4)/4 scrsz(4)/4 scrsz(3)/2 scrsz(4)/2]);
subplot(1,2,1)
scatter(yearfrac(Settle,Maturity1),Spread1,'*')
hold on
scatter(yearfrac(Settle,MarketData(3:4,1)),MarketData(3:4,2))
hold off
grid on
xlabel('Time (years)')
ylabel('Spread (bp)')
title('CDS Spreads')
legend('New Quotes','Market','location','SouthEast')

%This plot displays the resulting spreads:
Spread1Rec35 = cdsspread(ZeroData,ProbData,Settle,Maturity1,'RecoveryRate',0.35);

subplot(1,2,2)
plot(yearfrac(Settle,Maturity1),Spread1,...
yearfrac(Settle,Maturity1),Spread1Rec35,'--')
grid on
xlabel('Time (years)')
ylabel('Spread (bp)')
title('CDS Spreads with Different Recovery Rates')
legend('40%','35%','location','SouthEast')
%The resulting plot shows that smaller recovery rates produce higher premia, as expected, since in the event of %default, the protection payments will be higher:

%%Valuing an Existing CDS Contract
Maturity2 = '20-Sep-2012';
Spread2 = 196;
[ProbData,HazData] = cdsbootstrap(ZeroData,MarketData,Settle);
[Price,AccPrem,PaymentDates,PaymentTimes,PaymentCF] = cdsprice(ZeroData,ProbData,Settle,Maturity2,Spread2);
 
fprintf('Dirty Price: %8.2f\n',Price);
fprintf('Accrued Premium: %8.2f\n',AccPrem);
fprintf('Clean Price: %8.2f\n',Price-AccPrem);
fprintf('\nPayment Schedule:\n\n');
fprintf('Date \t\t Time Frac \t Amount\n');
for k = 1:length(PaymentDates)
   fprintf('%s \t %5.4f \t %8.2f\n',datestr(PaymentDates(k)),...
      PaymentTimes(k),PaymentCF(k));
end

%In the following example, a simple hedged position with two vanilla CDS contracts, one long, one short, with slightly different spreads is priced in a single call and the value of the portfolio is the sum of the returned prices
 [Price2,AccPrem2] = cdsprice(ZeroData,ProbData,Settle,repmat(datenum(Maturity2),2,1),[Spread2;Spread2+3],'Notional',[1e7; -1e7]);

fprintf('Contract \t Dirty Price \t Acc Premium \t  Clean Price\n');
fprintf('    Long \t $ %9.2f \t $ %9.2f \t $ %9.2f \t\n',...
   Price2(1), AccPrem2(1), Price2(1) - AccPrem2(1));
fprintf('   Short \t $ %8.2f \t $ %8.2f \t $ %8.2f \t\n',...
   Price2(2), AccPrem2(2), Price2(2) - AccPrem2(2));
fprintf('Mark-to-market of hedged position:')

%% Converting from Running to Upfront
[ProbData,HazData] = cdsbootstrap(ZeroData,MarketData,Settle);

Maturity3 = MarketData(:,1);
Spread3Run = MarketData(:,2);
Spread3Std = 100*ones(size(Maturity3)); % Standard spread of 100 bp
Price3 = cdsprice(ZeroData,ProbData,Settle,Maturity3,Spread3Std);
Upfront3 = Price3/10000000; % Standard notional of 10MM
display(Upfront3);
ProbData3Upf = cdsbootstrap(ZeroData,[Maturity3 Upfront3 Spread3Std],Settle);
Spread3RunFromUpf = cdsspread(ZeroData,ProbData3Upf,Settle,Maturity3);
display([Spread3Run Spread3RunFromUpf]);

%Under the flat-hazard rate (FHR) quoting convention, a single market quote is used to calibrate a probability curve. 
%This convention yields a single point in the probability curve, and a single hazard rate value
%For example, assume  a 4-year (standard dates) CDS contract with a current FHR based running spread of 550 bp needs 
%conversion to a CDS contract with a standard spread of 500 bp:
Maturity4 = datenum('20-Sep-13');
Spread4Run = 550;
ProbData4Run = cdsbootstrap(ZeroData,[Maturity4 Spread4Run],Settle);
Spread4Std = 500;
Price4 = cdsprice(ZeroData,ProbData4Run,Settle,Maturity4,Spread4Std);
Upfront4 = Price4/10000000;
fprintf('A running spread of %5.2f is equivalent to\n',Spread4Run);
fprintf('   a standard spread of %5.2f with an upfront of %8.7f\n',...
   Spread4Std,Upfront4);

%To reverse the conversion:
ProbData4Upf = cdsbootstrap(ZeroData,[Maturity4 Upfront4 Spread4Std],Settle);
Spread4RunFromUpf = cdsspread(ZeroData,ProbData4Upf,Settle,Maturity4);
fprintf('A standard spread of %5.2f with an upfront of %8.7f\n',...
   Spread4Std,Upfront4);
fprintf('    is equivalent to a running spread of %5.2f\n',Spread4RunFromUpf);

%% Inverted CDS market curve
MarketSpreadsInv1 = [750 650 550 500 450]';
MarketDataInv1 = [MarketDates MarketSpreadsInv1];
[ProbDataInv1,HazDataInv1] = cdsbootstrap(ZeroData,MarketDataInv1,Settle);
% In the second example, cdsbootstrap generates a warning:
MarketSpreadsInv2 = [800 550 400 250 100]';
MarketDataInv2 = [MarketDates MarketSpreadsInv2];

[ProbDataInv2,HazDataInv2] = cdsbootstrap(ZeroData,MarketDataInv2,Settle);
% A non-monotone bootstrapped probability curve implies negative default probabilities and negative hazard rates for certain time intervals. 
ProbTimes = yearfrac(Settle, MarketDates);
figure('Position',[scrsz(4)/16 scrsz(4)/4 7*scrsz(3)/8 scrsz(4)/2]);
subplot(1,3,1)
plot(MarketDates, MarketSpreadsInv1, 'o')
hold on
plot(MarketDates, MarketSpreadsInv2, 'x')
legend('1st instance','2nd instance','location','NorthEast')
grid on
%Set Ticks
labels = datestr(MarketDates, 12);
set(gca, 'XTick', MarketDates);
set(gca, 'XTickLabel', labels);
xlabel('Date')
ylabel('Spread (bp)')
title('Inverted Market Spread')

subplot(1,3,2)
plot([0; ProbTimes],[0; ProbDataInv1(:,2)])
hold on
plot([0; ProbTimes],[0; ProbDataInv2(:,2)],'--')
hold off
grid on
axis([0 ProbTimes(end,1) 0 ProbDataInv1(end,2)])
xlabel('Time (years)')
ylabel('Cumulative Default Probability')
title('Probability Curves for Inverted Spread Curves')
legend('1st instance','2nd instance','location','SouthEast')

% The hazard rates for these bootstrapped curves are decreasing because the short-term risk is higher. 
% Some bootstrapped parameters in the second curve are negative, as indicated by the warning.

HazTimes = yearfrac(Settle, MarketDates);
subplot(1,3,3)
stairs([0; HazTimes(1:end-1,1); HazTimes(end,1)+1],...
   [HazDataInv1(:,2);HazDataInv1(end,2)])
hold on
stairs([0; HazTimes(1:end-1,1); HazTimes(end,1)+1],...
   [HazDataInv2(:,2);HazDataInv2(end,2)],'--')
hold off
grid on
xlabel('Time (years)')
ylabel('Hazard Rate')
title('Hazard Rates for Inverted Spread Curves')
legend('1st instance','2nd instance','location','NorthEast')
