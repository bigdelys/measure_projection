function [sumWeightedSimilarityPvalue sumWeightedSimilarity] = calculate_measure_convergence_significance(similarity, dipoleLocation, headGrid, standardDeviationOfEstimatedDipoleLocation, numberOfPermutations, numberOfStandardDeviationsToTruncatedGaussaian, normalizeInBrainDipoleDenisty)
% whole function is not modev inside pr.meanProjection, so this function is obsolete.

if nargin<4
    standardDeviationOfEstimatedDipoleLocation = 12; % mm
end;

if nargin < 5
    numberOfPermutations = 500;
end;

if nargin < 6
    % number of standard deviations after which the Gaussian function is truncated
    numberOfStandardDeviationsToTruncatedGaussaian = 3;
end;

if nargin < 7
    normalizeInBrainDipoleDenisty = true;
end;

sumWeightedSimilarity = headGrid.xCube * 0;

standardDeviationOfEstimatedErrorInDipoleLocationPowerTwo = standardDeviationOfEstimatedDipoleLocation ^ 2;

similarity = similarity - diag(diag(similarity)); % remove ones on the diagonal


surrogateSumWeightedSimilarity = zeros(1, numberOfPermutations);
sumWeightedSimilarityPvalue = ones(size(headGrid.xCube));

clear randomPermutation;
for permutationNumber = 1:numberOfPermutations
    % randomPermutation(permutationNumber,:) = randperm(size(similarity,1)); % without repetition
    randomPermutation(permutationNumber,:) = randi(size(similarity,1), 1, size(similarity,1)); % with repetition
end;

if numberOfPermutations>0
    pr.progress('init'); % start the text based progress bar
end;

% whole function is not modev inside pr.meanProjection, so this function is obsolete.
% if normalizeInBrainDipoleDenisty
%     dipoleInBrainDensityNormalizationFactor = pr.meanProjection.calculateDipoleInBrainDensityNormalizationFactor(dipole, headGrid, standardDeviationOfEstimatedDipoleLocation, numberOfStandardDeviationsToTruncatedGaussaian);
% end;

for i=1:numel(headGrid.xCube)
    if headGrid.insideBrainCube(i)
        
        if numberOfPermutations>0 && mod(i,10) ==0
            %fprintf('Percent done = %d\n', round(100 * i / numel(headGrid.xCube)));
             pr.progress(i / numel(headGrid.xCube), sprintf('\npercent done %d/100',round(100*i / numel(headGrid.xCube))));
        end;
        
        pos = [headGrid.xCube(i) headGrid.yCube(i) headGrid.zCube(i)];
        distanceToDipoles = sum((dipoleLocation - repmat(pos, size(dipoleLocation,1), 1))' .^2) .^ 0.5;        
      
        % truncate the dipole denisty Gaussian at ~3 standard deviation
        dipoleWithNonzeroWeightIds = distanceToDipoles < (standardDeviationOfEstimatedDipoleLocation * numberOfStandardDeviationsToTruncatedGaussaian);
        
        if ~isempty(dipoleWithNonzeroWeightIds)
            
            % pass distance to dipoles through a gaussian kernel with specified standard deviation.
            gaussianPassedDistanceToDipoles = sqrt(1/(2 * pi * standardDeviationOfEstimatedErrorInDipoleLocationPowerTwo)) * exp(-distanceToDipoles(dipoleWithNonzeroWeightIds).^2 / (2 * standardDeviationOfEstimatedErrorInDipoleLocationPowerTwo));
            
            gaussianWeightMatrix = repmat(gaussianPassedDistanceToDipoles,length(gaussianPassedDistanceToDipoles),1);
 
            normalizationMatrix = gaussianWeightMatrix .* gaussianWeightMatrix';
            sumPairwiseWeights = sum(normalizationMatrix(:));
            
            normalizationMatrix = normalizationMatrix / sumPairwiseWeights;
            
            if any(normalizationMatrix ==0)
                keyboard;
            end;
            
            similarityWeightedByGauissian = similarity(dipoleWithNonzeroWeightIds, dipoleWithNonzeroWeightIds) .* normalizationMatrix;
            sumWeightedSimilarity(i) = sum(similarityWeightedByGauissian(:));
            
            % bootstapping with permutation
            for permutationNumber = 1:numberOfPermutations
                surrogateSimilarityWeightedByGauissian = similarity(randomPermutation(permutationNumber, dipoleWithNonzeroWeightIds), randomPermutation(permutationNumber, dipoleWithNonzeroWeightIds)) .* normalizationMatrix;
                surrogateSumWeightedSimilarity(permutationNumber) = sum(surrogateSimilarityWeightedByGauissian(:));
            end;
            
            sumWeightedSimilarityPvalue(i) = sum(surrogateSumWeightedSimilarity >= sumWeightedSimilarity(i)) / numberOfPermutations;
        end;
    end;
end;

if numberOfPermutations
    pause(.1);
    pr.progress('close'); % duo to some bug need a pause() before
    fprintf('\n');
end;

% we can only be sure that the significance is less than 1/numberOfPermutations
sumWeightedSimilarityPvalue = max(sumWeightedSimilarityPvalue, (1 / numberOfPermutations) - eps);