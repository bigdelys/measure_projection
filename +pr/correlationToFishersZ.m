function fishersZSimilarity = correlationToFishersZ(pearsonsRCorrelation)
% to prevent Inf and Nans
maxAlowed = 0.99999;
pearsonsRCorrelation(pearsonsRCorrelation > maxAlowed) = maxAlowed;

fishersZSimilarity = 0.5 * (log(1+pearsonsRCorrelation) - log(1-pearsonsRCorrelation));
