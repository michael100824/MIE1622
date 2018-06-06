function [callMC_Barrier_Knockin_Price_step, putMC_Barrier_Knockin_Price_step] = ...
     MC_barrier_knockin_price(S0, Sb, K, T, r, mu, sigma, numSteps, numPaths)
    
    % the option becomes a standard European option if the barrier was 
    % crossed some time before expiration.
    
    paths = zeros(numSteps+1, numPaths);
    dT = T/numSteps;
    paths(1,:) = S0;
    
     % Generate paths
    for iPath = 1:numPaths
        for iStep = 1:numSteps
               paths(iStep+1, iPath) = paths(iStep, iPath) * exp((mu - 0.5*sigma^2)*dT + sigma*sqrt(dT)*normrnd(0,1));                   
        end
    end
    
    check = sum(paths>= Sb);
    
    for iPath = 1:numPaths
        if check(iPath) > 0
            call(iPath,1) = max(paths(numSteps+1,iPath) - K, 0) * exp(-r*T);
            put(iPath,1) = max(K - paths(numSteps+1,iPath), 0) * exp(-r*T);
        else
            call(iPath,1) = 0;
            put(iPath,1) = 0;
        end
    end

    callMC_Barrier_Knockin_Price_step = mean(call);
    putMC_Barrier_Knockin_Price_step = mean(put);

end

