classdef dipoleAndMeasureOfStudyErsp < pr.dipoleAndMeasureOfStudy
    % holds ERPs from one or several conditions in a linearized way.
    % the first dimension is the linearized version of the ERSP for concatenated subset of
    % consitions.
    % the second dimension of value is dipoles.
    properties
        time  = []; % an array that hold the times (in ms) associated with the ERSP.
        frequency = []; % an array that hold the frequencies (in Hz) associated with the ERSP.
    end % properties
    methods (Access = 'protected')
        function figureHandle = plotMeasureAsArrayInCell(obj, measureAsArrayInCell, title, varargin)
            numberOfConditionsInEachFigure = 6;
            if length(measureAsArrayInCell) < 10
                std_plottf(obj.time, obj.frequency, measureAsArrayInCell,   'titles', title, varargin{:});
                figureHandle = gcf;
            else
                numberOfFigures = ceil(length(measureAsArrayInCell) / numberOfConditionsInEachFigure);
                for i=1:numberOfFigures
                    startCondition = ((i-1) * numberOfConditionsInEachFigure) + 1;
                    endCondition = min(length(measureAsArrayInCell), i * numberOfConditionsInEachFigure);
                    std_plottf(obj.time, obj.frequency, measureAsArrayInCell(startCondition:endCondition),   'titles', title(startCondition:endCondition), varargin{:});
                    figureHandle(i) = gcf;
                end;
            end;
        end;
    end;
    methods
        function obj = dipoleAndMeasureOfStudyErsp(STUDY, ALLEEG, varargin) % constructor
            superClassArgs = {};
            
            if nargin>1
                superClassArgs{1} = STUDY;
                superClassArgs{2} = ALLEEG;
            end;
            
            if nargin>2
                for i=1:length(varargin) % pass additional parameters in varargin to parent dipoleAndMeasureOfStudy class
                    superClassArgs{2+i} = varargin{i};
                end;
            end;
            
            obj = obj@pr.dipoleAndMeasureOfStudy(superClassArgs{:}); % call the super class constructor
            
            obj.numberOfMeasureDimensions = 2; % number of dimensions in measure
            obj.measureLabel = 'ERSP';
            
            if nargin > 0
                                
                try % first try reading directly from the design (since std_read**() are unreliabe)
                    % only read requested conditions.
                    [measure obj.time obj.frequency] = pr.read_measure_from_design(STUDY, ALLEEG, 'ersp', obj.conditionLabel);
                    
                    % to get the selected subset and most importantly, deal with repeated dipoles
                    % (who have been originally bilateral)
                    erspdataWithCompsFirst = permute(measure,[3 1 2]);
                    obj.linearizedMeasure = erspdataWithCompsFirst(obj.icIndexForEachDipole,:)';
                catch % if it fails (for example on older version of eeglab witough desing)
                    % if session is the second independent variable in the design, we have to combine
                    % different sessions.
                    
                    try
                        [STUDY, erspdataConditionByGroup] = std_readersp(STUDY, ALLEEG,  'clusters', 1);
                    catch
                        error('Measure Projection cannot import ERSP data (may not have been pre-computed yet).');
                    end;
                    
                    % if session is the second variable in the design collapse on it.
					if isfield(STUDY, 'design') && strcmpi(STUDY.design(STUDY.currentdesign).variable(2).label, 'session')
                        collapsedOnSession = cell(size(erspdataConditionByGroup,1), 1);
                        for i=1:size(collapsedOnSession,1)
                            collapsedOnSession{i} = cat(ndims(erspdataConditionByGroup{1,1}),erspdataConditionByGroup{i,:});
                        end;
                        
                        erspdataConditionByGroup = collapsedOnSession;
                        clear collapsedOnSession;
                    end;
                    
					% if session is the first variable in the design collapse on it.
					if isfield(STUDY, 'design') && strcmpi(STUDY.design(STUDY.currentdesign).variable(1).label, 'session')
						%collapsedOnSession = cell(size(erspdataConditionByGroup,2), 1);
						collapsedOnSession = [];
						for i=1:size(erspdataConditionByGroup,2) % across conditions
							collapsedOnSession{i} = cat(3,erspdataConditionByGroup{:,i});
						end;
						erspdataConditionByGroup = collapsedOnSession;
						clear collapsedOnSession;
					end
					
                    % for some reason inm the new eeglab version matrices are freq x timez x dipoles
                    % (instead of time x freq x dipole), the cod below checks for that and transforms
                    % them to this format if necessary
                    if size(erspdataConditionByGroup{obj.conditionId(1),1},1) == length(STUDY.cluster(1).erspfreqs)
                        for i=1:size(erspdataConditionByGroup,1)
                            for j=1:size(erspdataConditionByGroup,2)
                                erspdataConditionByGroup{i,j} = permute( erspdataConditionByGroup{i,j},[2 1 3]);
                            end;
                        end;
                    end;
                    
                    % if group is a design variable, combine conditions in each group, then combine groups together
					if isfield(STUDY, 'design') && (strcmpi(STUDY.design(STUDY.currentdesign).variable(1).label, 'group') |strcmpi(STUDY.design(STUDY.currentdesign).variable(2).label, 'group')  )
						for group=1:obj.numberOfGroups
							combinedConditions{group} = cat(1, erspdataConditionByGroup{obj.conditionId,group});
						end;
						
						erspdata = cat(3, combinedConditions{:});
					else
						erspdata = cat(3, erspdataConditionByGroup{:});
					end;
                    
                                        
                    % swap dimensions and linearize 3D matrix
                    erspdataWithCompsFirst = permute(erspdata,[3 2 1]);
                    obj.linearizedMeasure = erspdataWithCompsFirst(obj.icIndexForEachDipole,:)';
                end;
                
                % if time and frequency values could not be read from the design file, read them
                % from cluster(1) of study.
                if isempty(obj.time)
                    obj.time = STUDY.cluster(1).ersptimes;
                end;
                
                if isempty(obj.frequency)
                    obj.frequency = STUDY.cluster(1).erspfreqs;
                end;
                
                % ToDO makes this an input variable.
                outlierThreshold = [-40 40];
                
                if any(obj.linearizedMeasure(:) < outlierThreshold(1))
                    fprintf(['Measure Projection warning: Some ERSP values were lower than ' num2str(outlierThreshold(1)) ' dBs, they are now set to this value.\n']);
                    obj.linearizedMeasure(obj.linearizedMeasure < outlierThreshold(1)) = outlierThreshold(1);
                end;
                
                if any(obj.linearizedMeasure(:) > outlierThreshold(2))
                    fprintf(['Measure Projection warning: Some ERSP values were higher than ' num2str(outlierThreshold(2)) ' dBs, they are now set to this value.\n']);
                    obj.linearizedMeasure(obj.linearizedMeasure > outlierThreshold(2)) = outlierThreshold(2);
                end;   
                
				[obj  subsetId obj.removedIc.outsideBrain]= createSubsetInRelationToBrain(obj, obj.relationshipToBrainVolume);
				
				% for some reason bilateral dipoles are represented twice when they are read from
				% STUDY, here we remove the dubplicates.
				%obj = removeDuplicateDipoles(obj);
				
                % remove eye ICs
                if obj.removedIc.eye.removed
                    [obj eyeObj] = createSubsetWithoutEye(obj, obj.removedIc.eye.removalThreshold);
                    fprintf([num2str(eyeObj.scalpmap.numberOfScalpmaps) ' remaining eye ICs removed.\n']);
                    obj.removedIc.eye.object = eyeObj; % keep removed eye ICs.
                end;
                
            end;
        end;
    end;
end