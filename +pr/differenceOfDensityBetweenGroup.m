classdef differenceOfDensityBetweenGroup < pr.differenceBetweenGroup
    % holds information about an individual projection from dipole space to head (brain) grid
    % locations.
    properties        
        groupDensityDifferenceSignificance        
        normalizedGroupDensity
    end % properties
    methods
        function obj = differenceOfDensityBetweenGroup(dipoleAndMeasure, groupNameOrId, headGrid, standardDeviationOfEstimatedDipoleLocation, numberOfPermutations)
            
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
                        
                        [groupDensityDifferenceSignificance(i) normalizedGroup1Densities]= calculate_group_density_difference_significance(obj.groupId, gaussianPassedDistanceToDipoles, surrogateGroupIds);
                        normalizedGroup1Density(i) = normalizedGroup1Densities(1);
                        normalizedGroup2Density(i) = normalizedGroup1Densities(2);
                    end;
                end;
                
                obj.groupDensityDifferenceSignificance = groupDensityDifferenceSignificance;
                obj.normalizedGroupDensity{1} = normalizedGroup1Density;
                obj.normalizedGroupDensity{2} = normalizedGroup2Density;
                
                % use this for default plots (from the parent class).
                obj.groupSignificanceForPlotting = groupDensityDifferenceSignificance;
                
                pause(.1);
                progress('close'); % duo to some bug need a pause() before
                fprintf('\n');
            end;
        end
        function valueOnFineGrid = plotMri(obj, firstGroup, significanceLevel, mri3dplotOptions)
            
            if nargin<3
                significanceLevel = 0.03;
            end;
            
            if nargin<4
                mri3dplotOptions = {'mriview' , 'top','mrislices', [-50 -30 -20 -15 -10 -5 0 5 10 15 20 25 30 40 50]};
            end;
            
            if nargin<2
                firstGroup = 1;
            end;
            
            if firstGroup == 1
                valueOnCoarseGrid = 100 * (obj.normalizedGroupDensity{1} - obj.normalizedGroupDensity{2}) ./ obj.normalizedGroupDensity{1};
            else
                valueOnCoarseGrid = 100 * (obj.normalizedGroupDensity{2} - obj.normalizedGroupDensity{1}) ./ obj.normalizedGroupDensity{2};
            end;
            
            valueOnCoarseGrid(obj.groupSignificanceForPlotting > significanceLevel) = 0;
            
            valueOnCoarseGrid(valueOnCoarseGrid < 0) = 0;
            
            [valueOnFineGrid mri] = convert_coarse_grid_to_mri3d(valueOnCoarseGrid, obj.headGrid.xCube, obj.headGrid.yCube, obj.headGrid.zCube);
            mri3dplot(valueOnFineGrid, mri, mri3dplotOptions{:}); % for some reason, this function hicjacks a currently open figure. even if a new figur is just created.
            
            if firstGroup == 1
                title('Group density % diff. (1-2)', 'color', [1 1 1]);
            else
                title('Group density % diff. (2-1)', 'color', [1 1 1]);
            end;
        end;
    end;
end