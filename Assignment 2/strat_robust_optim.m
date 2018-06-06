function [x_optimal, cash_optimal] = strat_robust_optim(x_init, cash_init, mu, Q, cur_prices)

% 20 stocks
n = 20;
% compute the total asset 
total_money = cur_prices * x_init + cash_init;

% Define initial portfolio
w0 = cur_prices' .* x_init / total_money;

% Bounds on variables
lb_rMV = zeros(n,1);
ub_rMV = inf*ones(n,1);

% Required portfolio robustness
var_matr = diag(diag(Q));

% Target portfolio return estimation error is return estimation error of 1/n portfolio
rob_init = w0' * var_matr * w0; % return estimation error of initial portfolio
rob_bnd = rob_init; % target return estimation error

% Compute minimum variance portfolio
cplex_minVar = Cplex('MinVar');
cplex_minVar.addCols(zeros(1,n)', [], lb_rMV, ub_rMV);
cplex_minVar.addRows(1, ones(1,n), 1);
cplex_minVar.Model.Q = 2*Q;
cplex_minVar.Param.qpmethod.Cur = 6;
cplex_minVar.DisplayFunc = []; % disable output to screen 
cplex_minVar.solve();
cplex_minVar.Solution;
w_minVar = cplex_minVar.Solution.x; % asset weights
ret_minVar = dot(mu, w_minVar);
var_minVar = w_minVar' * Q * w_minVar;
rob_minVar = w_minVar' * var_matr * w_minVar;

% Target portfolio return is return of minimum variance portfolio
Portf_Retn = ret_minVar;

% Formulate and solve robust mean-variance problem
% Objective function
f_rMV  = zeros(n,1);
% Constraints
A_rMV  = sparse([  mu';
                 ones(1,n)]);
lhs_rMV = [Portf_Retn; 1];
rhs_rMV = [inf; 1];
% Initialize CPLEX environment
cplex_rMV = Cplex('Robust_MV');
% Add objective function and variable bounds
cplex_rMV.addCols(f_rMV, [], lb_rMV, ub_rMV);
% Add constraints
cplex_rMV.addRows(lhs_rMV, A_rMV, rhs_rMV);
% Add quadratic objective
cplex_rMV.Model.Q = 2*Q;
% Add quadratic constraint on return estimation error (robustness constraint)
Qq_rMV = var_matr;
cplex_rMV.addQCs(zeros(size(f_rMV)), Qq_rMV, 'L', rob_bnd, {'qc_robust'});
% Set CPLEX parameters
cplex_rMV.Param.threads.Cur = 4;
cplex_rMV.Param.timelimit.Cur = 60;
cplex_rMV.Param.barrier.qcpconvergetol.Cur = 1e-12; % solution tolerance
cplex_rMV.DisplayFunc = []; % disable output to screen 
cplex_rMV.solve();   
cplex_rMV.Solution;
    
if(isfield(cplex_rMV.Solution, 'x'))
    w_rMV = cplex_rMV.Solution.x;
    card_rMV = nnz(w_rMV);
    ret_rMV  = dot(mu, w_rMV);
    var_rMV = w_rMV' * Q * w_rMV;
    rob_rMV = w_rMV' * var_matr * w_rMV;
end    
 
% Round near-zero portfolio weights
w_rMV_nonrnd = w_rMV;
w_rMV(find(w_rMV<=1e-6)) = 0;
w_rMV = w_rMV / sum(w_rMV);

allocated_money = w_rMV * total_money; %20*1
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



