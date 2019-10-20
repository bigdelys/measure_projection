function [groupDensityDifferenceSignificance normalizedGroupDensityInNeighborhood]= calculate_group_density_difference_significance(groupId, gaussianPassedDistanceToNeighborhoodCenter, numberOfPermutationsOrSurrogateIdMatrix, allowRepetitionInPermutation)
% calculate the significance of group density difference between two groups in a given neighborhood 
% groupDensityDifferenceSignificance = calculate_group_density_difference_significance(groupId, gaussianPassedDistanceToNeighborhoodCenter, numberOfPermutationsOrSurrogateIdMatrix, allowRepetitionInPermutation)

if nargin < 3
    numberOfPermutationsOrSurrogateIdMatrix = 2000;
end;

% use repetition in permutation by default
if nargin < 4
    allowRepetitionInPermutation = true;
end;

% if numberOfPermutationsOrSurrogateIdMatrix is just a number, create surrogate group id based on
% it, otherwise, it is assumed to be a matrix containing surrogate group ids itself.
if numel(numberOfPermutationsOrSurrogateIdMatrix)  == 1
    surrogateGroupIds = create_surrogate_group_ids(groupId, numberOfPermutationsOrSurrogateIdMatrix, [], allowRepetitionInPermutation);
else
    surrogateGroupIds = numberOfPermutationsOrSurrogateIdMatrix;
end;

for i=1:2
    groupDensityInNeighborhood(i) = sum(gaussianPassedDistanceToNeighborhoodCenter(groupId == i));
    numberOfGroupMembers(i) = sum(groupId == i);
    
    % we should normalize by number of group members before calculating the difference
    normalizedGroupDensityInNeighborhood(i) = groupDensityInNeighborhood(i) / numberOfGroupMembers(i);
end;

groupDensityDifference = abs(normalizedGroupDensityInNeighborhood(2) - normalizedGroupDensityInNeighborhood(1));

for permutationNumber = 1:size(surrogateGroupIds, 1)

    % we need to calculate the actual number of members in surrogate
    % if surrogateGroupIds are created with subjectId option in create_surrogate_group_ids(),
    % the number of surrogate members is generally not equal to the number of actual group members
    % (because some data points are from subjects with no assigned group). 
    
    for i = 1:2
        numberOfSurrogateGroupMembers(i) = sum(surrogateGroupIds(permutationNumber,:) == i);
        surrogateGroupDensityInNeighborhood(i) = sum(gaussianPassedDistanceToNeighborhoodCenter(surrogateGroupIds(permutationNumber,:) == i));        
    end;
           
    surrogateGroupDensityDifference(permutationNumber) = abs((surrogateGroupDensityInNeighborhood(2)/ numberOfSurrogateGroupMembers(2)) - (surrogateGroupDensityInNeighborhood(1) / numberOfSurrogateGroupMembers(1)));    
    
end;

groupDensityDifferenceSignificance = sum(surrogateGroupDensityDifference > groupDensityDifference) / size(surrogateGroupIds, 1);
