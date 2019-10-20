function [optimalPolarity finalMinCost] = find_polarity_with_monte_carlo(scalpMapPairwiseAngle, varargin)
% [optimalPolarity minCost] = find_polarity_with_monte_carlo(scalpMapPairwiseAngle, numberOfFlipsToUse, maxNumberOfRuns)

inputOptions = finputcheck(varargin, ...
    { 'maxSteps'          'integer'   [0 Inf]   5000 ; ...
    'numberOfRestarts'  'integer'   [1 Inf]   3 ; ...
    'initialPolarities' 'integer'  []   [] });


% remove the diagonal
scalpMapPairwiseAngle = scalpMapPairwiseAngle - diag(diag(scalpMapPairwiseAngle));

numberOfIcs = size(scalpMapPairwiseAngle, 1);
w = -scalpMapPairwiseAngle;

bestCost = Inf;
for restartNumber = 1:inputOptions.numberOfRestarts    
    
    cost = inf(inputOptions.maxSteps, 1);
    minCost = inf(inputOptions.maxSteps, 1);
    
    randomstream =  RandStream('mt19937ar','Seed', restartNumber);
    
    if isempty(inputOptions.initialPolarities)
        bestSoFarPolarityVector = ones(numberOfIcs, 1);
    else
        bestSoFarPolarityVector = inputOptions.initialPolarities;
    end;
        
    scalpmapInnerProductAfterPolarity = w .* (bestSoFarPolarityVector * bestSoFarPolarityVector');
    
    lastNumberOfFlipsIncrease = 1;
    
    for i=1:inputOptions.maxSteps
        newPolarityVector = bestSoFarPolarityVector;
        
        
        if isempty(scalpmapInnerProductAfterPolarity)
            index = randomstream.randi(numberOfIcs);
        else % choose at random between swaps that would lead to a lower cost function
            swapAtIndexLeadsToLowerCost = find(sum(scalpmapInnerProductAfterPolarity) > 0);
            if isempty(swapAtIndexLeadsToLowerCost)
                break;
            end;
            
            randomIndex = randomstream.randi(length(swapAtIndexLeadsToLowerCost));
            index = swapAtIndexLeadsToLowerCost(randomIndex);
        end;
        
        newPolarityVector(index) = -bestSoFarPolarityVector(index);
        
        if size(w,1) > 2500 % after ~2500, the cost of in-memory-acess (second way of doing it) becomes larger than arithmical calculation (first way of doing it).,
            polarityMatrix = newPolarityVector * newPolarityVector';
            newScalpmapInnerProductAfterPolarity = w .* polarityMatrix;
            newCostTwoRandom = sum(sum(newScalpmapInnerProductAfterPolarity));
        else
            % instead of recalculating, just negate rows and columns
            newScalpmapInnerProductAfterPolarity = scalpmapInnerProductAfterPolarity;
            newScalpmapInnerProductAfterPolarity(index,:) = -newScalpmapInnerProductAfterPolarity(index,:);
            newScalpmapInnerProductAfterPolarity(:,index) = -newScalpmapInnerProductAfterPolarity(:,index);
            newCostTwoRandom = sum(sum(newScalpmapInnerProductAfterPolarity));
        end;
        
        if i>1 & newCostTwoRandom <= cost(i-1)
            bestSoFarPolarityVector = newPolarityVector;
            scalpmapInnerProductAfterPolarity = newScalpmapInnerProductAfterPolarity;
            cost(i) = newCostTwoRandom;
        else
            if i>1
                cost(i) = cost(i-1);
                fprintf('Warning: Something is probably wrong!');
            else % i == 1
                polarityMatrix = bestSoFarPolarityVector * bestSoFarPolarityVector';
                cost(i) = sum(sum(w .* polarityMatrix));
            end;
        end;
        
        minCost(i) = min(cost);
        
        numberOfStepsWithoutCostChange = i -  find(diff(minCost(lastNumberOfFlipsIncrease:i)), 1, 'last');
        if numberOfStepsWithoutCostChange > 3 * numberOfIcs
            % inputOptions.numberOfFlips = inputOptions.numberOfFlips + 1;
            % lastNumberOfFlipsIncrease = i;
            minCost(i+1:end) = [];
            fprintf('exit because of too long no change.\n');
            break;
        end;
        
    end;
    
    if min(minCost) < bestCost
        finalMinCost = minCost;
        optimalPolarity = bestSoFarPolarityVector;
        bestCost = min(minCost);
    end;
end;