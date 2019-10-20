classdef differenceOfMeasureBetweenGroup < pr.differenceBetweenGroup
    % holds information about an individual projection from dipole space to head (brain) grid
    % locations.
    properties
        similarity;
        linearizedProjectedMeasure;
        
        groupMeasureSignificanceInNeighborhood    % a cell array with wo cells, each for a different group significance.        
        minGroupSignificanceInNeighborhood
    end % properties
    methods
        function obj = differenceOfMeasureBetweenGroup(dipoleAndMeasure, groupNameOrId, headGrid, similarity, standardDeviationOfEstimatedDipoleLocation, numberOfPermutations)
            
            superClassArgs = {};
            
            if nargin >= 3
                superClassArgs{1} = dipoleAndMeasure;
                superClassArgs{2} = groupNameOrId;
                superClassArgs{3} = headGrid;
                
                if nargin >=5
                superClassArgs{4} = standardDeviationOfEstimatedDipoleLocation;
                end;
                
                if nargin >=6
                superClassArgs{5} = numberOfPermutations;
                end;
            end;
            
            obj = obj@pr.differenceBetweenGroup(superClassArgs{:}); % call the super class constructor
            
            if nargin >=3
                
                dipoleLocation = dipoleAndMeasure.location;
                
                standardDeviationOfEstimatedDipoleLocationPowerTwo = obj.standardDeviationOfEstimatedDipoleLocation ^ 2;
                
                group1SignificanceInNeighborhood = ones(headGrid.cubeSize);
                group2SignificanceInNeighborhood = ones(headGrid.cubeSize);
                minGroupSignificanceInNeighborhood = ones(headGrid.cubeSize);
                
                groupDensityDifferenceSignificance =  ones(headGrid.cubeSize);
                normalizedGroup1Density = ones(headGrid.cubeSize);
                normalizedGroup2Density = ones(headGrid.cubeSize);
                
                surrogateGroupIds = create_surrogate_group_ids(obj.groupId, obj.numberOfPermutations, dipoleAndMeasure.subjectNumber);
                
                progress('init'); % start the text based progress bar
                
                for i=1:numel(headGrid.xCube)
                    if headGrid.insideBrainCube(i) %% & sumWeightedSimilarityPvalue(i) < 0.02
                        
                        if mod(i,10) ==0
                            %fprintf('Percent done = %d\n', round(100 * i / numel(headGrid.xCube)));
                            progress(i / numel(headGrid.xCube), sprintf('\npercent done %d/100',round(100*i / numel(headGrid.xCube))));
                        end;
                        
                        pos = [headGrid.xCube(i) headGrid.yCube(i) headGrid.yCube(i)];
                        distanceToDipoles = sum((dipoleLocation - repmat(pos, size(dipoleLocation,1), 1))' .^2) .^ 0.5;
                        
                        % pass distance to dipoles through a gaussian kernel with specified standard deviation.
                        gaussianPassedDistanceToDipoles = sqrt(1/(2 * pi * standardDeviationOfEstimatedDipoleLocationPowerTwo)) * exp(-distanceToDipoles.^2 / (2 * standardDeviationOfEstimatedDipoleLocationPowerTwo));
                        
                        gaussianWeightMatrix = repmat(gaussianPassedDistanceToDipoles,length(gaussianPassedDistanceToDipoles),1);
                        
                        % a matrix that weights each pair of dipoles according to their gaussians
                        neighborhoodWeightMatrix = gaussianWeightMatrix .* gaussianWeightMatrix';
                        
                        groupSignificanceInNeighborhood = calculate_group_significance_based_on_pairwise_similarity(obj.groupId, similarity, surrogateGroupIds, neighborhoodWeightMatrix);
                        group1SignificanceInNeighborhood(i) = groupSignificanceInNeighborhood(1);
                        group2SignificanceInNeighborhood(i) = groupSignificanceInNeighborhood(2);
                        minGroupSignificanceInNeighborhood(i) = min(groupSignificanceInNeighborhood);                        
                    end;
                end;
                
                obj.groupMeasureSignificanceInNeighborhood{1} = group1SignificanceInNeighborhood;
                obj.groupMeasureSignificanceInNeighborhood{2} = group2SignificanceInNeighborhood;                
                obj.minGroupSignificanceInNeighborhood = minGroupSignificanceInNeighborhood;
                
                obj.similarity = similarity;
                
                % use minGroupSignificanceInNeighborhood for default plots
                obj.groupSignificanceForPlotting = minGroupSignificanceInNeighborhood;    
                
                pause(.1);
                progress('close'); % duo to some bug need a pause() before
                fprintf('\n');
            end;
        end
    end;
end