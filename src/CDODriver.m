%% Collaterilized Debt Obligation Driver
    addpath('NIG');
    warning ('off','all');
    TM = 5;                            % Maturity in years
    tstep = 0.5;                       % Time step in years
    portfSize = 125;                   % Size of portfolio
    R = 0.4;                           % Recovery rate
    lambda = 0.015;                    % Coefficient for hazard rate in Poisson equation
    Notional = 1.e6;                   % Notional of a name in portfolio
    Coupon = 50/1.e4;                  % Coupon rate
    IR = 0.04;                         % Risk-free interest rate
    No = 1.e4;                         % Number of Monte Carlo paths
    alpha = 1.0;                       % Tail heavyness of Normal-Inverse Gaussian distribution
    beta  = -0.1;                      % Asymmetry parameter of Normal-Inverse Gaussian distribution
    gamma = sqrt(alpha^2-beta^2);
    delta=gamma^3/alpha^2;             % Scale parameter of Normal-Inverse Gaussian distribution 
    mu=beta*delta/gamma;               % Location parameter of Normal-Inverse Gaussian distribution
    rho = [0.01,0.2,0.4,0.7,0.99];     % Corellation coefficients
    attach = [0.0, 0.03, 0.06, 0.09, 0.12, 0.22];  % Attachment points of iTraxx Europe
    detach = [0.03, 0.06, 0.09, 0.12, 0.22, 0.99]; % Detachment points of iTraxx Europe
    upfronts = [500, 500, 300, 100, 100, 100];  % Upfront payments of iTraxx Europe (bp)
    quotes = [3481, 300, 75, 174, 80.5, 17.5]; % Market quotes (bp) for iTraxx Europe Series 15.1 on 28 March 2013
    tranches = {'Equity','Junior Mezzanine','Senior Mezzanine','Junior Senior','Senior','Super Senior'};
    M = length(rho);
    N = length(attach);
    NumberOfTranches = numel(tranches);
    fixedLegVal=zeros(N,M);floatLegVal=zeros(N,M);buyerSellerVal=zeros(N,M);spread=zeros(N,M);fixedLegErr=zeros(N,M);floatingLegErr=zeros(N,M);
    fixedLegValLHP=zeros(N,M);floatLegValLHP=zeros(N,M);buyerSellerValLHP=zeros(N,M);spreadLHP=zeros(N,M);buyerSellerValHW=zeros(N,M);
    fixedLegValHW=zeros(N,M);floatLegValHW=zeros(N,M);spreadHW=zeros(N,M);fixedLegValNIG=zeros(N,M);floatLegValNIG=zeros(N,M);buyerSellerValNIG=zeros(N,M);spreadNIG=zeros(N,M);
    
    %%Large Homogeneous Portfolio Approximation
    PDs = [0.001 0.01 0.1 0.3];
    M1 = numel(PDs);    
    M2 = 500;
    lhp=zeros(M,M1,M2); lhpNIG=zeros(M,M1,M2); x=zeros(1,M2); str=cell(M,M1);
    for j = 1:M 
        k=0;
        for PD = PDs
            k=k+1;
            for i = 1:M2
                x(i) = (i-1)/M2;
                lhp(j,k,i) = CDL_LHP(x(i), rho(j), PD);
            end
            C_NIG=niginv(PD,alpha/rho(j),beta/rho(j),-mu/rho(j),delta/rho(j));
            s=sqrt(1-rho(j)^2)/rho(j);
            theta_inv=niginv(x/(1-R),s*alpha,s*beta,-s*mu,s*delta);
            lhpNIG(j,k,:) = 1-nigcdf((C_NIG-theta_inv*sqrt(1-rho(j)^2))/rho(j),alpha,beta,-mu,delta);
            str{j,k} = strcat('Rho=',num2str(rho(j)),', PD=', num2str(PD));
        end
    end
    dlhp = M2*(lhp(:,:,2:end) - lhp(:,:,1:end-1));
    dlhpNIG = M2*(lhpNIG(:,:,2:end) - lhpNIG(:,:,1:end-1));
    xx = x(2:M2);
    yy = dlhp(:,:,1:(M2-1));
    yy2 = dlhpNIG(:,:,1:(M2-1));
    
    % Graphs
    scrsz = get(groot,'ScreenSize');
    figure('Position',[scrsz(4)/8 scrsz(4)/8 3*scrsz(3)/4 scrsz(4)/2]);
    k=2;
    subplot(1,2,1)
    plot(xx,[squeeze(yy(k,1,:)),squeeze(yy(k,2,:)),squeeze(yy(k,3,:)),squeeze(yy(k,4,:))])
    axis([0,0.5,0,0.1*M2])
    legend( str{k,1},str{k,2},str{k,3},str{k,4})
    xlabel('Loss')
    ylabel('PDF')
    title('LHP Loss Distribution (Normal Copula)')
    subplot(1,2,2)
    plot(xx,[squeeze(yy2(k,1,:)),squeeze(yy2(k,2,:)),squeeze(yy2(k,3,:)),squeeze(yy2(k,4,:))])
    axis([0,0.5,0,0.1*M2]);
    legend(str{k,1},str{k,2},str{k,3},str{k,4},'Location','NorthEast')
    text(0.33,0.07*M2,strcat('alpha=',num2str(alpha)))
    text(0.33,0.065*M2,strcat('beta=',num2str(beta)))
    text(0.33,0.06*M2,strcat('mu=',num2str(mu)))
    text(0.33,0.055*M2,strcat('delta=',num2str(delta)))
    text(0.33,0.05*M2,strcat('gamma=',num2str(gamma)))
    xlabel('Loss')
    ylabel('PDF')
    title('LHP Loss Distribution (Normal-Inverse Gaussian Copula)')
    
    %% Monte Carlo Simulations
    for j = 1:M % loop over correlation coefficients
        for i=1:N % loop over tranches
            [fixedLegVal(i,j),floatLegVal(i,j),buyerSellerVal(i,j),spread(i,j),fixedLegErr(i,j),floatingLegErr(i,j)] = ...
                CDOPrice( 1.e-4*upfronts(i),Notional,portfSize,R,Coupon,IR,rho(j),lambda,attach(i),detach(i),No,TM,tstep);
            % LHP Approximation (Gaussian distribution)
            [fixedLegValLHP(i,j),floatLegValLHP(i,j),buyerSellerValLHP(i,j),spreadLHP(i,j)] = ...
                LHPPrice( 1.e-4*upfronts(i),Notional,R,Coupon,IR,rho(j),lambda,attach(i),detach(i),TM,tstep);
            % LHP Approximation (Normal Inverse Gaussian distribution)
            [fixedLegValNIG(i,j),floatLegValNIG(i,j),buyerSellerValNIG(i,j),spreadNIG(i,j)] = ...
                NIGPrice( 1.e-4*upfronts(i),Notional,R,Coupon,IR,rho(j),lambda, attach(i),detach(i),TM,tstep,alpha,beta,mu,delta);
            % Iterative method of Hull-White for NthToDefault Swap
            %[fixedLegValHW(i,j),floatLegValHW(i,j),buyerSellerValHW(i,j),spreadHW(i,j)] = ...
            %    NthToDefault( Notional, R, Coupon, floor(detach(i)* portfSize), IR, rho(j), lambda, TM, tstep, 2);
        end
    end
    % Upfront payment
    premium = 1.e-4*Notional*sum(upfronts*(detach'-attach'));
    priceMC = 1.e4*(sum(floatLegVal(:,k))-premium*portfSize)/sum(fixedLegVal(:,k)/Coupon);
    priceLHP = 1.e4*(sum(floatLegValLHP(:,k))-premium)/sum(fixedLegValLHP(:,k)/Coupon);
    priceNIG = 1.e4*(sum(floatLegValNIG(:,k))-premium)/sum(fixedLegValNIG(:,k)/Coupon);
    
    figure('Position',[scrsz(4)/4 scrsz(4)/4 scrsz(3)/2 scrsz(4)/2]);
    bar([priceMC, priceNIG, priceLHP],0.3)
    ylabel('Spread (bp)')
    labels = {'Monte Carlo','Normal-Inverse Gaussian Copula','Gaussian Copula'};
    set(gca,'XTick', 1:numel(labels), 'XTickLabel', labels);
    legend(strcat('Rho=',num2str(rho(k))),'Location','northwest')
    title('CDO Breakeven Spread')
    
    % Graphs
    figure('Position',[scrsz(4)/4 scrsz(4)/8 3*scrsz(3)/4 3*scrsz(4)/4]);
    subplot(2,2,1)
    plot(rho,fixedLegVal)
    grid on
    xlabel('Correlation')
    ylabel('Fixed Leg')
    legend(tranches)
    legend('boxoff')
    title('Monte Carlo Fixed Leg Value')
    
    subplot(2,2,2)
    plot(rho,floatLegVal)
    grid on
    xlabel('Correlation')
    ylabel('Floating Leg')
    legend(tranches)
    legend('boxoff')
    title('Monte Carlo Floating Leg Value')
    
    subplot(2,2,3)
    plot(rho,buyerSellerVal)
    grid on
    xlabel('Correlation')
    ylabel('CDO Value')
    legend(tranches)
    legend('boxoff')
    title('Seller''s/Buyer''s CDO Value')
    
    subplot(2,2,4)
    plot(rho,100*sqrt(fixedLegErr.^2+floatingLegErr.^2))
    grid on
    xlabel('Correlation')
    ylabel('Relative Error (%)')
    legend(tranches)
    legend('boxoff')
    title('Standard Error')
    
    figure('Position',[scrsz(4)/4 scrsz(4)/8 3*scrsz(3)/4 3*scrsz(4)/4]);
    ii=0;
    for i=[1,2,4,6]
        ii=ii+1;
        subplot(2,2,ii)
        plot(rho,spread(i,:),rho, spreadLHP(i,:),rho, spreadNIG(i,:),[0,1],[quotes(i),quotes(i)]);
        axis([0,1,0,2*quotes(i)])
        grid on
        xlabel('Correlation')
        ylabel('Spread (bp)')
        legend('Monte Carlo','Normal LHP','Normal-Inverse Gaussian LHP','Market iTraxx Europe Series v15.1','Location','NorthWest')
        legend('boxoff')
        title(strcat('Breakeven Spread For ',tranches{i},' Tranch'))
    end
    
    disp('Done')