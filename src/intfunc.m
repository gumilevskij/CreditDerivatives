% Calculates expected loss of Large Homogeneous Portfolio with the aid of
% NIG Copula
%
% Parameters:
% x = Unknown parameter
% K1 = Attachment point of the tranche
% R = Recovery
% C = default threshold
% rho = is the pairwise correlation of default
% alpha - Tail heavyness in NIG distribution
% beta -  Asymmetry parameter in NIG distribution
% mu -    Location parameter in NIG distribution
% delta - Scale parameter in NIG distribution

function y=intfunc(x,K1,R,C,rho,alpha,beta,mu,delta)

s=sqrt(1-rho^2)/rho;
temp1=nigcdf(x,s*alpha,s*beta,-s*mu,s*delta)-(K1/(1-R));
temp2=nigpdf((C-sqrt(1-rho^2)*x)/rho,alpha,beta,-mu,delta)*(sqrt(1-rho^2)/rho);
y=temp1.*temp2;
end

