function [pearsonsCorrelation upperStdOfPearsonsCorrelation lowerStdOfPearsonsCorrelation]= correlationFromFishersZ(fishersZSimilarity, stdOfFishersZSimilarity)

pearsonsCorrelation = (exp(2 * fishersZSimilarity) - 1) ./ (exp(2 * fishersZSimilarity) + 1);

if nargin > 1 && nargout > 1    
    fishersZSimilarityPlusStd = fishersZSimilarity + stdOfFishersZSimilarity;
    fishersZSimilarityMinusStd = fishersZSimilarity + stdOfFishersZSimilarity;
    
    upperStdOfPearsonsCorrelation = ((exp(2 * fishersZSimilarityPlusStd) - 1) ./ (exp(2 * fishersZSimilarityPlusStd) + 1)) - pearsonsCorrelation;
    lowerStdOfPearsonsCorrelation = pearsonsCorrelation - ((exp(2 * fishersZSimilarityMinusStd) - 1) ./ (exp(2 * fishersZSimilarityMinusStd) + 1));
end;
