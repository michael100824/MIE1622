function [call_BS_European_Price, putBS_European_Price] = BS_european_price(S0, K, T, r, sigma)
    t = 0;
    d1=(log(S0/K)+(r+0.5*sigma^2)*(T-t))/(sigma*sqrt(T-t));
    d2=d1-sigma*sqrt(T-t);
    call_BS_European_Price = normcdf(d1)*S0-normcdf(d2)*K*exp(-r*(T-t));
    putBS_European_Price = normcdf(-d2)*K*exp(-r*(T-t))-normcdf(-d1)*S0;
end

