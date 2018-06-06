clc;
clear all;
format long

addpath('/Applications/CPLEX_Studio128/cplex/matlab/x86-64_osx');
addpath('/Users/junzhang/Desktop/Ipopt-3.11.8-linux64mac64win32win64-matlabmexfiles');

global yearindex
yearindex = 2008;

% Input files
input_file_prices  = 'Daily_closing_prices20082009.csv';

% Read daily prices
if(exist(input_file_prices,'file'))
  fprintf('\nReading daily prices datafile - %s\n', input_file_prices)
  fid = fopen(input_file_prices);
     % Read instrument tickers
     hheader  = textscan(fid, '%s', 1, 'delimiter', '\n');
     headers = textscan(char(hheader{:}), '%q', 'delimiter', ',');
     tickers = headers{1}(2:end);
     % Read time periods
     vheader = textscan(fid, '%[^,]%*[^\n]');
     dates = vheader{1}(1:end);
  fclose(fid);
  data_prices = dlmread(input_file_prices, ',', 1, 1);
else
  error('Daily prices datafile does not exist')
end

% Convert dates into array [year month day]
format_date = 'mm/dd/yyyy';
dates_array = datevec(dates, format_date);
dates_array = dates_array(:,1:3);

% Find the number of trading days in Nov-Dec 2007 and
% compute expected return and covariance matrix for period 1
day_ind_start0 = 1;
day_ind_end0 = length(find(dates_array(:,1)==2007));
cur_returns0 = data_prices(day_ind_start0+1:day_ind_end0,:) ./ data_prices(day_ind_start0:day_ind_end0-1,:) - 1;
mu = mean(cur_returns0)';
Q = cov(cur_returns0);

% Remove datapoints for year 2007
data_prices = data_prices(day_ind_end0+1:end,:);
dates_array = dates_array(day_ind_end0+1:end,:);
dates = dates(day_ind_end0+1:end,:);

% Initial positions in the portfolio
init_positions = [5000 950 2000 0 0 0 0 2000 3000 1500 0 0 0 0 0 0 1001 0 0 0]';

% Initial value of the portfolio
init_value = data_prices(1,:) * init_positions;
fprintf('\nInitial portfolio value = $ %10.2f\n\n', init_value);

% Initial portfolio weights
w_init = (data_prices(1,:) .* init_positions')' / init_value;

% Number of periods, assets, trading days
N_periods = 6*length(unique(dates_array(:,1))); % 6 periods per year
N = length(tickers);
N_days = length(dates);

% Annual risk-free rate for years 2015-2016 is 2.5%
r_rf = 0.025;
% Annual risk-free rate for years 2008-2009 is 4.5%
r_rf2008_2009 = 0.045;

% Number of strategies
strategy_functions = {'strat_buy_and_hold' 'strat_equally_weighted' 'strat_min_variance' 'strat_max_Sharpe' 'strat_equal_risk_contr' 'strat_lever_equal_risk_contr' 'strat_robust_optim'};
strategy_names     = {'Buy and Hold' 'Equally Weighted Portfolio' 'Minimum Variance Portfolio' 'Maximum Sharpe Ratio Portfolio' 'Equal Risk Contributions Portfolio' 'Leveraged Equal Risk Contributions Portfolio' 'Robust Optimization Portfolio'};
%N_strat = 5; % comment this in your code
N_strat = length(strategy_functions); % uncomment this in your code
fh_array = cellfun(@str2func, strategy_functions, 'UniformOutput', false);

for (period = 1:N_periods)
   global period
   % Compute current year and month, first and last day of the period
   if(dates_array(1,1)== 08)
       cur_year  = 08 + floor(period/7);
   else
       cur_year  = 2008  + floor(period/7);
   end
   cur_month = 2*rem(period-1,6) + 1;
   day_ind_start = find(dates_array(:,1)==cur_year & dates_array(:,2)==cur_month, 1, 'first');
   day_ind_end = find(dates_array(:,1)==cur_year & dates_array(:,2)==(cur_month+1), 1, 'last');
   fprintf('\nPeriod %d: start date %s, end date %s\n', period, char(dates(day_ind_start)), char(dates(day_ind_end)));

   % Prices for the current day
   cur_prices = data_prices(day_ind_start,:);

   % Execute portfolio selection strategies
   for(strategy = 1:N_strat)

      % Get current portfolio positions
      if(period==1)
         curr_positions = init_positions;
         curr_cash = 0;
         portf_value{strategy} = zeros(N_days,1);
      else
         curr_positions = x{strategy,period-1};
         curr_cash = cash{strategy,period-1};
      end

      % Compute strategy
      [x{strategy,period} cash{strategy,period}] = fh_array{strategy}(curr_positions, curr_cash, mu, Q, cur_prices);

      % Verify that strategy is feasible (you have enough budget to re-balance portfolio)
      % Check that cash account is >= 0
      % Check that we can buy new portfolio subject to transaction costs

      %%%%%%%%%%% Insert your code here %%%%%%%%%%%%

      % Compute portfolio value
      if strategy == 6
        portf_value{strategy}(day_ind_start:day_ind_end) = data_prices(day_ind_start:day_ind_end,:) * x{strategy,period} + cash{strategy,period} - 548247.97;
      else
        portf_value{strategy}(day_ind_start:day_ind_end) = data_prices(day_ind_start:day_ind_end,:) * x{strategy,period} + cash{strategy,period};
      end
      
      fprintf('   Strategy "%s", value begin = $ %10.2f, value end = $ %10.2f\n', char(strategy_names{strategy}), portf_value{strategy}(day_ind_start), portf_value{strategy}(day_ind_end));

   end
      
   % Compute expected returns and covariances for the next period
   cur_returns = data_prices(day_ind_start+1:day_ind_end,:) ./ data_prices(day_ind_start:day_ind_end-1,:) - 1;
   mu = mean(cur_returns)';
   Q = cov(cur_returns);
   
end


%%
% Plot results
%%%%%%%%%%% Insert your code here %%%%%%%%%%%%

%plot daily value using four different strategies 
days = linspace(1,N_days,N_days);
y1 = portf_value{1};
y2 = portf_value{2};
y3 = portf_value{3};
y4 = portf_value{4};
y5 = portf_value{5};
y6 = portf_value{6};
y7 = portf_value{7};

figure
plot(days,y1,'LineWidth',2)
hold on;
plot(days,y2,'LineWidth',2)
hold on;
plot(days,y3,'LineWidth',2)
hold on;
plot(days,y4,'LineWidth',2)
hold on;
plot(days,y5,'LineWidth',2)
hold on;
plot(days,y6,'LineWidth',2)
hold on;
plot(days,y7,'LineWidth',2)


xlabel('Trading Days');
ylabel('Value');
title('Daily Value of Portfolio (2008-2009)')
legend('Buy and Hold','Equally Weighted Portfolio','Minimum Variance Portfolio','Maximum Sharpe Ratio Portfolio','Equal Risk Contributions Portfolio','Leveraged Equal Risk Contributions Portfolio','Robust Optimization Portfolio','Location','northwest');

%%
% plot strategy 3?4 and 7 to show dynamic changes in portfolio allocations

% strategy 3
y_axis = zeros(N_periods,20);
for i = 1:N_periods % for 12 period
    minvar_pos = x{3,i}; % select weight info for strategy 3
    index = 42 * (i - 1) + 1;
    value_of_each_stock = minvar_pos' .* data_prices(index,:);
    period_weight = value_of_each_stock / portf_value{3}(index);
    y_axis(i,:) = period_weight;
end

figure
area(y_axis)
set(get(gcf,'Children'),'YLim',[0 1],'Xlim',[1 12]);

xlabel('Trading Period');
ylabel('Weight');
title('Dynamic Change in Portfolio Alloction - Minimum variance (2008-2009)');
legend('MSFT', 'F',	'CRAY', 'GOOG',	'HPQ','YHOO','HOG','VZ','AAPL',...
    'IBM','T','CSCO','BAC','INTC','AMD','SNE','NVDA','AMZN','MS','BK');

% strategy 4
y_axis = zeros(N_periods,20);
for i = 1:N_periods % for 12 period
    minvar_pos = x{4,i}; % select weight info for strategy 7
    index = 42 * (i - 1) + 1;
    value_of_each_stock = minvar_pos' .* data_prices(index,:);
    period_weight = value_of_each_stock / portf_value{4}(index);
    y_axis(i,:) = period_weight;
end

figure
area(y_axis)
set(get(gcf,'Children'),'YLim',[0 1],'Xlim',[1 12]);

xlabel('Trading Period');
ylabel('Weight');
title('Dynamic Change in Portfolio Alloction - Maximum Sharpe ratio (2008-2009)');
legend('MSFT', 'F',	'CRAY', 'GOOG',	'HPQ','YHOO','HOG','VZ','AAPL',...
    'IBM','T','CSCO','BAC','INTC','AMD','SNE','NVDA','AMZN','MS','BK');
%%
% strategy 7
y_axis = zeros(N_periods,20);
for i = 1:N_periods % for 12 period
    minvar_pos = x{7,i}; % select weight info for strategy 7
    index = 42 * (i - 1) + 1;
    value_of_each_stock = minvar_pos' .* data_prices(index,:);
    period_weight = value_of_each_stock / portf_value{7}(index);
    y_axis(i,:) = period_weight;
end

figure
area(y_axis)
set(get(gcf,'Children'),'YLim',[0 1],'Xlim',[1 12]);

xlabel('Trading Period');
ylabel('Weight');
title('Dynamic Change in Portfolio Alloction - Robust Mean Variance (2008-2009)');
legend('MSFT', 'F',	'CRAY', 'GOOG',	'HPQ','YHOO','HOG','VZ','AAPL',...
    'IBM','T','CSCO','BAC','INTC','AMD','SNE','NVDA','AMZN','MS','BK');

