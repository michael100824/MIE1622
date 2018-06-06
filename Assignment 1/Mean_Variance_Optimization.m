clear all;
clc;

% Add path to CPLEX
% addpath('D:/CPLEX/CPLEX1263_x64/cplex/matlab/x64_win64');
addpath('/Applications/CPLEX_Studio128/cplex/matlab/x86-64_osx');

% Random data for 10 stocks
n = 10;
Q = randn(n);
Q = Q*Q'/1000; % covariance matrix
mu = rand(1,n)'/100; % expected return

% Optimization problem data
lb = zeros(n,1);
ub = inf*ones(n,1); A = ones(1,n);
b = 1;

% Compute minimum variance portfolio
cplex1 = Cplex('min_Variance');
% cplex1.Model.sense = 'minimize';
cplex1.addCols(zeros(n,1), [], lb, ub);
cplex1.addRows(b, A, b);
cplex1.Model.Q = 2*Q;
cplex1.Param.qpmethod.Cur = 6; % concurrent algorithm 
cplex1.Param.barrier.crossover.Cur = 1; % enable crossover 
cplex1.DisplayFunc = []; % disable output to screen 
cplex1.solve();

% Display minimum variance portfolio
w_minVar = cplex1.Solution.x;
var_minVar = w_minVar' * Q * w_minVar;
ret_minVar = mu' * w_minVar;
fprintf ('Minimum variance portfolio:\n');
fprintf ('Solution status = %s\n', cplex1.Solution.statusstring); fprintf ('Solution value = %f\n', cplex1.Solution.objval); fprintf ('Return = %f\n', sqrt(ret_minVar));
fprintf ('Standard deviation = %f\n\n', sqrt(var_minVar));

% Compute maximum return portfolio
cplex2 = Cplex('max_Return');
cplex2.Model.sense = 'maximize';
cplex2.addCols(mu, [], lb, ub);
cplex2.addRows(b, A, b);
cplex2.Param.lpmethod.Cur = 6; % concurrent algorithm 
cplex2.Param.barrier.crossover.Cur = 1; % enable crossover 
cplex2.DisplayFunc = []; % disable output to screen 
cplex2.solve();

% Display maximum return portfolio
w_maxRet = cplex2.Solution.x;
var_maxRet = w_maxRet' * Q * w_maxRet;
ret_maxRet = mu' * w_maxRet;
fprintf ('Maximum return portfolio:\n');
fprintf ('Solution status = %s\n', cplex2.Solution.statusstring); fprintf ('Solution value = %f\n', cplex2.Solution.objval); fprintf ('Return = %f\n', sqrt(ret_maxRet));
fprintf ('Standard deviation = %f\n\n', sqrt(var_maxRet));

% Target returns
targetRet = linspace(ret_minVar,ret_maxRet,20);
% Compute efficient frontier
cplex3 = Cplex('Efficient_Frontier');
cplex3.addCols(zeros(n,1), [], lb, ub);
cplex3.addRows(targetRet(1), mu', inf);
cplex3.addRows(b, A, b);
cplex3.Model.Q = 2*Q;
cplex3.Param.qpmethod.Cur = 6; % concurrent algorithm
cplex3.Param.barrier.crossover.Cur = 1; % enable crossover
cplex3.DisplayFunc = []; % disable output to screen
w_front = [];
for i=1:length(targetRet)
    cplex3.Model.lhs(1) = targetRet(i); cplex3.solve();
    w_front = [w_front cplex3.Solution.x]; 
    var_front(i) = w_front(:,i)' * Q * w_front(:,i); 
    ret_front(i) = mu' * w_front(:,i);
end
     % Plot efficient frontier
figure(1);
plot(sqrt(var_front), ret_front, 'k-', 'LineWidth', 3)
hold on;
plot(sqrt(var_minVar), ret_minVar, 'rd', 'MarkerSize', 6)
hold on;
plot(sqrt(var_maxRet), ret_maxRet, 'ms', 'MarkerSize', 6)
hold on;
plot(sqrt(diag(Q)), mu, 'b.', 'MarkerSize', 18)
xlabel('Standard deviation');
ylabel('Expected return');
title('Efficient Frontier')
legend('efficient frontier', 'minimum variance portfolio', 'maximum return portfolio', 'individual stocks')