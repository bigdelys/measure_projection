classdef dipoleAndMeasureOfStudy < pr.dipoleAndMeasure & pr.studyDipole
    % holds a measure (e.g. ERP, ERSP...) from one or several conditions in a linearized way.
    % the first dimension is the linearized version of the measure for concatenated subset of
    % consitions.
    % the second dimension of value is dipoles.
    properties
        conditionId;
        conditionLabel;
        relationshipToBrainVolume = 'insidebrain';
        scalpmap                                                                     % information about dipole scalp maps
        removedIc = struct('eye', struct('removed', true), 'outsideBrain', [])       % a structure that contains information about removed dipoles
    end % properties       
    methods (Access = 'private')
        function measure2DWithConditionsInCells = getSeparatedConditionsForLinearized2DMeasure(obj, linearMeasureForCombinedCondition)
            % changce 1-d lineairzed measure into 2D
            numberOfTimeFramesInEachCondition = length(obj.time);
            measureForCombinedCondition = reshape(linearMeasureForCombinedCondition, [], numberOfTimeFramesInEachCondition * length(obj.conditionId))';
            
            % separate conditions (they are concatenated in the time dimension).
            measureWithConditionsInCells = {};
            for coditionNumber = 1:length(obj.conditionId)
                measure2DWithConditionsInCells{coditionNumber} = measureForCombinedCondition((1+(coditionNumber-1) * numberOfTimeFramesInEachCondition) : (numberOfTimeFramesInEachCondition * coditionNumber),:);
            end;
        end;
        function measure1DWithConditionsInCells = getSeparatedConditionsForLinearized1DMeasure(obj, linearMeasureForCombinedCondition)
            
            % usually conditions are concatenated in the time dimension, with the exception of spec
            % measure in which they are concatenated in the frequency dimension.
            if isprop(obj, 'time') && length(obj.time) >= 1
				numberOfTimeFramesInEachCondition = length(obj.time);
			elseif isprop(obj, 'frequency') && length(obj.frequency) >= 1
				numberOfTimeFramesInEachCondition = length(obj.frequency);
			elseif length(obj.conditionId) == 1
				numberOfTimeFramesInEachCondition = size(linearMeasureForCombinedCondition, 1);
			else
				error('Since there are more than one conditions and no ''time'' or ''frequency'' field exists. the number of frames in each condition cannot be inferred.\n');
			end;
				
            % separate conditions (they are concatenated in the time dimension).
            measureWithConditionsInCells = {};
            for coditionNumber = obj.conditionId
                measure1DWithConditionsInCells{coditionNumber} = linearMeasureForCombinedCondition((1+(coditionNumber-1) * numberOfTimeFramesInEachCondition) : (numberOfTimeFramesInEachCondition * coditionNumber),:);
            end;
        end;
    end;
    methods (Abstract = true, Access = 'protected')
        plotMeasureAsArrayInCell(measureAsArrayInCell, title, varargin); % will be defined in subclasses (child classes).
    end;
    methods
        
        function obj = dipoleAndMeasureOfStudy(STUDY, ALLEEG, varargin) % constructor
            % conditionId is an optional input that specifies which conditions should be included.
            % by default all conditions are included.
            
            obj = obj@pr.dipoleAndMeasure();
            obj = obj@pr.studyDipole(STUDY, ALLEEG);
            
            if nargin > 0
                
                inputOptions = finputcheck(varargin, ...
                    { 'condition'         {'string' 'cell'}  []                       ''; ...
                    'location'       'string'     {'insidebrain' 'outsidebrain' 'any'}   'insidebrain';...                    
                    'removeEye'      'boolean'    []    true; ...
                    'eyeRemovalThreshold'    'real'    [0 1]    0.944; ... % correlation to sample eye ICs threshold
                    'loadScalpmap'   'boolean'    []    true });
                                                
                obj.relationshipToBrainVolume = inputOptions.location;
                obj.removedIc.eye.removed =  inputOptions.removeEye;
                obj.removedIc.eye.removalThreshold =  inputOptions.eyeRemovalThreshold;
                
                % read conditions from design
                
                % find design variable associated with the condition so we can read condition labels
                try
                    conditionVariableId = [];
                    for i=1: length(STUDY.design(STUDY.currentdesign).variable)
                        if strcmpi(STUDY.design(STUDY.currentdesign).variable(i).label, 'condition') | strcmpi(STUDY.design(STUDY.currentdesign).variable(i).label, 'type')
                            conditionVariableId = i;
                            break;
                        end;                                               
                    end;
                    
                    if isempty(conditionVariableId)
                        fprintf('Measure Projection: Study design does not have a field named ''Condition'', please check if you are using another name for this (e.g. ''Type'').\n Only correct name could be read in the toolbox.\n');
                    end;
                    
                    conditionLabels = STUDY.design(STUDY.currentdesign).variable(conditionVariableId).value;
                    
                    % if a condition is a concatenation of two conditions thecorresponding value
                    % inside conditionLabels is going to be a cell instead of strings. Here we
                    % change it ino a string.
                    for i=1:length(conditionLabels)
                        if iscell(conditionLabels{i})
                            conditionLabels{i} = pr.conditionStringFromCell(conditionLabels{i});
                        end;
                    end;
                    
                catch % if it cannot be read
                    fprintf('Measure Projection: Condition labels could not be read from Design, falling back to reading them from Study.condition (which could be not correct, unless your study is old).\n');
                    conditionLabels = STUDY.condition;
                end;
                
                if isempty(inputOptions.condition)
                    conditionId = [];
                elseif ischar(inputOptions.condition) % is condition is provided as a single string, like 'target'
                    conditionId = find(conditionLabels, inputOptions.condition);
                elseif iscell(inputOptions.condition) % is condition is provided as a cell, like {'target' 'nontarget'}
                    for i=1:length(inputOptions.condition)
                        conditionId(i) = find(strcmp(conditionLabels, inputOptions.condition{i}));
                    end;
                end;
                
                if nargin < 3 || isempty(conditionId)
                    conditionId = 1:length(conditionLabels);
                end
                
                obj.conditionId  = conditionId;
                obj.conditionLabel = conditionLabels(conditionId);
                
                % read scalpmaps, mostly for visualization but also for correct ERP polarity.
                if inputOptions.loadScalpmap
                    
                    % if only a subset of scalpmaps will be used (location is set to value other than
                    % 'any'), there will be another polarity normalization after subset selction, so
                    % there is no need to normalize scalpmaps here (to prevent doing it twice, which is time consuming with the convex method).
                    performNormalization = strcmpi(inputOptions.location, 'any');
                    
                    obj.scalpmap = pr.scalpmapOfStudy(STUDY, ALLEEG, obj.icIndexForEachDipole, 'normalizePolarity', performNormalization);
                end;
            end;
        end;
        
        function newObj = createSubsetForId(obj, subsetId, renormalizeScalpmapPolarity)
            
            if nargin < 3
                renormalizeScalpmapPolarity = true;
            end;
            			
			if any(subsetId < 1) 
				subsetId = logical(subsetId);
			end;
            
            newObj = obj;
            if ~isempty(obj.linearizedMeasure)
                newObj.linearizedMeasure = obj.linearizedMeasure(:, subsetId);
            end;
            newObj.location = obj.location(subsetId,:);
            newObj.direction = obj.direction(subsetId,:);
            newObj.insideBrain = obj.insideBrain(subsetId);
            newObj.datasetId = obj.datasetId(subsetId);
            newObj.subjectName = obj.subjectName(subsetId);
            newObj.groupName = obj.groupName(subsetId);
            newObj.groupNumber = obj.groupNumber(subsetId);
            newObj.subjectNumber = obj.subjectNumber(subsetId);
            newObj.datasetIdAllConditions = obj.datasetIdAllConditions(:,subsetId);
            newObj.numberInDataset = obj.numberInDataset(subsetId);
            newObj.uniqueSubjectName = unique(newObj.subjectName);
            newObj.uniqueGroupName = unique(newObj.groupName);
            newObj.icIndexForEachDipole = newObj.icIndexForEachDipole(subsetId);
            
			if ~isempty(newObj.scalpmap)
				newObj.scalpmap = obj.scalpmap.createSubsetForId(subsetId, renormalizeScalpmapPolarity);
				%newObj.scalpmap = obj.scalpmap.createSubsetForId(subsetId);
			end;
		end
		
        function [newObj subsetId]= createSubsetForGroup(obj, varargin)
            % get ids for the dipoles that belong to subset
            subsetId = getSubsetIdForGroup(obj, varargin{:});
            newObj =  createSubsetForId(obj, subsetId);
        end
        
        function [newObj subsetId] = createSubsetForSubject(obj, varargin)
            % get ids for the dipoles that belong to subset
            subsetId = getSubsetIdForSubject(obj, varargin{:});
            newObj =  createSubsetForId(obj, subsetId);
        end
        
        function [newObj subsetId removedObj] = createSubsetInRelationToBrain(obj, varargin)
            % [newObj subsetId removedObj] = createSubsetInRelationToBrain(obj, varargin)
            % get ids for the dipoles that belong to subset
            subsetId = getSubsetIdInRelationToBrain(obj, varargin{:});
            newObj =  createSubsetForId(obj, subsetId);
            
            if nargout > 2
                removedSubsetId = setdiff(1:obj.numberOfDipoles, find(subsetId));
                if isempty(removedSubsetId)
                    removedObj = [];
                else
                    removedObj =  createSubsetForId(obj, removedSubsetId);
                end;
            end;
            
        end
        
        function [nonEyeObj eyeObj nonEyeId eyeId similarityToEye] = createSubsetWithoutEye(obj, varargin)
            % find eye ICs
            [eyeId similarityToEye]= obj.scalpmap.detectEye(varargin{:});
            
            nonEyeId = ~eyeId;
            
            % do not renormalize scalpmaps.
            nonEyeObj = createSubsetForId(obj, nonEyeId, false);
            
            % do not renormalize scalpmaps.
            eyeObj = createSubsetForId(obj, eyeId, false);
        end
        
        function newObj = createSubsetForCondition(obj, conditionSubset, varargin)
            
            if ischar(conditionSubset) || iscell(conditionSubset)
                conditionSubsetId = find(ismember(obj.conditionLabel, conditionSubset));
            else % if numeric
                conditionSubsetId = conditionSubset;
            end;
            
            newObj = obj;
            % form a mask by first slicing an id vector according to conditions and then taking
            % those ids from dipole measures
            linearizeId = zeros(size(obj.linearizedMeasure, 1), 1)';
            linearizeId = 1:numel(linearizeId);
            
            conditionIdMask = obj.getSeparatedConditionsForLinearizedMeasure(linearizeId);
            
            newConditionIdMask = [];
            for i= conditionSubsetId
                newConditionIdMask = cat(2, newConditionIdMask, conditionIdMask{i}');
            end;
            
            newObj.linearizedMeasure = obj.linearizedMeasure(newConditionIdMask(:), :);
            newObj.conditionLabel =  obj.conditionLabel(conditionSubsetId);
            newObj.conditionId =  obj.conditionId(conditionSubsetId);            
        end
        
        function [sessionDipoleAndMeasure groupId uniqeDatasetId] = getDipoleAndMeasureForEachSession(obj)
            % function [sessionDipoleAndMeasure groupId uniqeDatasetId] = getDipoleAndMeasureForEachSession(obj);
            
            uniqeDatasetId = unique(obj.datasetId);
            groupId = []; % hold group ids (numbers) for datasets
            
            for i = 1:length(uniqeDatasetId)
                sessionDipoleAndMeasure(i) = obj.createSubsetForId(obj.datasetId == uniqeDatasetId(i), false); % do not re-normalize scalpmap polarities.
                
                groupId = [groupId  sessionDipoleAndMeasure(i) .groupNumber(1)]; % get the group number of dataset
            end;
        end;
        
        function measureWithConditionsInCells = getSeparatedConditionsForLinearizedMeasure(obj, linearMeasureForCombinedCondition)                
            
            if obj.numberOfMeasureDimensions == 1
                measureWithConditionsInCells = getSeparatedConditionsForLinearized1DMeasure(obj, linearMeasureForCombinedCondition);
            elseif obj.numberOfMeasureDimensions == 2
                measureWithConditionsInCells = getSeparatedConditionsForLinearized2DMeasure(obj, linearMeasureForCombinedCondition);
            else
                error('Number of of measure dimensions is not assigned in ''numberOfMeasureDimensions'' property of dipoleAndMeasureOfStudy type object.');
            end;
        end;
        
         function [linearProjectedMeasure groupId uniqeDatasetId dipoleDensity] = getProjectedMeasureForEachSession(obj, headGrid, regionOfInterestCube, projectionParameter, varargin)
            % [linearProjectedMeasure uniqeDatasetId groupId] = getProjectedMeasureForEachSession(obj, headGrid, regionOfInterestCube, projectionParameter, (key, value pair options))
            %
            % Has two types of output: (1) measure for every voxel of the region of interest (2)
            % average of each session over all the voxels on the region of interest. 
            % The output dimensions change depending on which type is requested, which is set by
            % 'averageOverRegion' ('on' of 'off', default is 'off)
            %
            % projects each session (dataset) to provided position(s) and returns a NxPxS matrix (or
            % NxS if the average is requested).
            %
            % N is the numbr of dimensions of the linearized measure.
            % P is the number of points in the input regionOfInterestCube parameter (if
            % averageOverRegion is set to off, otherwise this dimension will not exist)
            % S is the number of sessions (datasets)
            %
            % by setting 'calculateMeasure' to 'off' you can only get the dipole density (much
            % faster and less memory).
            %
            % by setting 'averageOverRegion'  to 'on' it returns averages over the ROI (weighted by
            % dipole density) for each session. Also, sessionConditionCell output is only set and
            % contains conditions in separate cells when this option is set
                        
            
            inputOptions = finputcheck(varargin, ...
                { 'calculateMeasure'   'string'    {'on', 'off'}  'on';... % this option can be used to only get dipole denisty back and skip the projected measure when it is not used but takes a lot of memory and time to calculate.                                    
                });
            
            % go through all sessions and project session dipoles to the given location(s)
            uniqeDatasetId = unique(obj.datasetId);
            
            if strcmpi(inputOptions.calculateMeasure, 'on')
                linearProjectedMeasure = zeros(size(obj.linearizedMeasure,1), sum(logical(regionOfInterestCube(:))), length(uniqeDatasetId));
            else
                linearProjectedMeasure = [];
            end;
            
            groupId = []; % hold group ids (numbers) for datasets
            dipoleDensity = []; % hold the density of dipole for each session, to be used in calculating averages for that session. It is an P x S matrix (as defined above).
            counter  = 1;
            for datasetId = uniqeDatasetId
                dipoleAndMeasureForDataset = obj.createSubsetForId(obj.datasetId == datasetId, false); % do not re-normalize scalpmap polarities.
                
                [projectionMatrix dipoleDensityFromTheDataset]= pr.meanProjection.getProjectionMatrix(dipoleAndMeasureForDataset, headGrid, projectionParameter, regionOfInterestCube);
                
                if strcmpi(inputOptions.calculateMeasure, 'on')
                    projectionFromTheDataset = dipoleAndMeasureForDataset.linearizedMeasure * projectionMatrix;
                    
                    linearProjectedMeasure(:,:,counter) = projectionFromTheDataset;
                    
                    counter = counter + 1;
                end;
                
                dipoleDensity = cat(2, dipoleDensity, dipoleDensityFromTheDataset');
                groupId = [groupId  dipoleAndMeasureForDataset.groupNumber(1)]; % get the group number of dataset
                
                numberOfSubjects = size(linearProjectedMeasure, 2);
            end;
        end;
        
        function [linearProjectedMeasure sessionConditionCell groupId uniqeDatasetId dipoleDensity] = getMeanProjectedMeasureForEachSession(obj, headGrid, regionOfInterestCube, projectionParameter, varargin)
            % [linearProjectedMeasure sessionConditionCell groupId uniqeDatasetId dipoleDensity] = getProjectedMeasureForEachSession(obj, headGrid, regionOfInterestCube, projectionParameter, (key, value pair options))
            %
            % projects each session (dataset) to provided position(s) and returns a NxS
            % matrix containing dipole-density-weghted- average measures for each session over the
            % region.
            %
            % N is the numbr of dimensions of the linearized measure.
            % S is the number of sessions (datasets)
            %
            % by setting 'calculateMeasure' to 'off' you can only get the total dipole density (much
            % faster and less memory).      
            %
            % sessionConditionCell is a cell array of number of sessions x number of conditions,
            % each containing a single condition with the original shape (e.g. 2-D for ERSP).
            
            
            inputOptions = finputcheck(varargin, ...
                { 'calculateMeasure'   'string'    {'on', 'off'}  'on';... % this option can be used to only get dipole denisty back and skip the projected measure when it is not used but takes a lot of memory and time to calculate.                                   
                });
            
            % go through all sessions and project session dipoles to the given location(s)
            uniqeDatasetId = unique(obj.datasetId);
            
            if strcmpi(inputOptions.calculateMeasure, 'on')
                linearProjectedMeasure = zeros(size(obj.linearizedMeasure), length(uniqeDatasetId));
            else
                linearProjectedMeasure = [];
            end;
            
            groupId = []; % hold group ids (numbers) for datasets
            dipoleDensity = []; % hold the density of dipole for each session, to be used in calculating averages for that session. It is an P x S matrix (as defined above).
            counter  = 1;
            for datasetId = uniqeDatasetId
                dipoleAndMeasureForDataset = obj.createSubsetForId(obj.datasetId == datasetId, false); % do not re-normalize scalpmap polarities.
                
                [projectionMatrix dipoleDensityFromTheDataset]= pr.meanProjection.getProjectionMatrix(dipoleAndMeasureForDataset, headGrid, projectionParameter, regionOfInterestCube);
                
                if strcmpi(inputOptions.calculateMeasure, 'on')
                    projectionFromTheDataset = dipoleAndMeasureForDataset.linearizedMeasure * projectionMatrix;
                    normalizedDipoleDenisty = bsxfun(@times, dipoleDensityFromTheDataset, 1 ./ sum(dipoleDensityFromTheDataset));
                    linearProjectedMeasure(:,counter) = projectionFromTheDataset  * normalizedDipoleDenisty';
                    counter = counter + 1;
                end;
                
                dipoleDensity = cat(2, dipoleDensity, dipoleDensityFromTheDataset');
                groupId = [groupId  dipoleAndMeasureForDataset.groupNumber(1)]; % get the group number of dataset                                
            end;
            
            numberOfSessions = size(linearProjectedMeasure, 2);
            
            % place each condition in a different cell for more convenience
            if nargout > 1
                sessionConditionCell = {};
                for i=1:numberOfSessions
                    conditionCell = obj.getSeparatedConditionsForLinearizedMeasure(linearProjectedMeasure(:,i))';
                    for j=1:length(conditionCell)
                        sessionConditionCell{i,j} = conditionCell{j};
                    end;
                end;
            end;
            
            % get the total dipole density
            dipoleDensity  = sum(dipoleDensity);
        end
                
        function [differenceBetweenConditions significanceValue] = getMeasureDifferenceAcrossConditions(obj, headGrid, regionOfInterestCube, projectionParameter, twoConditionIdsForComparison, usePositionProjections, varargin)
            % [differenceBetweenConditions significanceValue] = getMeasureDifferenceAcrossConditions(obj, headGrid, regionOfInterestCube, projectionParameter, twoConditionIdsForComparison, usePositionProjections, [optional statcond() statistics parameters])
            %
            % usePositionProjections specifies how different projected measures for different positions are used.
            % It can be 'each' to indicate using all projections for each session as independent
            % measurement (for example if they are from a Domain, if we have 20 positions in the domain 
            % and 10 subjects, there will be 20*10 = 200 measurements passed to statcond). 
            % The other choice for usePositionProjectionsis is 'mean', in which case only
            % the average of the measure over given positions will be used from each session.
            
            
            % first we project each dataset separately to the given location, then we separate
            % projected values for each condition and calculate statitics
            
            % by default compare first and second conditions
            if nargin < 4
                twoConditionIdsForComparison = [1 2];
            end;
            
            % by default use each projected position for each session as an independent measurement.
            if nargin < 5 || isempty(usePositionProjections)
                usePositionProjections = 'each';
            end;
            
            % go through all sessions and project session dipoles to the given position(s)
            [linearProjectedMeasure groupId uniqeDatasetId dipoleDensity] = obj.getProjectedMeasureForEachSession(headGrid, regionOfInterestCube, projectionParameter);
            
            if strcmpi(usePositionProjections, 'each')
                % add all projected measures from all subjects together, Multiple position for each
                % subject will contribute.
                linearProjectedMeasureForCombinedCondition = reshape(linearProjectedMeasure, size(linearProjectedMeasure,1), []);                
            else % when it is 'mean'
                % we average the linearized measure over all the given position, which are in the second
                % dimension.
                
                % linearProjectedMeasureForCombinedCondition = squeeze(mean(linearProjectedMeasure,2));
                
                % weight the projected values by dipole density
                % some sessions may have zero dipole denisty,
                linearProjectedMeasureForCombinedCondition = zeros(size(linearProjectedMeasure, 1), size(linearProjectedMeasure, 3));
                sessionsWithZeroDipoleDensity = [];
                for sessionNumber= 1:size(dipoleDensity, 2)
                    sessionTotalDipoleDenisty = sum(dipoleDensity(:,sessionNumber));
                    
                    if sessionTotalDipoleDenisty > 0
                        normalizedSessionDensity = dipoleDensity(:,sessionNumber) / sessionTotalDipoleDenisty;
                        linearProjectedMeasureForCombinedCondition(:, sessionNumber) = squeeze(linearProjectedMeasure(:,:,sessionNumber)) * normalizedSessionDensity;
                    else
                        sessionsWithZeroDipoleDensity = [sessionsWithZeroDipoleDensity sessionNumber];
                    end;
                end;
                
                % remove sessions with exactly zero dipole denisty
                linearProjectedMeasureForCombinedCondition(:, sessionsWithZeroDipoleDensity) = [];
            end;
            
            for coditionNumber = obj.conditionId
                projectedMeasure{coditionNumber} = [];
            end;
            
            for datasetCounter = 1:size(linearProjectedMeasureForCombinedCondition,2)
                projectedMeasureForDatasetWithConditionsSeparated = obj.getSeparatedConditionsForLinearizedMeasure(linearProjectedMeasureForCombinedCondition(:,datasetCounter));
                
                % separate conditions (they are concatenated in the time dimension).
                for coditionNumber = 1:length(obj.conditionId)
                    projectedMeasure{coditionNumber} = cat(3, projectedMeasure{coditionNumber}, projectedMeasureForDatasetWithConditionsSeparated{coditionNumber});
                end;
            end;
            
            % default statiscal method
            %             if isempty(varargin)
            %                  varargin = {'mode', 'perm', 'naccu', 250};
            %             end;
            
            % calculate statistical significance
            [differenceBetweenConditions degreesOfFreedom significanceValue] = statcond(projectedMeasure(twoConditionIdsForComparison)', varargin{:});
        end
        
        function [groupConditionMean differenceBetweenGroups significanceValue] = getMeasureDifferenceAcrossGroups(obj, headGrid, regionOfInterestCube, projectionParameter, twoGroupIdsForComparison, conditionToCompareId, usePositionProjections, varargin)
            % [differenceBetweenGroups significanceValue] = getMeasureDifferenceAcrossGroups(obj, headGrid, regionOfInterestCube, projectionParameter, twoGroupIdsForComparison, conditionId, [optional statcond() statistics parameters])
            
            % first we project each dataset separately to the given location, then we separate
            % projected values for the condition of interest and calculate statiticsfor given groups
            
            % by default compare first and second group
            if nargin < 4
                twoGroupIdsForComparison = [1 2];
            end;
                    
            % by default compare the first condition across groups
            if nargin < 5
                twoConditionIdsForComparison = 1;
            end;
            
            % by default use each projected position for each session as an independent measurement.
            if nargin < 6 || isempty(usePositionProjections)
                usePositionProjections = 'mean';
            end;
            
            % go through all sessions and project session dipoles to the given position(s)
            [linearProjectedMeasure datasetGroupNumber] = obj.getProjectedMeasureForEachSession(headGrid, regionOfInterestCube, projectionParameter);
            
            if strcmpi(usePositionProjections, 'each')
                % add all projected measures from all subjects together, Multiple position for each
                % subject will contribute.
                linearProjectedMeasureForCombinedCondition = reshape(linearProjectedMeasure, size(linearProjectedMeasure,1), []);
                datasetGroupNumber = repmat(datasetGroupNumber, size(linearProjectedMeasure,2),1);
                datasetGroupNumber =  reshape(datasetGroupNumber, 1, []);
            else % when usePositionProjections = 'mean'
                % average the linearized measure over all the given position, which are in the second
                % dimension.
                linearProjectedMeasureForCombinedCondition = squeeze(mean(linearProjectedMeasure,2));
            end;
            
            for groupNumber = 1:obj.numberOfGroups
                projectedMeasure{groupNumber} = [];
            end;
            
            for datasetCounter = 1:size(linearProjectedMeasureForCombinedCondition,2)
                projectedMeasureForDatasetWithConditionsSeparated = obj.getSeparatedConditionsForLinearizedMeasure(linearProjectedMeasureForCombinedCondition(:,datasetCounter));
                
                % separate conditions (they are concatenated in the time dimension).
                for coditionNumber = obj.conditionId
                    projectedMeasure{datasetGroupNumber(datasetCounter)} = cat(3, projectedMeasure{datasetGroupNumber(datasetCounter)}, projectedMeasureForDatasetWithConditionsSeparated{conditionToCompareId});
                end;
            end;
            
            % calculate group-mean for the condition and place them in a cell-array.
            for i=1:2
                groupConditionMean{i} = mean(projectedMeasure{twoGroupIdsForComparison(i)},3);
            end;
            
            % default statiscal method
            %  if isempty(varargin)
            %       varargin = {'mode', 'perm', 'naccu', 250};
            %  end;
            
            % calculate statistical significance
            [differenceBetweenGroups degreesOfFreedom significanceValue] = statcond(projectedMeasure(twoGroupIdsForComparison), varargin{:});
        end
        
        function figureHandle = plot(obj, linearProjectedMeasureForCombinedCondition, varargin)
            % figureHandle = plot(obj, linearProjectedMeasureForCombinedCondition, varargin)
            % figureHandle is an array of handles to figures produced.
            % varargin is for passing parameters to the plotting function
            
            projectedMeasure = obj.getSeparatedConditionsForLinearizedMeasure(linearProjectedMeasureForCombinedCondition);
            figureHandle = obj.plotMeasureAsArrayInCell(projectedMeasure, obj.conditionLabel, varargin{:});
        end;
        
        function plotConditionDifference(obj, linearProjectedMeasureForCombinedCondition, headGrid, regionOfInterestCube, projectionParameter, twoConditionLabelsForComparison, significanceLevelForConditionDifference, usePositionProjections, statisticsParameter, plottingParameter)
            % plotConditionDifference(linearProjectedMeasureForCombinedCondition, headGrid, regionOfInterestCube, projectionParameter, twoConditionLabelsForComparison, significanceLevelForConditionDifference, statisticsParameter, plottingParameter)
            %
            % plot condition difference between first and second specified conditions (A-B) and
            % mask areas with non-significent differences.
            
            % if no condition label is provided, use the first two (if they exist)
            if nargin < 5 || isempty(twoConditionLabelsForComparison)
                if length(obj.conditionLabel) > 1
                    twoConditionIdsForComparison = [1 2];
                    twoConditionLabelsForComparison = obj.conditionLabel;
                    
                    % when there are more than two conditions present, give a warning
                    if length(obj.conditionLabel) > 2
                        fprintf('Warning: there are more than two conditons present, by default only the difference between the first two is displayed. You can assign another condition pair in the input.\n');
                    end;
                else
                    error('There is only one condition present, at least two conditions are needed for a comparison\n');
                end;
            else % if condition labels for comparison are provided, then find condition ids in obj.conditionLabel that are associated with them.                
                if length(twoConditionLabelsForComparison) < 2
                    error('Number of provided condition labels is less than required two (2).\n');
                end;
                
                % find condition ids in obj.conditionLabel that are associated with provided conditon labels.
                for i=1:2
                    twoConditionIdsForComparison(i) = find(strcmp(obj.conditionLabel, twoConditionLabelsForComparison{i}));
                end;
            end
            
            if nargin < 6
                significanceLevelForConditionDifference = 0.03;                
            end;
            
            if nargin < 7
                usePositionProjections = 'mean'; % default is mean since we currently do not have a good way to incorporate session dipole denisties when 'each' statistics is used.
            end;
            
            if nargin < 8               
                statisticsParameter = {};
            end;
            
            if nargin < 9               
                plottingParameter = {};
            end;
            
            
            % separate conditions from linearized form
            projectedMeasure = obj.getSeparatedConditionsForLinearizedMeasure(linearProjectedMeasureForCombinedCondition);
            
            % only keep the two conditions to be compared
            projectedMeasure = projectedMeasure(twoConditionIdsForComparison);
            
            % calculate difference statistics for two conditions
            [differenceBetweenConditions significanceValue] = obj.getMeasureDifferenceAcrossConditions(headGrid, regionOfInterestCube, projectionParameter, twoConditionIdsForComparison, usePositionProjections,statisticsParameter{:});
            
            % calculate difference between the two conditions and add as the third measure for
            % plotting
            projectedMeasure{3} = projectedMeasure{1} - projectedMeasure{2};
                        
            % mask insignificent differences
            projectedMeasure{3}(significanceValue > significanceLevelForConditionDifference) = 0;
            
            % since when plotting, the mean spectra is automatically added for spectra, we should
            % add the negative of it so it is canccled out.
            if strcmp(obj.measureLabel, 'Spec')
                projectedMeasure{3} = projectedMeasure{3} - obj.specMeanOverAllIcAndCondition;
            end;
            
            % set the titles
            conditionTitle = [obj.conditionLabel{twoConditionIdsForComparison(1)} ' - ' obj.conditionLabel{twoConditionIdsForComparison(2)} ' (p<' num2str(significanceLevelForConditionDifference) ')'];
            
            title = [obj.conditionLabel(twoConditionIdsForComparison), conditionTitle];
            
            % plot
            obj.plotMeasureAsArrayInCell(projectedMeasure, title, plottingParameter{:});
        end
        
        function plotGroupDifference(obj, linearProjectedMeasureForCombinedCondition, headGrid, regionOfInterestCube, projectionParameter, twoGroupLabelsForComparison, conditionLabelForComparison, significanceLevelForConditionDifference, usePositionProjections, statisticsParameter, plottingParameter)
            % plotGroupDifference(obj, linearProjectedMeasureForCombinedCondition, headGrid, regionOfInterestCube, projectionParameter, twoGroupLabelsForComparison, conditionLabelsForComparison, significanceLevelForConditionDifference, statisticsParameter, plottingParameter)
            %
            % plot group projected measures and their difference for a given condition. The difference is calculated between the first and second specified group (A-B) 
            % Areas with non-significent differences are masked.
            
            % if no group label is provided, use the first two (if they exist)
            if nargin < 5 || isempty(twoGroupLabelsForComparison)
                if obj.numberOfGroups  > 1
                    twoGroupIdsForComparison = [1 2];
                    twoGroupLabelsForComparison = obj.uniqueGroupName(twoGroupIdsForComparison);
                    
                    % when there are more than two conditions present, give a warning
                    if obj.numberOfGroups > 2
                        fprintf('Warning: there are more than two groups present, by default only the difference between the first two is displayed. You can assign another group pair in the input.\n');
                    end;
                else
                    error('There is only one group present, at least two groups are needed for a comparison\n');
                end;
            else % if group labels for comparison are provided, then find group ids (numbers) in obj.uniqueGroupName that are associated with them.                
                if length(twoGroupLabelsForComparison) < 2
                    error('Number of provided condition labels is less than required two (2).\n');
                end;
                
                % find group ids in obj.uniqueGroupName that are associated with provided group labels.
                for i=1:2
                    twoGroupIdsForComparison(i) = find(strcmp(obj.uniqueGroupName, twoGroupLabelsForComparison{i}));
                end;
            end
            
            % if no condition label was specified, by default use the first condition
            if nargin < 6 || isempty(conditionLabelForComparison)
                conditionToCompareId = 1;
                conditionLabelForComparison = obj.conditionLabel{conditionToCompareId};
            else % othrwise find the condition id associated with the provided condition label.
                conditionToCompareId = find(strcmp(obj.conditionLabel, conditionLabelForComparison));                
            end;
            
            if nargin < 7
                significanceLevelForConditionDifference = 0.03;                
            end;
            
            if nargin < 8
                usePositionProjections = 'mean';
            end;
            
            if nargin < 9               
                statisticsParameter = {};
            end;
            
            if nargin < 10               
                plottingParameter = {};
            end;
            
            % calculate difference statistics for two groups on one condition
            [groupConditionMean differenceBetweenGroups significanceValue] = obj.getMeasureDifferenceAcrossGroups(headGrid, regionOfInterestCube, projectionParameter, twoGroupIdsForComparison, conditionToCompareId, usePositionProjections, statisticsParameter{:});            
            projectedMeasure = groupConditionMean;
                       
            % calculate difference between the two groups and add it as the third measure for
            % plotting
            projectedMeasure{3} = projectedMeasure{1} - projectedMeasure{2};
            
            % mask insignificent differences
            projectedMeasure{3}(significanceValue > significanceLevelForConditionDifference) = 0;
            
            
            % since when plotting, the mean spectra is automatically added for spectra, we should
            % add the negative of it so it is canccled out.
            if strcmp(obj.measureLabel, 'Spec')
                projectedMeasure{3} = projectedMeasure{3} - obj.specMeanOverAllIcAndCondition;
            end;
            
            % set the titles
            groupDifferenceTitle = ['Condition ' conditionLabelForComparison ', Group ' twoGroupLabelsForComparison{1} ' - ' twoGroupLabelsForComparison{2} ' (p<' num2str(significanceLevelForConditionDifference) ')'];
            
            title = [twoGroupLabelsForComparison, groupDifferenceTitle];
            
            plottingParameter = {};
            % a ahck
            
            % plot
            obj.plotMeasureAsArrayInCell(projectedMeasure, title, plottingParameter{:});
        end
        
        function plotDipoleMeasure(obj, dipoleNumber, varargin)
            obj.plot(obj.linearizedMeasure(:, dipoleNumber))
        end;		
				
		function obj = removeDuplicateDipoles(obj)
			% for some reason dual dipoles are read twice when reading from STUDY.
			theSame = false(obj.numberOfDipoles);
			for i=1:obj.numberOfDipoles
				for j=(i+1):obj.numberOfDipoles
					if  obj.numberInDataset(i) == obj.numberInDataset(j) && obj.datasetId(i) == obj.datasetId(j) &&    all(obj.location(i,:) - obj.location(j,:) < eps) &&  all(obj.direction(i,:) - obj.direction(j,:) < eps)
						theSame(i,j) = true;
						theSame(j,i) = true;
					end;
				end;
			end;
			
			icToKeep = true(obj.numberOfDipoles, 1);
			for i=1:size(theSame,1)
				if any(theSame(i,1:i))
					icToKeep(i) = false;
				end;
			end;
			
			obj = obj.createSubsetForId(icToKeep, false);
		end;
		
    end    
end
