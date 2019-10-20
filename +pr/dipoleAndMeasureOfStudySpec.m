classdef dipoleAndMeasureOfStudySpec < pr.dipoleAndMeasureOfStudy
    % holds ERPs from one or several conditions in a linearized way.
    % the first dimension is the linearized version of the Spectrum for concatenated subset of
    % consitions.
    % the second dimension of value is dipoles.
    properties
        frequency = [];
        specMeanOverAllIcAndCondition = [];
    end % properties
    methods (Access = 'protected')
        function figureHandle = plotMeasureAsArrayInCell(obj, measureAsArrayInCell, title, varargin)
            for i=1:length(measureAsArrayInCell)
                measureAsArrayInCell{i} = measureAsArrayInCell{i} + obj.specMeanOverAllIcAndCondition;
            end;
            std_plotcurve(obj.frequency, measureAsArrayInCell, 'titles', title, 'datatype','spec', varargin{:});
            figureHandle = gcf;
        end;
    end;
    methods
        function obj = dipoleAndMeasureOfStudySpec(STUDY, ALLEEG, varargin) % constructor
            % conditionId is an optional input that specifies which conditions should be included.
            % by default all conditions are included.
            
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
            obj.measureLabel = 'Spec';
            
            if nargin > 0

                try
                    try
                        [STUDY specdata ] = std_readspec(STUDY, ALLEEG, 'clusters', 1);
                    catch
                        [STUDY clustinfo] = std_readdata(STUDY,ALLEEG,'clusters',STUDY.etc.preclust.clustlevel,'infotype','spec');
                    end;
                    
                    [measure obj.frequency]= pr.read_measure_from_design(STUDY, ALLEEG, 'spec', obj.conditionLabel);
                    % to get the selected subset and most importantly, deal with repeated dipoles
                    % (who have been originally bilateral)
                    
                    obj.linearizedMeasure = measure(:,obj.icIndexForEachDipole);
                catch

                    try
                        [STUDY specdata ] = std_readspec(STUDY, ALLEEG, 'clusters', 1);
                        icCombinedSpec = cat(1, specdata{:});
                    catch
                        [STUDY clustinfo] = std_readdata(STUDY,ALLEEG,'clusters',STUDY.etc.preclust.clustlevel,'infotype','spec');
                        clustinfo = STUDY.cluster(STUDY.etc.preclust.clustlevel);
                        
                        % combine conditions in each group, then combine groups together
                        for group=1:obj.numberOfGroups
                            combinedConditions{group} = cat(1,clustinfo.specdata{obj.conditionId,group});
                        end;
                        
                        icCombinedSpec = cat(2, combinedConditions{:});
                    end;
                    
                    obj.linearizedMeasure = icCombinedSpec(:,obj.icIndexForEachDipole);
                end;
                
                % if frequency values could not be read from the design file, read them
                % from cluster(1) of study.
                if isempty(obj.frequency)
                    obj.frequency = STUDY.cluster(1).specfreqs;
                end;
                
                % normalized the spectrum by first removing the mean of the spectrum
                % of each component, and then calculating the mean across components and removing it
                % from all (this results is a more or less 'flat' spectrum for each IC).
                % the results is placed in obj.linearizedMeasure.
                % substracted mean spectrum over all ics and conditions is kept in obj.specMeanOverAllIcAndCondition
                
                
                specdataEachMeanRemoved = obj.linearizedMeasure - repmat(mean(obj.linearizedMeasure, 1), size(obj.linearizedMeasure,1), 1);
                
                specMeanOverAllIc= mean(specdataEachMeanRemoved, 2);
                specMeanOverCondition =  obj.getSeparatedConditionsForLinearizedMeasure(specMeanOverAllIc);
                obj.specMeanOverAllIcAndCondition = mean(cell2mat(specMeanOverCondition),2);
                
                obj.linearizedMeasure = specdataEachMeanRemoved - repmat(repmat(obj.specMeanOverAllIcAndCondition,length(specMeanOverCondition),1), 1, size(obj.linearizedMeasure,2));
                
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