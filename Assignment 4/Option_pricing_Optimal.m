clc;
clear all;
format long

% Pricing a European option using Black-Scholes formula and Monte Carlo simulations
% Pricing a Barrier option using Monte Carlo simulations

S0 = 100;     % spot price of the underlying stock today
K = 105;      % strike at expiry
mu = 0.05;    % expected return
sigma = 0.2;  % volatility
r = 0.05;     % risk-free rate
T = 1.0;      % years to expiry
Sb = 110;     % barrier


% Define variable numSteps to be the number of steps for multi-step MC
% numPaths - number of sample paths used in simulations
numPaths_list = [10000 20000 30000 40000 50000 60000 70000 80000 90000 100000];
numSteps_list = [2 12 24 252];

%%
% Implement your Black-Scholes pricing formula
[call_BS_European_Price, putBS_European_Price] = BS_european_price(S0, K, T, r, sigma);

bs_call = repelem(call_BS_European_Price,length(numPaths_list));
bs_buy = repelem(putBS_European_Price,length(numPaths_list));

for i = 1:length(numPaths_list)
    numSteps = 5;
    % Implement your one-step Monte Carlo pricing procedure for European option
    [callMC_European_Price_1_step, putMC_European_Price_1_step] = MC_european_price(S0, K, T, r, mu, sigma, 1, numPaths_list(i));

    % Implement your multi-step Monte Carlo pricing procedure for European option
    [callMC_European_Price_multi_step, putMC_European_Price_multi_step] = MC_european_price(S0, K, T, r, mu, sigma, numSteps, numPaths_list(i));
    
    call_1step_collect(i) = callMC_European_Price_1_step;
    put_1step_collect(i) = putMC_European_Price_1_step;
    call_multistep_collect(i) = callMC_European_Price_multi_step;
    put_multistep_collect(i) = putMC_European_Price_multi_step;
    
    var_1step_collect(i) = (callMC_European_Price_1_step - call_BS_European_Price)^2 + (putMC_European_Price_1_step - putBS_European_Price)^2;
    var_multistep_collect(i) = (callMC_European_Price_multi_step - call_BS_European_Price)^2 + (putMC_European_Price_multi_step - putBS_European_Price)^2;
end
%%
figure(1)
x = numPaths_list;
y1 = bs_call;
y2 = bs_buy;
y3 = call_1step_collect;
y4 = put_1step_collect;
y5 = call_multistep_collect;
y6 = put_multistep_collect;
plot(x,y1,'LineWidth',2)
hold on;
plot(x,y2,'LineWidth',2)
hold on;
plot(x,y3,'b*',x,y4,'r+',x,y5,'bo',x,y6,'rx')
axis([numPaths_list(1) numPaths_list(end) 7 9])
legend('BS Call', 'BS Put', 'One Step Call', 'One Step Put', 'MultiStep Call', 'MultiStep Put','Location', 'SouthEast')
xlabel('Num of Paths')
ylabel('Prices')
title('Num of Paths Vs Prices')
%hold off;
%%
figure(2)
x = numPaths_list;
y1 = var_1step_collect;
y2 = var_multistep_collect;
plot(x,y1,x,y2)
legend('Var of One Step MC','Var of Multiple Step MC','Location', 'NorthEast')
xlabel('Num of Paths')
ylabel('Variance')
title('Num of Paths Vs Variance')
%%
bs_call = repelem(call_BS_European_Price,length(numSteps_list));
bs_buy = repelem(putBS_European_Price,length(numSteps_list));

call_multistep_collect = [];
put_multistep_collect = [];
var_multistep_collect = [];

for i = 1:length(numSteps_list)
    % Implement your multi-step Monte Carlo pricing procedure for European option
    [callMC_European_Price_multi_step, putMC_European_Price_multi_step] = MC_european_price(S0, K, T, r, mu, sigma, numSteps_list(i), 50000);
    
    call_multistep_collect(i) = callMC_European_Price_multi_step;
    put_multistep_collect(i) = putMC_European_Price_multi_step;
    
    var_multistep_collect(i) = (callMC_European_Price_multi_step - call_BS_European_Price)^2 + (putMC_European_Price_multi_step - putBS_European_Price)^2;
end

%%
figure(3)
x = numSteps_list;
y1 = bs_call;
y2 = bs_buy;
y5 = call_multistep_collect;
y6 = put_multistep_collect;
plot(x,y1,'LineWidth',2)
hold on;
plot(x,y2,'LineWidth',2)
hold on;
plot(x,y5,'bo',x,y6,'r  x')
hold off;
axis([numSteps_list(1) numSteps_list(end) 7 9])
legend('BS Call', 'BS Put', 'MultiStep Call', 'MultiStep Put','Location', 'SouthEast')
xlabel('Num of Steps')
ylabel('Prices')
title('Num of Steps Vs Prices')
%%
figure(4)
x = numSteps_list;
y2 = var_multistep_collect;
plot(x,y2)
legend('Var of Multiple Step MC','Location', 'NorthEast')
xlabel('Num of Steps')
ylabel('Variance')
title('Num of Steps Vs Variance')

%%

% % Implement your one-step Monte Carlo pricing procedure for Barrier option
% [callMC_Barrier_Knockin_Price_1_step, putMC_Barrier_Knockin_Price_1_step] = ...
%     MC_barrier_knockin_price(S0, Sb, K, T, r, mu, sigma, 1, numPaths);
% 
% % Implement your multi-step Monte Carlo pricing procedure for Barrier option
% [callMC_Barrier_Knockin_Price_multi_step, putMC_Barrier_Knockin_Price_multi_step] = ...
%     MC_barrier_knockin_price(S0, Sb, K, T, r, mu, sigma, numSteps, numPaths);

bs_call = repelem(call_BS_European_Price,length(numPaths_list));
bs_buy = repelem(putBS_European_Price,length(numPaths_list));
call_1step_collect = [];
put_1step_collect = [];
call_multistep_collect = [];
put_multistep_collect = [];
var_1step_collect = [];
var_multistep_collect = [];

for i = 1:length(numPaths_list)
    numSteps = 5;
    % Implement your one-step Monte Carlo pricing procedure for Barrier option
    [callMC_Barrier_Knockin_Price_1_step, putMC_Barrier_Knockin_Price_1_step] = ...
        MC_barrier_knockin_price(S0, Sb, K, T, r, mu, sigma, 1, numPaths_list(i));

    % Implement your multi-step Monte Carlo pricing procedure for Barrier option
    [callMC_Barrier_Knockin_Price_multi_step, putMC_Barrier_Knockin_Price_multi_step] = ...
        MC_barrier_knockin_price(S0, Sb, K, T, r, mu, sigma, numSteps, numPaths_list(i));
    
    call_1step_collect(i) = callMC_Barrier_Knockin_Price_1_step;
    put_1step_collect(i) = putMC_Barrier_Knockin_Price_1_step;
    call_multistep_collect(i) = callMC_Barrier_Knockin_Price_multi_step;
    put_multistep_collect(i) = putMC_Barrier_Knockin_Price_multi_step;
    
    var_1step_collect(i) = (callMC_Barrier_Knockin_Price_1_step - call_BS_European_Price)^2 + (putMC_Barrier_Knockin_Price_1_step - putBS_European_Price)^2;
    var_multistep_collect(i) = (callMC_Barrier_Knockin_Price_multi_step - call_BS_European_Price)^2 + (putMC_Barrier_Knockin_Price_multi_step - putBS_European_Price)^2;
end
%%
figure(5)
x = numPaths_list;
y1 = bs_call;
y2 = bs_buy;
y3 = call_1step_collect;
y4 = put_1step_collect;
y5 = call_multistep_collect;
y6 = put_multistep_collect;
plot(x,y1,'LineWidth',2)
hold on;
plot(x,y2,'LineWidth',2)
hold on;
plot(x,y3,'b*',x,y4,'r+',x,y5,'bo',x,y6,'rx')
axis([numPaths_list(1) numPaths_list(end) 0 9])
legend('BS Call', 'BS Put', 'One Step Call', 'One Step Put', 'MultiStep Call', 'MultiStep Put','Location', 'SouthEast')
xlabel('Num of Paths')
ylabel('Prices')
title('Num of Paths Vs Prices')
%hold off;
%%
figure(6)
x = numPaths_list;
y1 = var_1step_collect;
y2 = var_multistep_collect;
plot(x,y1,x,y2)
legend('Var of One Step MC','Var of Multiple Step MC','Location', 'NorthEast')
xlabel('Num of Paths')
ylabel('Variance')
title('Num of Paths Vs Variance')
%%
bs_call = repelem(call_BS_European_Price,length(numSteps_list));
bs_buy = repelem(putBS_European_Price,length(numSteps_list));

call_multistep_collect = [];
put_multistep_collect = [];

var_multistep_collect = [];

for i = 1:length(numSteps_list)

    % Implement your multi-step Monte Carlo pricing procedure for European option
    [callMC_Barrier_Knockin_Price_multi_step, putMC_Barrier_Knockin_Price_multi_step] = ...
        MC_barrier_knockin_price(S0, Sb, K, T, r, mu, sigma, numSteps_list(i), 70000);
        
    call_multistep_collect(i) = callMC_Barrier_Knockin_Price_multi_step;
    put_multistep_collect(i) = putMC_Barrier_Knockin_Price_multi_step;
    
    var_multistep_collect(i) = (callMC_Barrier_Knockin_Price_multi_step - call_BS_European_Price)^2 + (putMC_Barrier_Knockin_Price_multi_step - putBS_European_Price)^2;
end

%%
figure(7)
x = numSteps_list;
y1 = bs_call;
y2 = bs_buy;
y5 = call_multistep_collect;
y6 = put_multistep_collect;
plot(x,y1,'LineWidth',2)
hold on;
plot(x,y2,'LineWidth',2)
hold on;
plot(x,y5,'bo',x,y6,'r  x')
hold off;
axis([numSteps_list(1) numSteps_list(end) 0 9])
legend('BS Call', 'BS Put', 'MultiStep Call', 'MultiStep Put','Location', 'SouthEast')
xlabel('Num of Steps')
ylabel('Prices')
title('Num of Steps Vs Prices')
%%
figure(8)
x = numSteps_list;
y2 = var_multistep_collect;
plot(x,y2)
legend('Var of Multiple Step MC','Location', 'NorthEast')
xlabel('Num of Steps')
ylabel('Variance')
title('Num of Steps Vs Variance')

% disp(['Black-Scholes price of an European call option is ',num2str(call_BS_European_Price)])
% disp(['Black-Scholes price of an European put option is ',num2str(putBS_European_Price)])
% disp(['One-step MC price of an Barrier call option is ',num2str(callMC_Barrier_Knockin_Price_1_step)])
% disp(['One-step MC price of an Barrier put option is ',num2str(putMC_Barrier_Knockin_Price_1_step)])
% disp(['Multi-step MC price of an Barrier call option is ',num2str(callMC_Barrier_Knockin_Price_multi_step)])
% disp(['Multi-step MC price of an Barrier put option is ',num2str(putMC_Barrier_Knockin_Price_multi_step)])


