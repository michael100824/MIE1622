function [x_optimal, cash_optimal] = strat_max_Sharpe(x_init, cash_init, mu, Q, cur_prices)
        % min y'Qy
        % Subject To:
        % sum [(mu_i-rf)*(y_i)] = 1
        % sum [y_i] - k = 0
        % y_i >= 0
        % k >= 0
    
    global yearindex
    % Add path to CPLEX
    addpath('/Applications/CPLEX_Studio128/cplex/matlab/x86-64_osx');

    % compute the total asset 
    total_money = cur_prices(end,:) * x_init + cash_init;
    % 20 stocks
    n = 21;
    
    if yearindex == 2008
        r_rf = 0.045;
    else
        r_rf = 0.025;
    end
    daily_rf = r_rf/252;
    
    
    Q = [Q zeros(20,1)];
    Q = [Q;zeros(1,21)];
    

    % Optimization problem data
    % 0 <= wi <= inf
    
    diff = mu' - daily_rf;
    A = [ diff 0;ones(1,20) -1];
    
    bound = [1;0];
    
    lb = zeros(n,1);
    ub = inf*ones(n,1); 
    

    % Compute maximum sharpe portfolio
    cplex2 = Cplex('max_Sharpe');
    cplex2.addCols(zeros(n,1), [], lb, ub);
    cplex2.addRows(bound, A, bound);
        
    cplex2.Model.Q = 2*Q;
    cplex2.Param.qpmethod.Cur = 6; % concurrent algorithm 
    cplex2.Param.barrier.crossover.Cur = 1; % enable crossover 
    cplex2.DisplayFunc = []; % disable output to screen 
    cplex2.solve();
    
    if (strcmp(cplex2.Solution.statusstring,'infeasible') == 1)
        % if no solution can be obtained during financial crisis, keep the
        % portfolio unchanged
        x_optimal = x_init;
        cash_optimal = cash_init;
    else
        solution = cplex2.Solution.x; %21*1
        w_maxSharp = solution(1:20,:) / solution(21,:); %20*1
        allocated_money = w_maxSharp * total_money; %20*1
        x_optimal = floor(allocated_money'./ cur_prices(end,:))'; %20*1
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
end
