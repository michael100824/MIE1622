clear all;
clc
format long;

Nout  = 100000; % number of out-of-sample scenarios
Nin   = 5000;   % number of in-sample scenarios
Ns    = 5;      % number of idiosyncratic scenarios for each systemic

C = 8;          % number of credit states

% Filename to save out-of-sample scenarios
filename_save_out  = 'scen_out';

% Read and parse instrument data
instr_data = dlmread('instrum_data.csv', ',');
instr_id   = instr_data(:,1);           % ID
driver     = instr_data(:,2);           % credit driver
beta       = instr_data(:,3);           % beta (sensitivity to credit driver)
recov_rate = instr_data(:,4);           % expected recovery rate
value      = instr_data(:,5);           % value
prob       = instr_data(:,6:6+C-1);     % credit-state migration probabilities (default to A)
exposure   = instr_data(:,6+C:6+2*C-1); % credit-state migration exposures (default to  A)
retn       = instr_data(:,6+2*C);       % market returns

K = size(instr_data, 1); % number of  counterparties

% Read matrix of correlations for credit drivers
rho = dlmread('credit_driver_corr.csv', '\t');
sqrt_rho = (chol(rho))'; % Cholesky decomp of rho (for generating correlated Normal random numbers)

disp('======= Credit Risk Model with Credit-State Migrations =======')
disp('============== Monte Carlo Scenario Generation ===============')
disp(' ')
disp(' ')
disp([' Number of out-of-sample Monte Carlo scenarios = ' int2str(Nout)])
disp([' Number of in-sample Monte Carlo scenarios = ' int2str(Nin)])
disp([' Number of counterparties = ' int2str(K)])
disp(' ')

% Find credit-state for each counterparty
% 8 = AAA, 7 = AA, 6 = A, 5 = BBB, 4 = BB, 3 = B, 2 = CCC, 1 = default
[Ltemp, CS] = max(prob, [], 2); % to figure out the original credit state, CS is the position
clear Ltemp

% Account for default recoveries
exposure(:, 1) = (1-recov_rate) .* exposure(:, 1); % estimated loss

% Compute credit-state boundaries
CS_Bdry = norminv( cumsum(prob(:,1:C-1), 2) ); %credit boundary

% -------- Insert your code here -------- %
Ndriver = length(rho); % 50 credit drivers and K(100) counterparties

if(~exist('scenarios_out.mat','file'))
    
    % -------- Insert your code here -------- %
    % define parameter y for 100000 scenarios and 50 drivers which is a 
    % 100000*50 matrix
    y = zeros(Nout,Ndriver); 
    % define creditworthiness index for 10000 scenarios and 100 counterparties
    % which is a 10000*100 matrix
    w = zeros(Nout,K); 
    % define the credit state to be in the next year for 10000 scenarios 
    % and 100 counterparties which is a 10000*100 matrix
    cs_to_be = zeros(Nout,K);
    % define parameter z for each counterparty which is a 100*1 vector
    z = randn(K,1);
    % define loss for 10000 scenarios and 100 counterparties
    % which is a 10000*100 matrix
    Losses_out = zeros(Nout,K);

    for s = 1:Nout % simulate 100000 scenarios 
        normal_random_vector = randn(Ndriver,1);
        y(s,:) = (sqrt_rho * normal_random_vector)';
        for k = 1:K % simulate 100 counterparties
        % -------- Insert your code here -------- %
        % Calculated out-of-sample losses (100000 x 100)
            % find the corresponding credit driver for counterparty k
            cd = driver(k);
            % calculate creditworthiness
            w(s,k) = beta(k) * y(s,cd) + sqrt(1-beta(k)^2) * z(k);
            temp = [w(s,k) CS_Bdry(k,:)];
            temp = sort(temp);
            cs_index = find(temp == w(s,k));
            cs_to_be(s,k) = cs_index;
            Losses_out(s,k) = exposure(k,cs_index);
        end
    end
    
    save('scenarios_out', 'Losses_out')
else
    load('scenarios_out', 'Losses_out')
end

% Normal approximation computed from out-of-sample scenarios
mu_l = mean(Losses_out)'; % calculate mean of counterparty k in different scenarios
var_l = cov(Losses_out); % calculate covariance

% Compute portfolio weights
% portf 1: equal value (dollar amount) is invested in each of 100 bonds;
% portf 2: one unit invested in each of 100 bonds;
portf_v = sum(value);     % portfolio value
w0{1} = value / portf_v;  % asset weights (portfolio 1)
w0{2} = ones(K, 1) / K;   % asset weights (portfolio 2)
x0{1} = (portf_v ./ value) .* w0{1};  % asset units (portfolio 1)
x0{2} = (portf_v ./ value) .* w0{2};  % asset units (portfolio 2)

% Quantile levels (99%, 99.9%)
alphas = [0.99 0.999];

Losses_out_wtd{1}=sort(Losses_out*x0{1}); % total loss for 10000 scenarios using port 1
Losses_out_wtd{2}=sort(Losses_out*x0{2}); % total loss for 10000 scenarios using port 2

% Compute VaR and CVaR (non-Normal and Normal) for 100000 scenarios
for(portN = 1:2)
    for(q=1:length(alphas))
        alf = alphas(q);
        % -------- Insert your code here -------- %
        VaRout(portN,q)  = Losses_out_wtd{portN}(ceil(Nout*alf));
        VaRinN(portN,q)  = mean(Losses_out_wtd{portN}) + norminv(alf,0,1)*std(Losses_out_wtd{portN});
        CVaRout(portN,q) = (1/(Nout*(1-alf))) * ( (ceil(Nout*alf)-Nout*alf) * VaRout(portN,q)+ sum(Losses_out_wtd{portN}(ceil(Nout*alf)+1:Nout)));
        CVaRinN(portN,q) = mean(Losses_out_wtd{portN}) + (normpdf(norminv(alf,0,1))/(1-alf))*std(Losses_out_wtd{portN});
        % -------- Insert your code here -------- %        
    end
end

% Perform 100 trials
N_trials = 100;
for(tr=1:N_trials)
    
    % Monte Carlo approximation 1

    % -------- Insert your code here -------- %
    i = 0;
    for s = 1:ceil(Nin/Ns) % systemic scenarios s = 1:1000
        % -------- Insert your code here -------- %
        normal_random_vector = randn(Ndriver,1);
        y_inMC1(s,:) = (sqrt_rho * normal_random_vector)';
        for si = 1:Ns % idiosyncratic scenarios for each systemic si = 1:5
            % -------- Insert your code here -------- %
            z_inMC1{s,si} = randn(K,1);
         % Calculated losses for MC1 approximation (5000 x 100)
            for k = 1:K
             % find the corresponding credit driver for counterparty k
                    cd = driver(k);
                    % calculate creditworthiness
                    w_inMC1{s,si}(k) = beta(k) * y_inMC1(s,cd) + sqrt(1-beta(k)^2) * z_inMC1{s,si}(k);
                    temp_inMC1 = [w_inMC1{s,si}(k) CS_Bdry(k,:)];
                    temp_inMC1 = sort(temp_inMC1);
                    cs_index = find(temp_inMC1 == w_inMC1{s,si}(k));
                    cs_to_be_inMC1{s,si}(k) = cs_index;
                    Losses_inMC1_prep{s,si}(k) = exposure(k,cs_index);
            end
            i = i + 1;
            Losses_inMC1(i,:) = Losses_inMC1_prep{s,si};
        end
    end
    
   
    % Losses_inMC1
    
    % Monte Carlo approximation 2
    
    % -------- Insert your code here -------- %
    z_inMC2 = randn(K,1);
    for s = 1:Nin % systemic scenarios (1 idiosyncratic scenario for each systemic)
        % -------- Insert your code here -------- %
        normal_random_vector = randn(Ndriver,1);
        y_inMC2(s,:) = (sqrt_rho * normal_random_vector)';
        for k = 1:K % simulate 100 counterparties
        % -------- Insert your code here -------- %
            % Calculated losses for MC2 approximation (5000 x 100)
            cd = driver(k);
            % calculate creditworthiness
            w_inMC2(s,k) = beta(k) * y_inMC2(s,cd) + sqrt(1-beta(k)^2) * z_inMC2(k);
            temp_inMC2 = [w_inMC2(s,k) CS_Bdry(k,:)];
            temp_inMC2 = sort(temp_inMC2);
            cs_index = find(temp_inMC2 == w_inMC2(s,k));
            cs_to_be_inMC2(s,k) = cs_index;
            Losses_inMC2(s,k) = exposure(k,cs_index);
        end
    end
       
       
       % Compute VaR and CVaR
    for(portN = 1:2)
        for(q=1:length(alphas))
            alf = alphas(q);
            % -------- Insert your code here -------- %            
            % Compute portfolio loss 
            % Change the original code from portf_loss_inMC1{portN} ot portf_loss_inMC1{tr,portN}
            portf_loss_inMC1{tr,portN} = sort(Losses_inMC1*x0{portN}); 
            portf_loss_inMC2{tr,portN} = sort(Losses_inMC2*x0{portN});
            mu_MC1 = mean(Losses_inMC1)';
            var_MC1 = cov(Losses_inMC1);
            mu_MC2 = mean(Losses_inMC2)';
            var_MC2 = cov(Losses_inMC2);
            % Compute portfolio mean loss mu_p_MC1 and portfolio standard deviation of losses sigma_p_MC1
            mu_p_MC1 = mu_MC1'*x0{portN};
            sigma_p_MC1 = std(portf_loss_inMC1{tr,portN});
            % Compute portfolio mean loss mu_p_MC2 and portfolio standard deviation of losses sigma_p_MC2
            mu_p_MC2 = mu_MC2'*x0{portN};
            sigma_p_MC2 = std(portf_loss_inMC2{tr,portN});
            % Compute VaR and CVaR for the current trial     
            VaRinMC1{portN,q}(tr) = portf_loss_inMC1{portN}(ceil(Nin*alf));
            VaRinMC2{portN,q}(tr) = portf_loss_inMC2{portN}(ceil(Nin*alf));
            VaRinN1{portN,q}(tr) = mean(portf_loss_inMC1{portN}) + norminv(alf,0,1)*std(portf_loss_inMC1{portN});
            VaRinN2{portN,q}(tr) = mean(portf_loss_inMC2{portN}) + norminv(alf,0,1)*std(portf_loss_inMC2{portN});
            CVaRinMC1{portN,q}(tr) = (1/(Nin*(1-alf))) * ( (ceil(Nin*alf)-Nin*alf) * VaRinMC1{portN,q}(tr)+ sum(portf_loss_inMC1{portN}(ceil(Nin*alf)+1:Nin)));
            CVaRinMC2{portN,q}(tr) = (1/(Nin*(1-alf))) * ( (ceil(Nin*alf)-Nin*alf) * VaRinMC2{portN,q}(tr)+ sum(portf_loss_inMC2{portN}(ceil(Nin*alf)+1:Nin)));
            CVaRinN1{portN,q}(tr) = mean(portf_loss_inMC1{portN}) + (normpdf(norminv(alf,0,1))/(1-alf))*std(portf_loss_inMC1{portN});
            CVaRinN2{portN,q}(tr) = mean(portf_loss_inMC2{portN}) + (normpdf(norminv(alf,0,1))/(1-alf))*std(portf_loss_inMC2{portN});
            % -------- Insert your code here -------- %
        end
    end
end

% Display portfolio VaR and CVaR 
for(portN = 1:2)
    fprintf('\nPortfolio %d:\n\n', portN)    
     for(q=1:length(alphas))
        alf = alphas(q);
        fprintf('Out-of-sample: VaR %4.1f%% = $%6.2f, CVaR %4.1f%% = $%6.2f\n', 100*alf, VaRout(portN,q), 100*alf, CVaRout(portN,q))
        fprintf('In-sample MC1: VaR %4.1f%% = $%6.2f, CVaR %4.1f%% = $%6.2f\n', 100*alf, mean(VaRinMC1{portN,q}), 100*alf, mean(CVaRinMC1{portN,q}))
        fprintf('In-sample MC2: VaR %4.1f%% = $%6.2f, CVaR %4.1f%% = $%6.2f\n', 100*alf, mean(VaRinMC2{portN,q}), 100*alf, mean(CVaRinMC2{portN,q}))
        fprintf(' In-sample No: VaR %4.1f%% = $%6.2f, CVaR %4.1f%% = $%6.2f\n', 100*alf, VaRinN(portN,q), 100*alf, CVaRinN(portN,q))
        fprintf(' In-sample N1: VaR %4.1f%% = $%6.2f, CVaR %4.1f%% = $%6.2f\n', 100*alf, mean(VaRinN1{portN,q}), 100*alf, mean(CVaRinN1{portN,q}))
        fprintf(' In-sample N2: VaR %4.1f%% = $%6.2f, CVaR %4.1f%% = $%6.2f\n\n', 100*alf, mean(VaRinN2{portN,q}), 100*alf, mean(CVaRinN2{portN,q}))
     end
end


%%
% Plot results
% -------- Insert your code here -------- %
x0 = 10;
y0 = 10;
width = 1000;
height = 400;
% plot portfolio 1 out-of-sample 
figure(1);
set(gcf,'color', 'white','units','points','position',[x0,y0,width,height]);
[frequencyCounts, binLocations] = hist(Losses_out_wtd{1}, 100);
bar(binLocations, frequencyCounts);
hold on;
% 99% VaR
line([VaRout(1,1) VaRout(1,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99.9% VaR
line([VaRout(1,2) VaRout(1,2)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99% CVaR
line([CVaRout(1,1) CVaRout(1,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99.9% CVaR
line([CVaRout(1,2) CVaRout(1,2)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;

normf = ( 1/(std(Losses_out_wtd{1})*sqrt(2*pi)) ) * exp( -0.5*((binLocations-mean(Losses_out_wtd{1}))/std(Losses_out_wtd{1})).^2 );
normf = normf * sum(frequencyCounts)/sum(normf);
plot(binLocations, normf, 'r', 'LineWidth', 1); hold on;

text(0.98*VaRout(1,1), max(frequencyCounts)/1.9, {'VaR','99%'})
text(0.98*VaRout(1,2), max(frequencyCounts)/1.9, {'VaR','99.9%'})
text(0.98*CVaRout(1,1), max(frequencyCounts)/1.9, {'CVaR','99%'})
text(0.98*CVaRout(1,2), max(frequencyCounts)/1.9, {'CVaR','99.9%'})
hold off;
title('True Distribution of Portfolio 1 (out of sample)')
xlabel('Credit-State Migration Exposures')
ylabel('Frequency')


% plot portfolio 2 out-of-sample 
figure(2);
set(gcf,'color', 'white','units','points','position',[x0,y0,width,height]);
[frequencyCounts, binLocations] = hist(Losses_out_wtd{2}, 100);
bar(binLocations, frequencyCounts);
hold on;
% 99% VaR
line([VaRout(2,1) VaRout(2,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99.9% VaR
line([VaRout(2,2) VaRout(2,2)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99% CVaR
line([CVaRout(2,1) CVaRout(2,1)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99.9% CVaR
line([CVaRout(2,2) CVaRout(2,2)], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;

normf = ( 1/(std(Losses_out_wtd{2})*sqrt(2*pi)) ) * exp( -0.5*((binLocations-mean(Losses_out_wtd{2}))/std(Losses_out_wtd{2})).^2 );
normf = normf * sum(frequencyCounts)/sum(normf);
plot(binLocations, normf, 'r', 'LineWidth', 1); hold on;

text(0.98*VaRout(2,1), max(frequencyCounts)/1.9, {'VaR','99%'})
text(0.98*VaRout(2,2), max(frequencyCounts)/1.9, {'VaR','99.9%'})
text(0.98*CVaRout(2,1), max(frequencyCounts)/1.9, {'CVaR','99%'})
text(0.98*CVaRout(2,2), max(frequencyCounts)/1.9, {'CVaR','99.9%'})
hold off;
title('True Distribution of Portfolio 2 (out of sample)')
xlabel('Credit-State Migration Exposures')
ylabel('Frequency')

%% MC1
% plot portfolio 1 in-of-sample 

% calculate superposition of each measurement
VaRinMC1_p1_99 = mean(VaRinMC1{1,1});
VaRinMC1_p1_999 = mean(VaRinMC1{1,2});
CVaRinMC1_p1_99 = mean(CVaRinMC1{1,1});
CVaRinMC1_p1_999 = mean(CVaRinMC1{1,2});

% calculate superposition of loss
for i = 1:100
    superposition_loss_p1_MC1_i = portf_loss_inMC1{i,1} .* 1/100;
    if i < 2
        superposition_loss_p1_MC1 = zeros(5000,1) + superposition_loss_p1_MC1_i;
    else 
        superposition_loss_p1_MC1 = superposition_loss_p1_MC1 + superposition_loss_p1_MC1_i;
    end
end
    
figure(3);
set(gcf,'color', 'white','units','points','position',[x0,y0,width,height]);
[frequencyCounts, binLocations] = hist(superposition_loss_p1_MC1, 100);
bar(binLocations, frequencyCounts);
hold on;
% 99% VaR
line([VaRinMC1_p1_99 VaRinMC1_p1_99], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99.9% VaR
line([VaRinMC1_p1_999 VaRinMC1_p1_999], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99% CVaR
line([CVaRinMC1_p1_99 CVaRinMC1_p1_99], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99.9% CVaR
line([CVaRinMC1_p1_999 CVaRinMC1_p1_999], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;

normf = ( 1/(std(superposition_loss_p1_MC1)*sqrt(2*pi)) ) * exp( -0.5*((binLocations-mean(superposition_loss_p1_MC1))/std(superposition_loss_p1_MC1)).^2 );
normf = normf * sum(frequencyCounts)/sum(normf);
plot(binLocations, normf, 'r', 'LineWidth', 1);
hold on;

text(0.98*VaRinMC1_p1_99, max(frequencyCounts)/1.9, {'VaR','99%'})
text(0.98*VaRinMC1_p1_999, max(frequencyCounts)/1.9, {'VaR','99.9%'})
text(0.98*CVaRinMC1_p1_99, max(frequencyCounts)/1.9, {'CVaR','99%'})
text(0.98*CVaRinMC1_p1_999, max(frequencyCounts)/1.9, {'CVaR','99.9%'})
hold off;
title('Distribution of Portfolio 1 (Monte Carlo approximation 1)')
xlabel('Credit-State Migration Exposures')
ylabel('Frequency')

% plot portfolio 2 in-of-sample
VaRinMC1_p2_99 = mean(VaRinMC1{2,1});
VaRinMC1_p2_999 = mean(VaRinMC1{2,2});
CVaRinMC1_p2_99 = mean(CVaRinMC1{2,1});
CVaRinMC1_p2_999 = mean(CVaRinMC1{2,2});

% calculate superposition of loss
for i = 1:100
    superposition_loss_p2_MC1_i = portf_loss_inMC1{i,2} .* 1/100;
    if i < 2
        superposition_loss_p2_MC1 = zeros(5000,1) + superposition_loss_p2_MC1_i;
    else 
        superposition_loss_p2_MC1 = superposition_loss_p2_MC1 + superposition_loss_p2_MC1_i;
    end
end

figure(4);
set(gcf,'color', 'white','units','points','position',[x0,y0,width,height]);
[frequencyCounts, binLocations] = hist(superposition_loss_p2_MC1, 100);
bar(binLocations, frequencyCounts);
hold on;
% 99% VaR
line([VaRinMC1_p2_99 VaRinMC1_p2_99], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99.9% VaR
line([VaRinMC1_p2_999 VaRinMC1_p2_999], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99% CVaR
line([CVaRinMC1_p2_99 CVaRinMC1_p2_99], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99.9% CVaR
line([CVaRinMC1_p2_999 CVaRinMC1_p2_999], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;

normf = ( 1/(std(superposition_loss_p2_MC1)*sqrt(2*pi)) ) * exp( -0.5*((binLocations-mean(superposition_loss_p2_MC1))/std(superposition_loss_p2_MC1)).^2 );
normf = normf * sum(frequencyCounts)/sum(normf);
plot(binLocations, normf, 'r', 'LineWidth', 1);
hold on;

text(0.98*VaRinMC1_p2_99, max(frequencyCounts)/1.9, {'VaR','99%'})
text(0.98*VaRinMC1_p2_999, max(frequencyCounts)/1.9, {'VaR','99.9%'})
text(0.98*CVaRinMC1_p2_99, max(frequencyCounts)/1.9, {'CVaR','99%'})
text(0.98*CVaRinMC1_p2_999, max(frequencyCounts)/1.9, {'CVaR','99.9%'})
hold off;
title('Distribution of Portfolio 2 (Monte Carlo approximation 1)')
xlabel('Credit-State Migration Exposures')
ylabel('Frequency')
%% MC2
% plot portfolio 1 in-of-sample 

% calculate superposition of each measurement
VaRinMC2_p1_99 = mean(VaRinMC2{1,1});
VaRinMC2_p1_999 = mean(VaRinMC2{1,2});
CVaRinMC2_p1_99 = mean(CVaRinMC2{1,1});
CVaRinMC2_p1_999 = mean(CVaRinMC2{1,2});

% calculate superposition of loss
for i = 1:100
    superposition_loss_p1_MC2_i = portf_loss_inMC2{i,1} .* 1/100;
    if i < 2
        superposition_loss_p1_MC2 = zeros(5000,1) + superposition_loss_p1_MC2_i;
    else 
        superposition_loss_p1_MC2 = superposition_loss_p1_MC2 + superposition_loss_p1_MC2_i;
    end
end
    
figure(5);
set(gcf,'color', 'white','units','points','position',[x0,y0,width,height]);
[frequencyCounts, binLocations] = hist(superposition_loss_p1_MC2, 100);
bar(binLocations, frequencyCounts);
hold on;
% 99% VaR
line([VaRinMC2_p1_99 VaRinMC2_p1_99], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99.9% VaR
line([VaRinMC2_p1_999 VaRinMC2_p1_999], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99% CVaR
line([CVaRinMC2_p1_99 CVaRinMC2_p1_99], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99.9% CVaR
line([CVaRinMC2_p1_999 CVaRinMC2_p1_999], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;

normf = ( 1/(std(superposition_loss_p1_MC2)*sqrt(2*pi)) ) * exp( -0.5*((binLocations-mean(superposition_loss_p1_MC2))/std(superposition_loss_p1_MC2)).^2 );
normf = normf * sum(frequencyCounts)/sum(normf);
plot(binLocations, normf, 'r', 'LineWidth', 1);
hold on;

text(0.98*VaRinMC2_p1_99, max(frequencyCounts)/1.9, {'VaR','99%'})
text(0.98*VaRinMC2_p1_999, max(frequencyCounts)/1.9, {'VaR','99.9%'})
text(0.98*CVaRinMC2_p1_99, max(frequencyCounts)/1.9, {'CVaR','99%'})
text(0.98*CVaRinMC2_p1_999, max(frequencyCounts)/1.9, {'CVaR','99.9%'})
hold off;
title('Distribution of Portfolio 1 (Monte Carlo approximation 2)')
xlabel('Credit-State Migration Exposures')
ylabel('Frequency')

% plot portfolio 2 in-of-sample
VaRinMC2_p2_99 = mean(VaRinMC2{2,1});
VaRinMC2_p2_999 = mean(VaRinMC2{2,2});
CVaRinMC2_p2_99 = mean(CVaRinMC2{2,1});
CVaRinMC2_p2_999 = mean(CVaRinMC2{2,2});

% calculate superposition of loss
for i = 1:100
    superposition_loss_p2_MC2_i = portf_loss_inMC2{i,2} .* 1/100;
    if i < 2
        superposition_loss_p2_MC2 = zeros(5000,1) + superposition_loss_p2_MC2_i;
    else 
        superposition_loss_p2_MC2 = superposition_loss_p2_MC2 + superposition_loss_p2_MC2_i;
    end
end

figure(6);
% set(gcf, 'color', 'white');
set(gcf,'color', 'white','units','points','position',[x0,y0,width,height])
[frequencyCounts, binLocations] = hist(superposition_loss_p2_MC2, 100);
bar(binLocations, frequencyCounts);
hold on;
% 99% VaR
line([VaRinMC2_p2_99 VaRinMC2_p2_99], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99.9% VaR
line([VaRinMC2_p2_999 VaRinMC2_p2_999], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99% CVaR
line([CVaRinMC2_p2_99 CVaRinMC2_p2_99], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;
% 99.9% CVaR
line([CVaRinMC2_p2_999 CVaRinMC2_p2_999], [0 max(frequencyCounts)/2], 'Color', 'r', 'LineWidth', 1, 'LineStyle', '--');
hold on;

normf = ( 1/(std(superposition_loss_p2_MC2)*sqrt(2*pi)) ) * exp( -0.5*((binLocations-mean(superposition_loss_p2_MC2))/std(superposition_loss_p2_MC2)).^2 );
normf = normf * sum(frequencyCounts)/sum(normf);
plot(binLocations, normf, 'r', 'LineWidth', 1);
hold on;

text(0.98*VaRinMC2_p2_99, max(frequencyCounts)/1.9, {'VaR','99%'})
text(0.98*VaRinMC2_p2_999, max(frequencyCounts)/1.9, {'VaR','99.9%'})
text(0.98*CVaRinMC2_p2_99, max(frequencyCounts)/1.9, {'CVaR','99%'})
text(0.98*CVaRinMC2_p2_999, max(frequencyCounts)/1.9, {'CVaR','99.9%'})
hold off;
title('Distribution of Portfolio 2 (Monte Carlo approximation 2)')
xlabel('Credit-State Migration Exposures')
ylabel('Frequency')