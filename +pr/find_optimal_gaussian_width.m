function [optimalGaussianWidth meanPredictionSImilarity gaussianStdValues dipolePredictionSimilarity] = find_optimal_gaussian_width(dipoleAndPotentialMeasure, gaussianStdValues, normalizeInBrainDipoleDenisty, locationOrMeasure, headGrid)
% [optimalGaussianWidth meanPredictionSImilarity gaussianStdValues dipolePredictionSimilarity] = find_optimal_gaussian_width(dipoleAndMeasure, gaussianStdValues, normalizeInBrainDipoleDenisty, locationOrMeasure, headGrid)
if nargin < 2
    gaussianStdValues = 10:45;
end;
if nargin < 3
    normalizeInBrainDipoleDenisty = true;
end;

if nargin < 4
    if isprop(dipoleAndPotentialMeasure, 'linearizedMeasure')
        locationOrMeasure = 'measure';
    else % when there is only dipole but no measure, e.g. diople density smoothing   
        locationOrMeasure = 'location';
    end;
end;

if nargin < 5
    headGrid = pr.headGrid(8);
end;

useFisherZ = false;

dipolePredictionSimilarity = zeros(dipoleAndPotentialMeasure.numberOfDipoles, length(gaussianStdValues));
for gaussianStdCounter = 1:length(gaussianStdValues)
    
    switch locationOrMeasure 
        case 'location'
        projectionParameter = pr.projectionParameter(gaussianStdValues(gaussianStdCounter), Inf, normalizeInBrainDipoleDenisty);                
        [projectionMatrixForAll totalDipoleDenisty gaussianWeightMatrixForAll]= pr.meanProjection.getProjectionMatrixForArbitraryLocation(dipoleAndPotentialMeasure, projectionParameter, dipoleAndPotentialMeasure.location, headGrid);                
        
        gaussianWeightMatrixForAll = gaussianWeightMatrixForAll - diag(diag(gaussianWeightMatrixForAll)); % remove the contribution of density from each dipole to its location        
        gaussianWeightMatrixForAll(isnan(gaussianWeightMatrixForAll)) = 0;
        
        dipolePredictionSimilarity(:, gaussianStdCounter) = log(sum(gaussianWeightMatrixForAll)); % sum over densities of other dipoles at leave-one-out locations.
    case 'measure' % find optimal for dipoleAndMeasure based on the measure       
        
        
        % for test ?
        for i=1:size(dipoleAndPotentialMeasure.linearizedMeasure, 2)
        dipoleAndPotentialMeasure.linearizedMeasure(:,i) = dipoleAndPotentialMeasure.linearizedMeasure(:,i) / (sum(dipoleAndPotentialMeasure.linearizedMeasure(:,i).^2).^0.5);
        end;
        
        projectionParameter = pr.projectionParameter(gaussianStdValues(gaussianStdCounter), 3, normalizeInBrainDipoleDenisty);                
        [projectionMatrixForAll totalDipoleDenisty gaussianWeightMatrixForAll]= pr.meanProjection.getProjectionMatrixForArbitraryLocation(dipoleAndPotentialMeasure, projectionParameter, dipoleAndPotentialMeasure.location, headGrid);
        
        projectionMatrixForAll = projectionMatrixForAll - diag(diag(projectionMatrixForAll));
        projectionMatrixForAll = bsxfun(@times,projectionMatrixForAll, 1./sum(projectionMatrixForAll));
        projectionIntoLocation = dipoleAndPotentialMeasure.linearizedMeasure * projectionMatrixForAll;
        
        if useFisherZ
            dipolePredictionSimilarity(:, gaussianStdCounter) = pr.fishersZfromCorrelation(pr.correlation_of_columns(projectionIntoLocation, dipoleAndPotentialMeasure.linearizedMeasure));
        else % minimize residual variance (seem to not work as well as sum of Fisher Zs).
            projectionIntoLocation(isnan(projectionIntoLocation)) = 0;
            residualVariance(:, gaussianStdCounter) = sum((projectionIntoLocation - dipoleAndPotentialMeasure.linearizedMeasure).^2);
            %residualVariance(:, gaussianStdCounter) = sum((projectionIntoLocation - dipoleAndPotentialMeasure.linearizedMeasure).^2) ./ sum((dipoleAndPotentialMeasure.linearizedMeasure).^2);
            %residualVariance(:, gaussianStdCounter) = sum(abs(projectionIntoLocation - dipoleAndPotentialMeasure.linearizedMeasure));
            dipolePredictionSimilarity = -residualVariance;
        end;
    end;
end;

meanPredictionSImilarity = mean(dipolePredictionSimilarity);
[dummy id] = max(meanPredictionSImilarity);
optimalGaussianWidth = gaussianStdValues(id);

end

