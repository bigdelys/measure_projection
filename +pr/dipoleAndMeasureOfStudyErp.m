classdef dipoleAndMeasureOfStudyErp < pr.dipoleAndMeasureOfStudy
    % holds ERPs from one or several conditions in a linearized way.
    % the first dimension is the linearized version of the ERP for concatenated subset of
    % consitions.
    % the second dimension of value is dipoles.
    properties
        time  = []; % an array that hold the times (in ms) associated with the measure.
    end % properties
    methods (Access = 'protected')
        function figureHandle = plotMeasureAsArrayInCell(obj, measureAsArrayInCell, title, varargin)
            numberOfConditionsInEachFigure = 6;
            if length(measureAsArrayInCell) <= numberOfConditionsInEachFigure
                % put ERP traces together inone plot;
                pr.std_plotcurve(obj.time, measureAsArrayInCell', 'titles', {'' ''}, 'datatype','erp', 'plotconditions', 'together','plotgroups', 'apart',varargin{:});
                
                % put legend for conditions
                legend(title);
                
                % make lines thicker.
                set(findobj(gcf, 'type', 'Line'), 'linewidth', 2)
                figureHandle = gcf;
            else  % plot in multiple figures if there are many conditions
                numberOfFigures = ceil(length(measureAsArrayInCell) / 6);
                for i=1:numberOfFigures
                    startCondition = ((i-1) * numberOfConditionsInEachFigure) + 1;
                    endCondition = min(length(measureAsArrayInCell), i * numberOfConditionsInEachFigure);
                    pr.std_plotcurve(obj.time, measureAsArrayInCell(startCondition:endCondition), 'titles', title(startCondition:endCondition), 'datatype','erp', varargin{:});
                    figureHandle(i) = gcf;
                end;
            end;
        end;
    end;
    methods
        function obj= dipoleAndMeasureOfStudyErp(STUDY, ALLEEG, varargin) % constructor
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
            
            obj.numberOfMeasureDimensions = 1; % number of dimensions in measure
            obj.measureLabel = 'ERP';
            
            if nargin > 0                
                
                [erpFilterStructure.b, erpFilterStructure.a] = butter(2,20/(ALLEEG(1).srate / 2),'low');
                
                try
                    
                    [measure obj.time] = pr.read_measure_from_design(STUDY, ALLEEG, 'erp', obj.conditionLabel, erpFilterStructure);
                    
                    % to get the selected subset and most importantly, deal with repeated dipoles
                    % (who have been originally bilateral)
                    obj.linearizedMeasure = measure(:,obj.icIndexForEachDipole);                    
                catch
                   
                    % read from old study format
                    try
                        [STUDY, erpdataConditionByGroup] = std_readerp(STUDY, ALLEEG,  'clusters', 1);
                    catch
                    end;
                    
                    % if session is the second independent variable in the design, we have to combine
                    % different sessions.                    
                    
                    % perform a 20 Hz lowpass before comparing ERPs, this will reduce the noise and create better
                    if isfield(STUDY, 'design') && strcmpi(STUDY.design(STUDY.currentdesign).variable(2).label, 'session')
                        collapsedOnSession = cell(size(erpdataConditionByGroup,1), 1);
                        for i=1:size(collapsedOnSession,1)
                            collapsedOnSession{i} = cat(2,erpdataConditionByGroup{i,:});
                        end;
                        erpdataConditionByGroup = collapsedOnSession;
                        clear collapsedOnSession;
                    end;
                    
                    % combine conditions in each group, then combine groups together
                    try
                        for group=1:obj.numberOfGroups
                            
                            % lowpass filter each condition for each group
                            for i=1:size(erpdataConditionByGroup,1)
                                clustinfo.erpdata{i, group} = filtfilt(erpFilterStructure.b, erpFilterStructure.a, double(erpdataConditionByGroup{i, group}));
                            end;
                            
                            combinedConditions{group} = cat(1,clustinfo.erpdata{obj.conditionId,group});
                        end;
                    catch exception
                        fprintf('Error in concatenating condition. Some conditions for certain subjects might be missing.\n');
                        disp(exception.message);
                    end;
                    
                    icCombinedErp = cat(2, combinedConditions{:});
                    obj.linearizedMeasure = icCombinedErp(:,obj.icIndexForEachDipole);
                end;
				
				% if time values could not be read from the design file, read them
				% from cluster(1) of study.
				if isempty(obj.time)
					obj.time = STUDY.cluster(1).erptimes;
				end;
				
				[obj  subsetId obj.removedIc.outsideBrain]= createSubsetInRelationToBrain(obj, obj.relationshipToBrainVolume);
				
				% for some reason bilateral dipoles are represented twice when they are read from
				% STUDY, here we remove the dubplicates.
				% obj = removeDuplicateDipoles(obj);
				
				% remove eye ICs
				if obj.removedIc.eye.removed
                    [obj eyeObj] = createSubsetWithoutEye(obj, obj.removedIc.eye.removalThreshold);
                    fprintf([num2str(eyeObj.scalpmap.numberOfScalpmaps) ' remaining eye ICs removed.\n']);
                    obj.removedIc.eye.object = eyeObj; % keep removed eye ICs.
                end;
                
				% correct the polarity of ERP measure based on scalpmap normalization polarities.
				% different dipole ERPs are located in the second dimension
				obj.linearizedMeasure = obj.linearizedMeasure .* repmat(obj.scalpmap.normalizationPolarity(:)', size(obj.linearizedMeasure,1),1);				
			end;
        end;
		
		 function newObj = createSubsetForId(obj, subsetId, renormalizeScalpmapPolarity)
			% we need to apply new normalization polarity to ERP measure after each new slicing.
			 if nargin < 3
                renormalizeScalpmapPolarity = true;
            end;
			
			if any(subsetId < 1)
				subsetId = logical(subsetId);
			end;
			
			normalizationPolarityBefore = obj.scalpmap.normalizationPolarity;
			newObj = createSubsetForId@pr.dipoleAndMeasureOfStudy(obj, subsetId, renormalizeScalpmapPolarity);
			
			if ~isempty(normalizationPolarityBefore)
				newObj.linearizedMeasure = newObj.linearizedMeasure .* repmat(newObj.scalpmap.normalizationPolarity(:)' ./ vec(normalizationPolarityBefore(subsetId))', size(newObj.linearizedMeasure,1),1);
			end;
		 end;
		
    end;
end