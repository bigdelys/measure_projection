classdef representationalSimilarity
    properties
        similarity
        defaultSignificanceThreshold = 0.05;
        dipoleAndMeasure % witouth the data to save space
        regionLabel  % a cell aray containing labels of regions in which similarity has been calculated (e.g. anatomical labels)
    end
    methods
        function obj = representationalSimilarity(dipoleAndMeasure, conditionList, region, varargin)
            
            if nargin < 2 || isempty(conditionList)
                conditionList = dipoleAndMeasure.conditionLabel;
            end;
            
            if nargin < 3 || isempty(region) % if no region is specified, use anatomical regions
                anatomicalLabels = pr.regionOfInterestFromAnatomy.getAllanatomicalLabels;
                obj.regionLabel = anatomicalLabels;
            else
                % TO DO: implement RSA of a list of Domains.
            end;
            
            if numel(dipoleAndMeasure) == 1
                % place dipoleAndMeasure object witouth its mesure data into the object.
                obj.dipoleAndMeasure = dipoleAndMeasure;
                obj.dipoleAndMeasure.linearizedMeasure = [];
                
                % separate conditions and place in an array
                for conditionNumber = 1:length(conditionList)
                    conditionMeasureArray(conditionNumber) = dipoleAndMeasure.createSubsetForCondition(conditionList{conditionNumber});
                end;
            else % it must be an array of dipoleAndMeasure, each contaiing a condition
                obj.dipoleAndMeasure = dipoleAndMeasure(1);
                obj.dipoleAndMeasure.linearizedMeasure = [];
                
                conditionMeasureArray = dipoleAndMeasure;
            end;
                       
            anatomicalRegionSignificance= [];
            anatomicalRegionCorrelation= [];
            
            obj.similarity = zeros(length(anatomicalLabels), length(conditionMeasureArray), length(conditionMeasureArray));
            
            for anatomicalRegionId = 1:length(anatomicalLabels)
                
                % select the region to project into
                regionOfInterest = pr.regionOfInterestFromAnatomy(pr.headGrid, anatomicalLabels{anatomicalRegionId});
                
                % project values for each condition (of the whole study, from all subejcts) there
                locationCube = regionOfInterest.membershipProbabilityCube > 0.01;
                locationXyz = regionOfInterest.headGrid.getPosition(locationCube);
                projectionParameter = pr.projectionParameter;
                linearizedProjectedMeasureScoreCell = {};
                totalDipoleDenisty = [];
                
                for i = 1:length(conditionMeasureArray)
                    [projectionMatrix totalDipoleDenisty(i,:)]= pr.meanProjection.getProjectionMatrixForArbitraryLocation(conditionMeasureArray(i), projectionParameter, locationXyz, regionOfInterest.headGrid);
                    linearizedProjectedMeasure = conditionMeasureArray(i).linearizedMeasure * projectionMatrix;
                    
                    % calcuylate the z score (zero mean, std =1) of projected measure at each location to improve
                    % performance when calculating correlation
                    linearizedProjectedMeasure = bsxfun(@minus, linearizedProjectedMeasure,  mean(linearizedProjectedMeasure));
                    linearizedProjectedMeasure = bsxfun(@rdivide, linearizedProjectedMeasure,  std(linearizedProjectedMeasure));
                    
                    linearizedProjectedMeasureScoreCell{i} = linearizedProjectedMeasure;
                end;
                
                
                % calculate condition similarity
                
                for conditionId1 = 1:length(conditionMeasureArray)
                    for conditionId2 = 1:(conditionId1-1)
                        
                        % multiply dipole densities to form a joint probability of dipole being at each location
                        %jointProbabilityFromDipoleDensity = prod(totalDipoleDenisty([conditionId1 conditionId2],:));
                        
                        % for a single study maybe just using probability is better
                        jointProbabilityFromDipoleDensity = totalDipoleDenisty([conditionId1],:);
                        
                        % normalize to make a simplex
                        jointProbabilityFromDipoleDensity = jointProbabilityFromDipoleDensity / sum(jointProbabilityFromDipoleDensity);
                        
                        correlationSimilaity = sum((linearizedProjectedMeasureScoreCell{conditionId1} .* linearizedProjectedMeasureScoreCell{conditionId2})) / (size(linearizedProjectedMeasureScoreCell{conditionId1}, 1) - 1);
                        
                        % ignore locations with nan (invalid, for example constant vector) correlation
                        validCorrelationId = ~isnan(correlationSimilaity);
                        
                        % re-normalize to make a simplex with valid correlation locations
                        jointProbabilityFromDipoleDensity(validCorrelationId) = jointProbabilityFromDipoleDensity(validCorrelationId) / sum(jointProbabilityFromDipoleDensity(validCorrelationId));
                        
                        
                        % use Fisher's Z transform
                        fishersZSimilaity = pr.correlationToFishersZ(correlationSimilaity);
                        
                        totalSimilarity = sum(fishersZSimilaity(validCorrelationId) .* jointProbabilityFromDipoleDensity(validCorrelationId));
                        
                        % not use this transform (just correlations)
                        % totalSimilarity = sum(correlationSimilaity .* jointProbabilityFromDipoleDensity);
                        
                        obj.similarity(anatomicalRegionId, conditionId1, conditionId2) = totalSimilarity;
                        obj.similarity(anatomicalRegionId, conditionId2, conditionId1) = totalSimilarity;
                    end;
                end;
                
            end;
            
            
        end;
        function plotSimilarity(varargin)
        end;
    end
end