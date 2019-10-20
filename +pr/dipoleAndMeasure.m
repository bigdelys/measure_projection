classdef dipoleAndMeasure < pr.dipole
    % holds a measure (e.g. ERP, ERSP...) in a linearized way.
    % the first dimension is the linearized version of the measure.
    % the second dimension of value is items (usually dipoles).
    properties
        linearizedMeasure = []; % N x M matrix, N is the given measure (ERP, ERSP...) in a linearized manner, M is the number of items (usually dipoles).               
        measureLabel = ''; % the text label describing the measure, for example 'ERSP' or 'ERP'. This is set in the child classes;
    end % properties    
    properties %(Constant = true)
        numberOfMeasureDimensions % this is 1 for ERP, Spec and other 1 dimensional measures, and 2 for ERP, ITC.
        % it does not change for a given measure, so it is Constant.
    end;    
    methods
        function obj = dipoleAndMeasure() % constructor
            obj = obj@pr.dipole();
        end;        
        
        function correlationSimilaity = getPairwiseCorrelationSimilarity(obj)
            correlationSimilaity = 1-squareform(pdist(double(obj.linearizedMeasure'), 'correlation'));            
        end;        
        
        function euclideanSimilaity = getPairwiseEuclideanSimilarity(obj) % could be negative as it is -euclidean distance
            euclideanSimilaity = -squareform(pdist(obj.linearizedMeasure'));
        end;        
        
        function estimatedMutualInformation = getPairwiseMutualInformationSimilarity(obj)          
            estimatedMutualInformation = pr.estimate_mutual_information_from_correlation(getPairwiseCorrelationSimilarity(obj));            
        end;        
        
        function estimatedMutualInformation = getPairwiseFishersZSimilarity(obj)
            estimatedMutualInformation = pr.fishersZfromCorrelation(getPairwiseCorrelationSimilarity(obj));
        end;
        
		function differenceSimilarity = getPairwiseScalarDifferenceSimilarity(obj)
          nDip = size(obj.linearizedMeasure,2);
          differenceSimilarity = -abs(ones(nDip,1)*obj.linearizedMeasure - obj.linearizedMeasure' * ones(1,nDip));
		  
		  % we need to make the minimum of this higher than zero since ocations further than ~2
		  % spatial Gaussian std. from more than two dipoles get zero 
		  
		  differenceSimilarity = differenceSimilarity - min(differenceSimilarity(:)) + 1000;
		  
        end;
		
%         ! this function has to be removed!
%         function [linearizedProjectedMeasure dipoleDensity] = projectTo(obj, position, standardDeviationOfEstimatedDipoleLocation)
%             % position is N x 3 array of location to which the projection should occur
%             % returns an L x N array for N projected positions.
%             if nargin<3
%                 standardDeviationOfEstimatedDipoleLocation = 12;
%             end;
%             
%             linearizedProjectedMeasure = zeros(size(obj.linearizedMeasure,1), size(position, 1));
%             dipoleDensity = zeros(1, size(position, 1));
%             
%             for i=1:size(position, 1)
%                 [linearizedProjectedMeasure(:,i) dipoleDensity(i)] = project_eeg_measure_to_space(position(i,:), obj.location, obj.linearizedMeasure, standardDeviationOfEstimatedDipoleLocation);
%             end;
%         end;
        
        
    end;
end