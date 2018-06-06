function [x_optimal, cash_optimal] = strat_lever_equal_risk_contr(x_init, cash_init, mu, Q, cur_prices)

% take long 200% position in equal risk contributions portfolio double the
% total money
% global Q A_ineq A_eq 
global period yearindex
n = 20;

if yearindex == 2008
    r_rf = 0.045;
else
    r_rf = 0.025;
end

total_money = cur_prices * x_init + cash_init;
borrowed_fund = total_money;

if(period == 1)
    total_money = total_money + borrowed_fund;
else 
    total_money = cur_prices * x_init + cash_init;
end

period_interest = borrowed_fund * r_rf/6;

% Equality constraints
A_eq = ones(1,n);
b_eq = 1;

% Inequality constraints
A_ineq = [];
b_ineql = [];
b_inequ = [];
           
% Define initial portfolio as "1/n portfolio"
w0 = cur_prices' .* x_init / total_money;

options.lb = zeros(1,n);       % lower bounds on variables
options.lu = ones (1,n);       % upper bounds on variables
options.cl = [b_eq' b_ineql']; % lower bounds on constraints
options.cu = [b_eq' b_inequ']; % upper bounds on constraints

% Set the IPOPT options
options.ipopt.jac_c_constant        = 'yes';
options.ipopt.hessian_approximation = 'limited-memory';
options.ipopt.mu_strategy           = 'adaptive';
options.ipopt.tol                   = 1e-10;
options.ipopt.print_level           = 0;

% The callback functions
funcs.objective         = @computeObjERC;
funcs.constraints       = @computeConstraints;
funcs.gradient          = @computeGradERC;
funcs.jacobian          = @computeJacobian;
funcs.jacobianstructure = @computeJacobian;

% Run IPOPT
[wsol info] = ipopt(w0',funcs,options);

% Make solution a column vector
if(size(wsol,1)==1)
    w_erc = wsol';
else
    w_erc = wsol;
end

% Compute return, variance and risk contribution for the ERC portfolio
ret_ERC = dot(mu, w_erc);
var_ERC = w_erc'* Q *w_erc;
RC_ERC = (w_erc .* ( Q *w_erc )) / sqrt(w_erc'*Q*w_erc);

allocated_money = w_erc * total_money; %20*1
x_optimal = floor(allocated_money'./ cur_prices)'; %20*1
transaction = cur_prices * abs((x_optimal - x_init)) * 0.005;
cash_optimal = total_money - cur_prices * x_optimal - transaction - period_interest; %scalar
    
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
        cash_optimal = total_money - cur_prices * x_optimal - transaction - period_interest; %scalar
    end
end
