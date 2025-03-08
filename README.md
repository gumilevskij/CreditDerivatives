# Credit Derivatives

Examples of Matlab code to price credit derivatives.

# How to Run

In MATLAB please open CDODriver.m script and run it to price CDO instruments, cds.m script - to price CDS, and cds_options.m to price options of CDS.  Please specify instruments parameters for pricing:

- CDS : Valuation date for the CDS, market dates and spreads, zero rates.

- CDS Options: Settlament date, option and CDS maturities,option strike, spread volatility, zero rate and market data such as market rates and dates.

- CDO: Maturity in years, size of portfolio, recovery and hazard rates, coupon rate, risk-free interest rate, number of Monte Carlo paths, parameters of Normal-Inverse Gaussian distribution, corellation coefficients, attachment and detachment points of CDO, for example, iTraxx Euroupe.

# Documentation

For a short introduction to credit derivatives pricing please see <docs/Credit Derivatives.pdf>.
