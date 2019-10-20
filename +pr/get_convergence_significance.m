function [convergence convergenceSignificance randomPermutation]= get_convergence_significance(similarity, probabilityOnsubstrate, randomPermutation, varargin)

if nargin < 3
    numberOfPermutations = 2000;
    currentRandomStream = RandStream('mt19937ar','Seed',0);
    randomPermutation = zeros(numberOfPermutations, size(similarity,1));
    for permutationNumber = 1:numberOfPermutations
        randomPermutation(permutationNumber,:) = currentRandomStream.randi(size(similarity,1), 1, size(similarity,1)); % with repetition
    end;
else
    numberOfPermutations = size(randomPermutation,  1);
end;

probabilityIsNonZero = probabilityOnsubstrate > eps;
probabilityOnsubstrate = probabilityOnsubstrate(probabilityIsNonZero);

pairProbability = probabilityOnsubstrate * probabilityOnsubstrate';
pairProbability = pairProbability / sum(pairProbability(:));

convergence = squeeze(sum(sum(similarity(probabilityIsNonZero, probabilityIsNonZero) .* pairProbability, 1), 2));
surrogateConvergence = zeros(numberOfPermutations, 1);

for permutationNumber = 1:numberOfPermutations   
    permutationId = randomPermutation(permutationNumber,:);
    permutationId = permutationId(probabilityIsNonZero); % only choose non-zero indices to increase speed.
    
    surrogateConvergence(permutationNumber) = sum(sum(similarity(permutationId, permutationId) .* pairProbability, 1), 2);
end;

convergenceSignificance = mean(surrogateConvergence >= convergence);
convergenceSignificance = max(convergenceSignificance, 1/numberOfPermutations);