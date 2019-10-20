function fishersZSimilarity = fishersZfromCorrelation(pearsonsRCorrelation)
% to prevent Inf and Nans
maxAlowed = 0.99999;
pearsonsRCorrelation(pearsonsRCorrelation > maxAlowed) = maxAlowed;

% since nans usually happen by correlating two zero patterns
pearsonsRCorrelation(isnan(pearsonsRCorrelation)) = 0;

fishersZSimilarity = 0.5 * (log(1+pearsonsRCorrelation) - log(1-pearsonsRCorrelation));
