clc;
clear all;
format long

% Pricing a European option using Black-Scholes formula and Monte Carlo simulations
% Pricing a Barrier option using Monte Carlo simulations

S0 = 100;     % spot price of the underlying stock today
K = 105;      % strike at expiry
mu = 0.05;    % expected return
sigma = 0.20;  % volatility
r = 0.05;     % risk-free rate
T = 1.0;      % years to expiry
Sb = 110;     % barrier


% Define variable numSteps to be the number of steps for multi-step MC
% numPaths - number of sample paths used in simulations

% Implement your Black-Scholes pricing formula
[call_BS_European_Price, putBS_European_Price] = BS_european_price(S0, K, T, r, sigma);

% % Implement your one-step Monte Carlo pricing procedure for European option
% [callMC_European_Price_1_step, putMC_European_Price_1_step,path_1] = MC_european_price(S0, K, T, r, mu, sigma, 1, 40000);

% Implement your multi-step Monte Carlo pricing procedure for European option
[callMC_European_Price_multi_step, putMC_European_Price_multi_step,path_mul] = MC_european_price(S0, K, T, r, mu, sigma, 12, 50000);

% Implement your one-step Monte Carlo pricing procedure for Barrier option
[callMC_Barrier_Knockin_Price_1_step, putMC_Barrier_Knockin_Price_1_step] = ...
    MC_barrier_knockin_price(S0, Sb, K, T, r, mu, sigma, 1, 10000);

% Implement your multi-step Monte Carlo pricing procedure for Barrier option
[callMC_Barrier_Knockin_Price_multi_step, putMC_Barrier_Knockin_Price_multi_step] = ...
    MC_barrier_knockin_price(S0, Sb, K, T, r, mu, sigma, 252, 70000);

disp(['Black-Scholes price of an European call option is ',num2str(call_BS_European_Price)])
disp(['Black-Scholes price of an European put option is ',num2str(putBS_European_Price)])
disp(['One-step MC price of an European call option is ',num2str(callMC_European_Price_1_step)])
disp(['One-step MC price of an European put option is ',num2str(putMC_European_Price_1_step)])
disp(['Multi-step MC price of an European call option is ',num2str(callMC_European_Price_multi_step)])
disp(['Multi-step MC price of an European put option is ',num2str(putMC_European_Price_multi_step)])
disp(['One-step MC price of an Barrier call option is ',num2str(callMC_Barrier_Knockin_Price_1_step)])
disp(['One-step MC price of an Barrier put option is ',num2str(putMC_Barrier_Knockin_Price_1_step)])
disp(['Multi-step MC price of an Barrier call option is ',num2str(callMC_Barrier_Knockin_Price_multi_step)])
disp(['Multi-step MC price of an Barrier put option is ',num2str(putMC_Barrier_Knockin_Price_multi_step)])


% Plot results
figure(1);  
%%%%%%%%%%% Insert your code here %%%%%%%%%%%%
% plot Monte Carlo pricing procedure
%%
numPaths = 50000;
numSteps = 12;
for i=1:numPaths 
    plot(1:numSteps+1,path_mul(:,i));
    hold on;
end
hold off;
axis([0 numSteps+1 30 inf])
title('Underlying Stock Price Simulations');

