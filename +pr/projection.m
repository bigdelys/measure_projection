classdef projection
    properties
        headGrid
        dipoleDensity % a dipole density materix with exact zeros at far from dipole locations.
        linearizedProjectedMeasure = []
        originalMeasureSize
    end % properties
    methods(Access = 'private')
        function [obj linearizedMeasureArray] = convertMeasureArrayToLinearFormat(obj, measureArray)
            obj.originalMeasureSize = size(measureArray);
            linearizedMeasureArray = measureArray(:);
        end;
        function obj = setLinearizedMeasureForAllNonZeroDipoleDensityLocationTo(obj, linearizedProjectedMeasure)
            [obj linearizedProjectedMeasure] = convertMeasureArrayToLinearFormat(obj, linearizedProjectedMeasure);
            obj.linearizedProjectedMeasure = repmat(linearizedProjectedMeasure, 1, sum(obj.dipoleDensity(:) > 0));
        end;
    end;
    methods
        function obj = projection(headGrid, dipoleLocation, measureArray, standardDeviationOfEstimatedDipoleLocation, dipoleDensityCutOffDistanceInStd)
            
            if nargin < 4
                standardDeviationOfEstimatedDipoleLocation = 12; % in mm, default std. for gaussian cloud representing each dipole.
            end;
            
            if nargin < 5
                dipoleDensityCutOffDistanceInStd = 3; % in standard deviation units.
            end;
            
            obj.headGrid = headGrid;
            
            obj.dipoleDensity = single(zeros(headGrid.cubeSize));
            
            % if dipoleLocation is provided
            if nargin > 1
                standardDeviationOfEstimatedErrorInDipoleLocationPowerTwo = standardDeviationOfEstimatedDipoleLocation ^ 2;
                
                % get all grid p[ositions, even those outside brain volume.
                gridPosition = obj.headGrid.getPosition('all');
                
                distanceToDipole = sum( (gridPosition - repmat(dipoleLocation, size(gridPosition,1), 1)) .^2,2 ) .^ 0.5;
                
                % only calculate density at locations near the dipole, assume exact zero everywhere else
                nearDipoleGridPOsitionId = distanceToDipole <= (dipoleDensityCutOffDistanceInStd * standardDeviationOfEstimatedDipoleLocation);
                obj.dipoleDensity(nearDipoleGridPOsitionId) = sqrt(1/(2 * pi * standardDeviationOfEstimatedErrorInDipoleLocationPowerTwo)) * exp(-distanceToDipole(nearDipoleGridPOsitionId).^2 / (2 * standardDeviationOfEstimatedErrorInDipoleLocationPowerTwo));
                
                % set density outside brain volume to zero
                obj.dipoleDensity(~headGrid.insideBrainCube) = 0;
                
                % make sum of dipole density to be one
                obj.dipoleDensity = obj.dipoleDensity / sum(obj.dipoleDensity(:));
                
                % if a linearized measure is provided, set all non-zero density locations measures
                % values to it.
                if nargin > 2 && ~isempty(measureArray)
                    obj = setLinearizedMeasureForAllNonZeroDipoleDensityLocationTo(obj, measureArray);
                end;
            end;
        end;
        function measureArray = convertLinearizedMeasureToArray(obj, linearizedMeasureArray)
            measureArray = reshape(linearizedMeasureArray, obj.originalMeasureSize);
        end;
        function [valueOnFineGridOutput mri] = plotDipoleDensityAsMri(obj, mri3dplotOptions)
            
            if nargin < 2
                mri3dplotOptions = {'mriview' , 'top','mrislices', [-50 -30 -20 -15 -10 -5 0 5 10 15 20 25 30 40 50]};
            end;
            
            [valueOnFineGrid mri] = convert_coarse_grid_to_mri3d(double(obj.dipoleDensity), obj.headGrid.xCube, obj.headGrid.yCube, obj.headGrid.zCube);
            mri3dplot(valueOnFineGrid, mri, mri3dplotOptions{:}); % for some reason, this function hicjacks a currently open figure. even if a new figur is just created.
            
            if nargout > 0
                valueOnFineGridOutput = valueOnFineGrid;
            end;
        end;
        function plot(obj, varargin) % overload regulat plot() function
            obj.plotDipoleDensityAsMri(varargin{:});
        end;
        function result = similarity(obj1, obj2)

            
            if isempty(obj1.linearizedProjectedMeasure) || isempty(obj2.linearizedProjectedMeasure)
                error('Projection class error: At least one of the provided Projection objects has an empty linearized measure.\n');
            end;
            
            % first for each input projection object we find locations with non-zero dipole density
            nonZeroDensityLocation1 = logical(obj1.dipoleDensity);
            nonZeroDensityLocation2 = logical(obj2.dipoleDensity);
            
            
            % find location in which both have non-zero densities
            areasOnWhichBothDipoleDensitiesAreNonZero = obj1.dipoleDensity > 0 & obj2.dipoleDensity > 0;
            
            
            % since linearProjectedMeasure variable is only assigned to non-zero density locations in
            % each object, we need to find out which IDs in dipole density do they belong to.
            nonZeroDipoleDensityIdForResult = find(areasOnWhichBothDipoleDensitiesAreNonZero);
            nonZeroDipoleDensityIdForObj1 = find(obj1.dipoleDensity);
            nonZeroDipoleDensityIdForObj2 = find(obj2.dipoleDensity);
            
            % find ids for linearized measures in obj1 and obj2 which are associated with result
            % object linearized ids
            [dummy resultLinerizedIdInObj1] = ismember(nonZeroDipoleDensityIdForResult, nonZeroDipoleDensityIdForObj1);
            [dummy resultLinerizedIdInObj2] = ismember(nonZeroDipoleDensityIdForResult, nonZeroDipoleDensityIdForObj2);
            
            sumWeightedSimilarities = 0;
            sumWeights = 0;
            % go through all non-zero locations, find associated linerized
            % measure ids in ob1 and ob2 and also their densities and then
            % calculate the normalized weighted sum of a similarity
            % measure, for example correlation
            for i=1:length(nonZeroDipoleDensityIdForResult)
                c = corrcoef(cat(2, obj1.linearizedProjectedMeasure(:,resultLinerizedIdInObj1(i)), obj2.linearizedProjectedMeasure(:,resultLinerizedIdInObj2(i))));
                pairWeight = obj1.dipoleDensity(nonZeroDipoleDensityIdForObj1(resultLinerizedIdInObj1(i))) * obj2.dipoleDensity(nonZeroDipoleDensityIdForObj2(resultLinerizedIdInObj2(i)));
                sumWeightedSimilarities = sumWeightedSimilarities + c(1,2) * pairWeight;
                sumWeights = sumWeights + pairWeight;
            end;
            
            result = sumWeightedSimilarities / sumWeights;
        end;
        function resultObj = plus(obj1, obj2) % overloading + operator
            
            % first check if both objects are from the same (projection) class
            if ~isa(obj1, 'pr.projection')
                error('Projection class error: First argument is not an object of class Projection.\n');
            end;
            
            if ~isa(obj2, 'pr.projection')
                error('Projection class error: Second argument is not an object of type Projection.\n');
            end;
            
            % make sure they both have the same head grids
            if ~isequal(obj1.headGrid, obj2.headGrid)
                error('Projection class error: Two input Projection variables has diffrent Head-Grids.\n');
            end;
            
            % if one of the objects to be added contained no projected measure yet, the sum equals to
            % the other one (which might or might not be empty).
            if isempty(obj1.linearizedProjectedMeasure)
                resultObj = obj2;
                return;
            end;
            
            if isempty(obj2.linearizedProjectedMeasure)
                resultObj = obj1;
                return;
            end;
            
            % when both input variables have non-empty linearized measures.
            
            % check if linearized measures have the same first dimension (corresponding to measure)
            if size(obj1.linearizedProjectedMeasure,1) ~=  size(obj2.linearizedProjectedMeasure,1)
                error('Projection class error: Two input Projection variables has (non-empty) linerized measures of different size.\n');
            end;
            
            % first for each input projection object we find locations with non-zero dipole density
            nonZeroDensityLocation1 = logical(obj1.dipoleDensity);
            nonZeroDensityLocation2 = logical(obj2.dipoleDensity);
            
            
            resultObj = obj1; % copy common variables from the first input variable
            
            % sum up dipole densities
            resultObj.dipoleDensity = obj1.dipoleDensity + obj2.dipoleDensity;
            
            % since linearProjectedMeasure variable is only assigned to non-zero density locations in
            % each object, we need to find out which IDs in dipole density do they belong to.
            nonZeroDipoleDensityIdForResult = find(resultObj.dipoleDensity);
            nonZeroDipoleDensityIdForObj1 = find(obj1.dipoleDensity);
            nonZeroDipoleDensityIdForObj2 = find(obj2.dipoleDensity);
            
            % find ids for linearized measures in obj1 and obj2 which are associated with result
            % object linearized ids
            [dummy resultLinerizedIdInObj1] = ismember(nonZeroDipoleDensityIdForResult, nonZeroDipoleDensityIdForObj1);
            [dummy resultLinerizedIdInObj2] = ismember(nonZeroDipoleDensityIdForResult, nonZeroDipoleDensityIdForObj2);
            
            
            % create an empty linerized measure matrix, each second dimension corresponds to a
            % non-zero diple density location.
            resultObj.linearizedProjectedMeasure = single(zeros(size(obj1.linearizedProjectedMeasure,1), length(nonZeroDipoleDensityIdForResult)));
            
            % now we have to calculate new linearized projected measure
            for i=1:size(resultObj.linearizedProjectedMeasure,2)
                % if the dipole denisty at the location for obj1 is zero, the measure is equal to
                % obj2's measure and vice versa
                if resultLinerizedIdInObj1(i) == 0
                    resultObj.linearizedProjectedMeasure(:,i) = obj2.linearizedProjectedMeasure(:,resultLinerizedIdInObj2(i));
                elseif resultLinerizedIdInObj2(i) == 0
                    resultObj.linearizedProjectedMeasure(:,i) = obj1.linearizedProjectedMeasure(:,resultLinerizedIdInObj1(i));
                else  % when neither dipole density is zero
                    resultObj.linearizedProjectedMeasure(:,i) = (obj1.linearizedProjectedMeasure(:,resultLinerizedIdInObj1(i)) * obj1.dipoleDensity(nonZeroDipoleDensityIdForObj1(resultLinerizedIdInObj1(i))) + obj2.linearizedProjectedMeasure(:,resultLinerizedIdInObj2(i)) * obj2.dipoleDensity(nonZeroDipoleDensityIdForObj2(resultLinerizedIdInObj2(i)))) / resultObj.dipoleDensity(nonZeroDipoleDensityIdForResult(i));
                end;
            end;
        end;
        function resultObj = times(measureArray, obj) % overloading  .* operator
            % measureArray is a numerical matrix with any dimensions (N x M x K x I ...).
            % order if not important in .* operation.
            
            % if the input order was first a projection object and then an array, swap the inputs
            if isa(measureArray, 'pr.projection')
                t = measureArray;
                measureArray = obj;
                obj = t;
            end;
            
            if  isnumeric(measureArray) && isa(obj, 'pr.projection')
                resultObj = setLinearizedMeasureForAllNonZeroDipoleDensityLocationTo(obj, measureArray);
            else
                error('Projection class error: For .* (projection) operation, one variable should be a numerical array (any dimension) and the other should be of Projection class.');
            end;
        end;
        function resultObj = mtimes(objectOrScalar1, objectOrScalar2) % overloading * operator
            
            % swap input variables if the scalar one is the second
            if isnumeric(objectOrScalar2)
                t = objectOrScalar1;
                objectOrScalar1 = objectOrScalar2;
                objectOrScalar2 = t;
            end;
            
            % if the operation is multipication of a scalar by an object,
            % modulate (multiple) the object dipole density by that
            % scalar.
            if isnumeric(objectOrScalar1)
                resultObj = objectOrScalar2;
                
                % Only non-zero locations are accessed to increase speed.
                isNonZeroDensity = resultObj.dipoleDensity > 0;
                resultObj.dipoleDensity(isNonZeroDensity) = resultObj.dipoleDensity(isNonZeroDensity) * objectOrScalar1;
            elseif isa(objectOrScalar1, 'pr.projection')
                % implement the similary operator with a weighted sum of
                % correlation here.
                error('Not implemented yet.\n');
            end;
            
        end;
    end % methods
end