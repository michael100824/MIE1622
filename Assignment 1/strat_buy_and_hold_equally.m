function  [x_optimal, cash_optimal] = strat_buy_and_hold_equally(x_init, cash_init, mu, Q, cur_prices)
    % This function is to buy the optimal stocks and hold them until the
    % last day of a period.
    
    % x_optimal is an 1*20 array and cash_optimal is a non-negative number
    total_money = cur_prices(end,:) * x_init + cash_init;
    x_optimal = [1065;3225;1497;94;2715;993;757;1060;456;307;1469;1800;2771;1369;17748;2414;2465;161;1286;1230];
    transaction = cur_prices(end,:) * abs((x_optimal - x_init)) * 0.005;
    cash_optimal = total_money - cur_prices(end,:) * x_optimal - transaction; %scalar
    
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