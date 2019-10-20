function groupSignificance = calculate_group_significance_based_on_pairwise_similarity(groupId, similarity, numberOfPermutationsOrSurrogateIdMatrix, neighborhoodWeight, allowRepetitionInPermutation)
% calculate the significance of group labels for a given pairwise similarity matrix.
% groupSignificance = calculate_group_significance_based_on_pairwise_similarity(groupId, similarity, numberOfPermutationsOrSurrogateIdMatrix, allowRepetitionInPermutation)

if nargin<3
    numberOfPermutationsOrSurrogateIdMatrix = 5000;
end;

if nargin<4
    neighborhoodWeight = [];
end;

if nargin<5
    allowRepetitionInPermutation = true;
end;

% if numberOfPermutationsOrSurrogateIdMatrix is just a number, create surrogate group id based on
% it, otherwise, it is assumed to be a matrix containing surrogate group ids itself.
if numel(numberOfPermutationsOrSurrogateIdMatrix)  == 1
    surrogateGroupIds = create_surrogate_group_ids(groupId, numberOfPermutationsOrSurrogateIdMatrix, [], allowRepetitionInPermutation);
else
    surrogateGroupIds = numberOfPermutationsOrSurrogateIdMatrix;
end;

for i = 1:2
    numberOfGroupMembers(i) = sum(groupId == i);
    insideGroupMeanPairwiseSimilarity(i) = weighted_similarity_mean(groupId == i, groupId == i);
end;

crossGroupsMeanPairwiseSimilarity= weighted_similarity_mean(groupId == 1, groupId == 2);

for permutationNumber = 1:size(surrogateGroupIds, 1)
    
    for i = 1:2
        surrogateInsideGroupMeanPairwiseSimilarity(permutationNumber,i) = weighted_similarity_mean(surrogateGroupIds(permutationNumber,:) == i, surrogateGroupIds(permutationNumber,:) == i);
    end;
    
    surrogateCrossGroupsMeanPairwiseSimilarity(permutationNumber) = weighted_similarity_mean(surrogateGroupIds(permutationNumber,:) == 1, surrogateGroupIds(permutationNumber,:) == 2);
end;

for i = 1:2
    groupInsideVsOutsideMeanPairwiseSimilarityDifference(i) = insideGroupMeanPairwiseSimilarity(i) - crossGroupsMeanPairwiseSimilarity;
    
    groupSignificance(i) = sum(surrogateInsideGroupMeanPairwiseSimilarity(:,i)' - surrogateCrossGroupsMeanPairwiseSimilarity > groupInsideVsOutsideMeanPairwiseSimilarityDifference(i)) / size(surrogateGroupIds, 1);
end;

% make sure p-values are higher than 1/ number of permutations (and not equal to zero)
groupSignificance = max(groupSignificance, (1 / numberOfPermutationsOrSurrogateIdMatrix) - eps);

    function weightedSimilarityMean = weighted_similarity_mean(ids1, ids2)
        if isempty(neighborhoodWeight)
            weightedSimilarityMean = mean(mean(similarity(ids1, ids2)));
        else
            sumNeighborhoodWeight = sum(sum(neighborhoodWeight(ids1, ids2)));
            weightedSimilarityMean = sum(sum(similarity(ids1, ids2) .* neighborhoodWeight(ids1, ids2))) / sumNeighborhoodWeight;
        end;
    end

end
