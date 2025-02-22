%% Computes survival probability of Nth-to-Default Swap
% Uses Hull-White iterattive methods

function ret=integrand(M,t,k,rho,lambda,method)
    N = numel(M);
	Qi=1-exp(-lambda*t);
	Fi=norminv(Qi,0,1);
	tmp=(Fi-rho*M)/sqrt(1-rho^2);
	Si=(1-normcdf(tmp)); %probability of survival of each firm
    
    if method == 1
        piT0=Si.^N; %probability that all firms will survive
        wi=(1-Si)/Si;
        Vvec=ones(N,1)*wi;
        idxvec=1:N;
        idxvec=idxvec';
        Vvec=N*(Vvec.^idxvec);
        Uvec=zeros(N,1);
        Uvec(1)=Vvec(1);
        for ki=2:N,
            tmpsum=0;
            for ki2=1:ki-1,
                tmpsum=tmpsum-(-1)^(ki2)*Uvec(ki-ki2)*Vvec(ki2);
            end
            tmpsum=tmpsum+(-1)^(ki+1)*Vvec(ki);
            Uvec(ki)=tmpsum/ki;
        end
        piTvec=piT0'.*Uvec;
        
    elseif method == 2
        ptk=zeros(N+1,N+1); %proability that exactly l defaults happend for k firms
        qki=1-Si; %probability of default for each firm
        ptk(1,1)=1; %probability that 0 defaults happend when there are 0 firms
        for i=2:N+1,
            ptk(1,i)=ptk(1,i-1)*(1-qki(i-1));
            for i2=2:i-1,
                ptk(i2,i)=ptk(i2,i-1)*(1-qki(i-1))+ptk(i2-1,i-1)*qki(i-1);
            end
            ptk(i,i)=ptk(i-1,i-1)*qki(i-1);
        end
        piTvec=ptk(:,N+1);
        
    end
    
	survival_prob=1-sum(piTvec(k:N));
	ret=survival_prob*normpdf(M);
end

