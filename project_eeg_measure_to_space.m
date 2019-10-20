function [linearizedProjectedMeasure dipoleDensity weightedSumOfCorrelationBetweenProjectedAndDipole] = project_eeg_measure_to_space(pos, dipoleLocation, linearizedMeasure, standardDeviationOfEstimatedDipoleLocation)

if nargin<4
    standardDeviationOfEstimatedDipoleLocation = 12;
end;

standardDeviationOfEstimatedErrorInDipoleLocationPowerTwo = standardDeviationOfEstimatedDipoleLocation ^ 2;

distanceToDipoles = sum((dipoleLocation - repmat(pos, size(dipoleLocation,1), 1))' .^2) .^ 0.5;

% pass distance to dipoles through a gaussian kernel with specified standard deviation.
gaussianPassedDistanceToDipoles = sqrt(1/(2 * pi * standardDeviationOfEstimatedErrorInDipoleLocationPowerTwo)) * exp(-distanceToDipoles.^2 / (2 * standardDeviationOfEstimatedErrorInDipoleLocationPowerTwo));

% mute the effet of very far ICs
effectiveIcs = gaussianPassedDistanceToDipoles > 0;%0.01;
gaussianPassedDistanceToDipoles(~effectiveIcs) = 0;

% normalize so weights have sum of 1
dipoleDensity = sum(gaussianPassedDistanceToDipoles);

if dipoleDensity == 0
    dipoloeWeights = gaussianPassedDistanceToDipoles;
else
   dipoloeWeights = gaussianPassedDistanceToDipoles / dipoleDensity;    
end;

linearizedProjectedMeasure = linearizedMeasure * dipoloeWeights';

%projectedMeasure = reshape(linearizedProjectedMeasure, size(erspdata,2),  size(erspdata,1))';

% std_plottf(STUDY.cluster(1).ersptimes, STUDY.cluster(1).erspfreqs, {projectedErsp}, 'titles', {'test'});

if nargout > 2 % if weight correlation sum is requested
    % calculate weighted correlations between dipole measure and the projected measure
    correlationBetweenProjectedAndDipole = correlation_between_a_vector_and_many_others(linearizedProjectedMeasure, linearizedMeasure(:,effectiveIcs));
    weightedSumOfCorrelationBetweenProjectedAndDipole = correlationBetweenProjectedAndDipole *  dipoloeWeights(effectiveIcs)';
end;


