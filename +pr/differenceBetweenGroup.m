classdef differenceBetweenGroup
    % holds information about an individual projection from dipole space to head (brain) grid
    % locations.
    properties
        headGrid;
        standardDeviationOfEstimatedDipoleLocation % in mm, default std. for gaussian cloud representing each dipole.
        numberOfPermutations
        dipoleLocation
        dipoleDirection
        groupId
    end % public properties
    
    properties (Access = 'protected')
        groupSignificanceForPlotting
    end;
    
    methods
        function obj = differenceBetweenGroup(dipoleAndMeasure, groupNameOrId, headGrid, standardDeviationOfEstimatedDipoleLocation, numberOfPermutations)
            % groupNameOrId should either contain a cell array or be a vector of 1s. and 2s. If it
            % is a cell array, it should have two cell members, each containing another cell with
            % the names of groups. For example, {{'1', '2'}, {'3'}} specifies two 'supergroups' to
            % be compared: one consisting of Study groups '1' and '2' and the other from study group
            % '3'.
            
            if iscell(groupNameOrId)                
                groupId1 = ismember(dipoleAndMeasure.groupName, groupNameOrId{1});
                groupId2 = ismember(dipoleAndMeasure.groupName, groupNameOrId{2});
                
                groupId = groupId1 + 2 * groupId2;
            else 
                groupId = groupNameOrId;
            end;
            
            if nargin<7
                numberOfPermutations = 300;
            end;
            
            if nargin<6
                standardDeviationOfEstimatedDipoleLocation = 20;
            end;
            
            obj.numberOfPermutations = numberOfPermutations;
            obj.groupId = groupId;
            obj.headGrid = headGrid;
            obj.standardDeviationOfEstimatedDipoleLocation = standardDeviationOfEstimatedDipoleLocation;
            obj.dipoleLocation = dipoleAndMeasure.location;
            obj.dipoleDirection = dipoleAndMeasure.direction;
        end
        function plotScatter(obj, significanceLevel)
            value = double(obj.groupSignificanceForPlotting < significanceLevel);            
            value(~value) = 0.1;
            
            color = value2color(value(:), jet);
            
            scatter3(obj.headGrid.xCube(obj.headGrid.insideBrainCube), obj.headGrid.yCube(obj.headGrid.insideBrainCube), obj.headGrid.zCube(obj.headGrid.insideBrainCube), value(obj.headGrid.insideBrainCube) * 40, color(obj.headGrid.insideBrainCube), 'filled');
            axis equal;
        end;
        function valueOnFineGrid = plotMri(obj, significanceLevel, mri3dplotOptions)
            
            if nargin<2
                significanceLevel = 0.03;
            end;
            
            if nargin<3
                mri3dplotOptions = {'mriview' , 'top','mrislices', [-50 -30 -20 -15 -10 -5 0 5 10 15 20 25 30 40 50]};
            end;
            
            valueOnCoarseGrid = obj.groupSignificanceForPlotting;
            valueOnCoarseGrid(obj.groupSignificanceForPlotting > significanceLevel) = 0;
            
            valueOnCoarseGrid(valueOnCoarseGrid<0) = 0;
            
            [valueOnFineGrid mri] = convert_coarse_grid_to_mri3d(valueOnCoarseGrid, obj.headGrid.xCube, obj.headGrid.yCube, obj.headGrid.zCube);
            mri3dplot(valueOnFineGrid, mri, mri3dplotOptions{:}); % for some reason, this function hicjacks a currently open figure. even if a new figur is just created.
            title('P value', 'color', [1 1 1]);
        end;
    end;
end