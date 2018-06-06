function [x_optimal, cash_optimal] = strat_min_variance(x_init, cash_init, mu, Q, cur_prices)
    % Add path to CPLEX
    addpath('/Applications/CPLEX_Studio128/cplex/matlab/x86-64_osx');

    % compute the total asset 
    total_money = cur_prices * x_init + cash_init;
    % 20 stocks 
    n = 20;

    % Optimization problem data
    % 0 <= wi <= inf
    lb = zeros(n,1);
    ub = inf*ones(n,1); 
    % sum(wi) = 1
    A = ones(1,n);
    bound = 1;

    % Compute minimum variance portfolio
    cplex1 = Cplex('min_Variance');
    % there is no linear part in obj function
    cplex1.addCols(zeros(n,1), [], lb, ub);
    cplex1.addRows(bound, A, bound);
    
    cplex1.Model.Q = 2*Q;
    cplex1.Param.qpmethod.Cur = 6; % concurrent algorithm 
    cplex1.Param.barrier.crossover.Cur = 1; % enable crossover 
    cplex1.DisplayFunc = []; % disable output to screen 
    cplex1.solve();

    w_minVar = cplex1.Solution.x; %20*1
    allocated_money = w_minVar * total_money; %20*1
    x_optimal = floor(allocated_money'./ cur_prices)'; %20*1
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