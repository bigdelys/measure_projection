classdef dipoleAndSubjectName < pr.dipole
    % contains information related to dipoles and additionally contains some subject information.
    properties
        subjectName % an array containing subject names associates with dipoles.
        subjectNumber % an array containing subject numbers associates with dipoles. Please notice that subject numbers are very different from subject names, they are just created to have an integer reference to subject names (instead of using subject names which are of type string).
        uniqueSubjectName
    end;
    
    methods
        function [linearProjectedMeasure dipoleDensity uniqeSubjectId] = getProjectedMeasureForEachSubject(obj, headGrid, regionOfInterestCube, projectionParameter, varargin)
            % [linearProjectedMeasure groupId uniqeDatasetId dipoleDensity] = getProjectedMeasureForEachSubject(obj, headGrid, regionOfInterestCube, projectionParameter, (key, value pair options))
            %
            % projects each subject to provided position(s) and returns a NxPxS matrix.
            % N is the numbr of dimensions of the linearized measure.
            % P is the number of points in the input regionOfInterestCube parameter.
            % S is the number of subjects.
            
            
            inputOptions = finputcheck(varargin, ...
                { 'calculateMeasure'   'string'    {'on', 'off'}  'on';... % this option can be used to only get dipole denisty back and skip the projected measure when it is not used but takes a lot of memory and time to calculate.
                });
            
            % go through all subejct and project session dipoles to the given location(s)
            uniqeSubjectId = unique(obj.subjectNumber);
            
            if strcmpi(inputOptions.calculateMeasure, 'on')
                linearProjectedMeasure = zeros(size(obj.linearizedMeasure), sum(logical(regionOfInterestCube(:))), length(uniqeSubjectId));
            else
                linearProjectedMeasure = [];
            end;
            
            dipoleDensity = []; % hold the density of dipole for each session, to be used in calculating averages for that session. It is an P x S matrix (as defined above).
            counter  = 1;
            for subjectId = uniqeSubjectId
                dipoleAndMeasureForSubject = obj.createSubsetForId(find(obj.subjectNumber == subjectId), false); % do not re-normalize scalpmap polarities.
                
                [projectionMatrix dipoleDensityFromSubject]= pr.meanProjection.getProjectionMatrix(dipoleAndMeasureForSubject, headGrid, projectionParameter, regionOfInterestCube);
                
                if strcmpi(inputOptions.calculateMeasure, 'on')
                    projectionFromTheDataset = dipoleAndMeasureForSubject.linearizedMeasure * projectionMatrix;
                    
                    linearProjectedMeasure(:,:,counter) = projectionFromTheDataset;
                    counter = counter + 1;
                end;
                
                dipoleDensity = cat(2, dipoleDensity, dipoleDensityFromSubject');
            end;
        end;
        
        function [linearProjectedMeasure subjectConditionCell groupId uniqeSubjectId dipoleDensity] = getMeanProjectedMeasureForEachSubject(obj, headGrid, regionOfInterestCube, projectionParameter, varargin)
            % [linearProjectedMeasure subjectConditionCell dipoleDensity uniqeSubjectId] = getProjectedMeasureForEachSession(obj, headGrid, regionOfInterestCube, projectionParameter, (key, value pair options))
            %
            % projects each subject to provided position(s) and returns a NxS matrix in
            % linearProjectedMeasure.
            % N is the numbr of dimensions of the linearized measure.          
            % S is the number of subjects.
            % by setting 'calculateMeasure' to 'off' you can only get the total dipole density (much
            % faster and less memory).      
            %
            % subjectConditionCell is a cell array of number of subjects x number of conditions,
            % each containing a single condition with the original shape (e.g. 2-D for ERSP).            
            
            inputOptions = finputcheck(varargin, ...
                { 'calculateMeasure'   'string'    {'on', 'off'}  'on';... % this option can be used to only get dipole denisty back and skip the projected measure when it is not used but takes a lot of memory and time to calculate.
                });
            
            % go through all subejct and project session dipoles to the given location(s)
            uniqeSubjectId = unique(obj.subjectNumber);
            
            if strcmpi(inputOptions.calculateMeasure, 'on')
                linearProjectedMeasure = zeros(size(obj.linearizedMeasure), length(uniqeSubjectId));
            else
                linearProjectedMeasure = [];
            end;
            
            groupId = []; % hold group ids (numbers) for datasets
            dipoleDensity = []; % hold the density of dipole for each session, to be used in calculating averages for that session. It is an P x S matrix (as defined above).
            counter  = 1;
            for subjectId = uniqeSubjectId
                dipoleAndMeasureForSubject = obj.createSubsetForId(obj.subjectNumber == subjectId, false); % do not re-normalize scalpmap polarities.
                
                [projectionMatrix dipoleDensityFromSubject]= pr.meanProjection.getProjectionMatrix(dipoleAndMeasureForSubject, headGrid, projectionParameter, regionOfInterestCube);
                
                if strcmpi(inputOptions.calculateMeasure, 'on')
                    projectionFromTheDataset = dipoleAndMeasureForSubject.linearizedMeasure * projectionMatrix;
                    normalizedDipoleDenisty = bsxfun(@times, dipoleDensityFromSubject, 1 ./ sum(dipoleDensityFromSubject));
                    linearProjectedMeasure(:,counter) = projectionFromTheDataset  * normalizedDipoleDenisty';
                    counter = counter + 1;
                end;
                
                dipoleDensity = cat(2, dipoleDensity, dipoleDensityFromSubject');
                groupId = [groupId  dipoleAndMeasureForSubject.groupNumber(1)]; % get the group number of dataset
            end;
            
            numberOfSubjects = size(linearProjectedMeasure, 2);
            
            % place each condition in a different cell for more convenience
            if nargout > 1
                subjectConditionCell = {};
                for i=1:numberOfSubjects
                    conditionCell = obj.getSeparatedConditionsForLinearizedMeasure(linearProjectedMeasure(:,i))';
                    for j=1:length(conditionCell)
                        subjectConditionCell{i,j} = conditionCell{j};
                    end;
                end;
            end;
            
            % get the total dipole density
            dipoleDensity  = sum(dipoleDensity);
        end
        
        function newObj = createSubsetForId(obj, subsetId, renormalizeScalpmapPolarity)
            
            if nargin < 3
                renormalizeScalpmapPolarity = true;
            end;
            
            newObj = obj;
            newObj.linearizedMeasure = obj.linearizedMeasure(:, subsetId);
            newObj.location = obj.location(subsetId,:);
            newObj.direction = obj.direction(subsetId,:);
          %  newObj.insideBrain = obj.insideBrain(subsetId);           
            newObj.subjectName = obj.subjectName(subsetId);
            newObj.subjectNumber = obj.subjectNumber(subsetId);           
            newObj.uniqueSubjectName = unique(newObj.subjectName);            
            
            if isprop(newObj, 'scalpmap') && ~isempty(newObj.scalpmap)
                newObj.scalpmap = obj.scalpmap.createSubsetForId(subsetId, renormalizeScalpmapPolarity);                
            end;
        end
    end;
end