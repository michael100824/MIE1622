function [x_optimal, cash_optimal] = strat_equally_weighted(x_init, cash_init, mu, Q, cur_prices)  
    
    % compute the total asset 
    total_money = cur_prices * x_init + cash_init;
    % equally allocate to each stock, which is 1/20 of total asset
    allocated_money = ones(1,20) * total_money * 1/20; % 1*20
    
    x_optimal = floor(allocated_money./ cur_prices)';%20*1
    transaction = cur_prices * abs((x_optimal - x_init)) * 0.005;
    cash_optimal = total_money - cur_prices * x_optimal - transaction; %scalar
    
    % check if cash_optimal is non negative
    if cash_optimal < 0
        % find out the ratio between the postion of each stock and total position 
        ratio = (x_optimal ./ sum(x_optimal))'; 
        % allocate the negative cash to each stock to balance 
        cash_balance = abs(cash_optimal)* ratio;
        % use the allocated cash divide by stock price to get the position
        % of each stock
        position_balance = ceil(cash_balance ./ cur_prices)';
        % the new x_optimal is the difference between inital position and
        % and balanced position
        x_optimal = x_optimal - position_balance;
        % recalculated transcation fee
        transaction = cur_prices * abs((x_optimal - x_init)) * 0.005;
        % recaculate cash_optimal
        cash_optimal = total_money - cur_prices * x_optimal - transaction; %scalar
    end
end
