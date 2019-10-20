classdef studyDipole < pr.dipoleAndSubjectName
    properties
        numberOfGroups
        insideBrain % a logical array that indicates wether each IC is inside brain volume.
        datasetId % an array containing dataset Ids associates with dipoles.
        datasetIdAllConditions % an array containing dataset Ids associates with dipoles for all the conditions. This is a Condition x IC array.
        groupName % an array containing group names associates with dipoles.
        groupNumber % an array containing group numbers associates with dipoles. Please notice that group numbers are very different from group names, they are just created to have an integer reference to group names (instead of using group names which are of type string).
        uniqueGroupName
        numberInDataset   % an array containing the number of dipole IC in the associated EEG dataset. for example, if the dipole is from component number 5 in the dataset, this number will be 5.
    end % properties
    properties %(Access = 'protected')
        icIndexForEachDipole   % since there may be more than one dipole associated with each IC, this variables keeps track of which IC indices (in the study) are associated with each dipole.
    end;
    methods
        function obj = studyDipole(STUDY, ALLEEG) % constructor
                       
            if isempty(STUDY)
                error('Measure Projection: No EEGLAB study is present. Please first load a study.');
            end;
            
            obj = obj@pr.dipoleAndSubjectName();            
            
            % check and make sure that all the dipoles coordinate formats
            % are either all in MNI space or all in Spherical coordinates.            
            coordinateFormat = {};
            counter = 1;
            for datasetNumber = 1:length(ALLEEG)
                if ~isempty(ALLEEG(datasetNumber).dipfit) % some ALLEEG datasets might not have an empty .dipfit field.
                    coordinateFormat{counter} = ALLEEG(datasetNumber).dipfit.coordformat;
                    counter = counter + 1;
                end;
            end;
            
            inputDipoleCoordinateFormat = unique(lower(coordinateFormat));
            
            if length(inputDipoleCoordinateFormat) > 1
                error('All dipoles in ALLEEG sturcture (e.g. ALLEEG(1).dipfit.coordformat) should be in the same coordinate format (either all MNI or all spherical).');
            end;
            
            % read dipole information
            [STUDY clustinfo] = std_readdata(STUDY,ALLEEG,'clusters', 1,'infotype','dipole');
            clustinfo = STUDY.cluster(1);
            
            obj.numberOfGroups = max(length(STUDY.group), 1); % at least one group is present, even if it is not explicitly defined.
            
            if isfield(clustinfo, 'alldipoles') % for EEGLAB 9b forward
                dipoles = clustinfo.alldipoles;
            else % for previous EEGLAB versions                                               
                % combine conditions in each group, then combine groups together
                for group=1:obj.numberOfGroups
                    combinedConditions{group} = cat(1,clustinfo.dipoles{1,group}); % only dipoles from the first condition
                end;
                
                dipoles = cat(2, combinedConditions{:});
            end;
            
                               
            % import dipoles int the toolbox, create multiple entirs for ICs with two bilateral
            % dipoles. This sets obj.location and obj.direction fields.
            [obj obj.icIndexForEachDipole]= convert_dipole_structure_to_array(dipoles, obj);           
            
            % make all the dipoles are in MNI coordinates. If they are in Spherical coordinates,
            % convert them to MNI.
            if strcmpi(inputDipoleCoordinateFormat, 'spherical')
                obj = obj.convertDipoleCoordinatesFromSphericalToMni;
            end;
            
            
            % find out which ICs are inside brain volume
            % first try using sourcedepth() function to cvalculate exact distance to brain surface
            try 
                brainVolume =  load('standard_BEM_vol.mat'); % use MNI standard volume for dipole depth
                depth = sourcedepth(obj.location , brainVolume.vol)';
                obj.insideBrain = depth < 0; % this value is in mm
            catch % if that failed, use a precomputed 1-mm spacing grid on which inside and outside brain 
                  % locations are marked. Points closer to in-brain locations or close than a
                  % threshold to some in-brain locations are marked as inside brain.  This is
                  % mostly accurate (with about 1-2 percent error compared to exact calculation
                  % using sourcedepth().
                fprintf('Do not worry... falling back to using grid locations for in-brain dipole calculations...\n');               
                highResolutionBrainGrid = load('MNI_VoxelTsearch1.mat');
                obj.insideBrain = zeros(1, size(obj.location,1));
                
                for i=1:size(obj.location, 1)
                    distanceToInside = min(pr.pdist2_fast(highResolutionBrainGrid.allpoints(:,highResolutionBrainGrid.Inside)', obj.location(i,:)));
                    distanceToOutside= min(pr.pdist2_fast(highResolutionBrainGrid.allpoints(:,highResolutionBrainGrid.Outside)', obj.location(i,:)));
                    
                    minDIstanceToInside(i) =  min(distanceToInside);
                    obj.insideBrain(i) = minDIstanceToInside (i) < min(distanceToOutside) | minDIstanceToInside (i) < 2;
                end;
            end;
                        
            icSubjectAndGroup = get_ic_subject_and_group(STUDY);
            
            obj.datasetId = icSubjectAndGroup.icDatasetId(obj.icIndexForEachDipole);
            obj.datasetIdAllConditions = icSubjectAndGroup.icDatasetIdAllConditions(:,obj.icIndexForEachDipole);
            obj.subjectName = icSubjectAndGroup.icSubjectName(obj.icIndexForEachDipole);
            obj.groupName = icSubjectAndGroup.icGroupName(obj.icIndexForEachDipole);
            obj.groupNumber = icSubjectAndGroup.icGroupNumber(obj.icIndexForEachDipole);
            obj.subjectNumber = icSubjectAndGroup.icSubjectNumber(obj.icIndexForEachDipole);
            obj.uniqueSubjectName = icSubjectAndGroup.uniqueSubjectName;
            obj.uniqueGroupName = icSubjectAndGroup.uniqueSubjectGroup;
            obj.numberInDataset = clustinfo.comps(obj.icIndexForEachDipole);
        end;        
    end;
    methods (Access = protected) % only seen from itself and derived classes
        function subsetId = getSubsetIdForGroup(obj, groupNameOrNumber, insideOrOutsideBrain)
            
            % by default only select dipoles inside brain
            if nargin<3
                insideOrOutsideBrain = 'insidebrain';
            end;
            
            if ischar(groupNameOrNumber)
                groupNameOrNumber= {groupNameOrNumber}; % turn single string into cell
            end;
            
            if isnumeric(groupNameOrNumber) % if it is an array of group numbers, turn them into a cell array of group names.
                for i=1:length(groupNameOrNumber)
                    groupNameOrNumberCell{i} = obj.uniqueGroupName{groupNameOrNumber(i)};
                end;
                
                groupNameOrNumber = groupNameOrNumberCell;
            end;
            
            for i=1:length(obj.groupName)
                subsetId(i) = ismember(obj.groupName{i}, groupNameOrNumber);
            end;
            
            
            switch insideOrOutsideBrain
                case 'insidebrain'
                    subsetId = subsetId & obj.insideBrain;
                case 'outsidebrain'
                    subsetId = subsetId & ~obj.insideBrain;
                case 'anywhere'
                    % nothing to do here.
                otherwise
                    error(['Wrong parameter for inside or outside brain: ' insideOrOutsideBrain]);
            end;
        end;
        function subsetId = getSubsetIdForSubject(obj, subjectNameOrNumber, insideOrOutsideBrain)
            
            % by default only select dipoles inside brain
            if nargin<3
                insideOrOutsideBrain = 'insidebrain';
            end;
            
            if ischar(subjectNameOrNumber)
                subjectNameOrNumber= {subjectNameOrNumber}; % turn single string into cell
            end;
            
            if isnumeric(subjectNameOrNumber) % if it is an array of subject numbers, turn them into a cell array of subject names.
                for i=1:length(subjectNameOrNumber)
                    subjectNameOrNumberCell{i} = obj.uniqueSubjectName{subjectNameOrNumber(i)};
                end;
                
                subjectNameOrNumber = subjectNameOrNumberCell;
            end;
            
            for i=1:length(obj.subjectName)
                subsetId(i) = ismember(obj.subjectName{i}, subjectNameOrNumber);
            end;
            
            
            switch insideOrOutsideBrain
                case 'insidebrain'
                    subsetId = subsetId & obj.insideBrain;
                case 'outsidebrain'
                    subsetId = subsetId & ~obj.insideBrain;
                case 'anywhere'
                    % nothing to do here.
                otherwise
                    error(['Wrong parameter for inside or outside brain: ' insideOrOutsideBrain]);
            end;
        end;
        function subsetId = getSubsetIdInRelationToBrain(obj, insideOrOutsideBrain)
            
            % by default only select dipoles inside brain
            if nargin<2
                insideOrOutsideBrain = 'insidebrain';
            end;          
            
            switch insideOrOutsideBrain
                case 'insidebrain'
                    subsetId = obj.insideBrain;
                case 'outsidebrain'
                    subsetId = ~obj.insideBrain;
                case 'any'
                    % select all dipoles (inside and outside brain).
                    subsetId = 1:length(obj.insideBrain);
                otherwise
                    error(['Wrong parameter for inside or outside brain: ' insideOrOutsideBrain]);
            end;
        end
    end;
end