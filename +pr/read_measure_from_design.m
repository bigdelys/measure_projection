function [measure range1 range2 param] = read_measure_from_design(STUDY, ALLEEG, measureType, conditionLabelToRead, erpFilterStructure)
% [measure param range1 range2] = read_measure_from_design(STUDY, ALLEEG, measureType, conditionLabelToRead)
% conditionLabelToRead is a cell array of condition labels that should be inlcluded when reading
% (empty or unspecified -> all).
% param range1 range2 are returned from std_readfile(). and contains time or frequency... info,
% depending on the type of masure.

strcom = measureType;
cluster_ind = 1;
measure = [];
icNumber = [];

% 20Hz lowpass filter design for ERP
if strcmpi(measureType, 'erp')
    [b,a] = butter(2,20/(ALLEEG(1).srate / 2),'low');
end;

% find design variable associated with the condition so we can read condition labels
conditionVariableId = [];
for i=1: length(STUDY.design(STUDY.currentdesign).variable)
    if strcmpi(STUDY.design(STUDY.currentdesign).variable(i).label, 'condition') | strcmpi(STUDY.design(STUDY.currentdesign).variable(i).label, 'type')
        conditionVariableId = i;
        break;
    end;
end;

if isempty(conditionVariableId)
    fprintf('Measure Projection toolbox: Condition variable could not be found in the design.\nYour condition choices cannot be applied.\n');
else
    conditionLabelsFromDesign = STUDY.design(STUDY.currentdesign).variable(conditionVariableId).value;
    if nargin < 4 || isempty(conditionLabelToRead) % if not condition subset is specified, read all condition data
        conditionIdsToRead = 1:length(conditionLabelsFromDesign);
    else % otherwise find the subset IDs and only concatenate those down below.
        conditionIdsToRead = [];
        for i=1:length(conditionLabelsFromDesign)
            if ismember(pr.conditionStringFromCell(conditionLabelsFromDesign{i}), conditionLabelToRead)           
                conditionIdsToRead = [conditionIdsToRead i];
            end;
        end;
    end;
end;


for si = 1:size(STUDY.cluster(cluster_ind).sets,2)
    %STUDY.cluster = checkcentroidfield(STUDY.cluster, 'ersp', 'ersp_times', 'ersp_freqs', 'itc', 'itc_times', 'itc_freqs');
    tmpstruct = std_setcomps2cell(STUDY, STUDY.cluster(cluster_ind).sets(:,si), STUDY.cluster(cluster_ind).comps(si));
    cellinds  = [ tmpstruct.setinds{:} ];
    compinds  = [ tmpstruct.allinds{:} ];
    cells = STUDY.design(STUDY.currentdesign).cell(cellinds);
    fprintf('Pre-clustering array row %d, adding %s for design %d cell(s) [%s] component %d ...\n', si, upper(strcom), STUDY.currentdesign, int2str(cellinds), compinds(1));
    [X param range1 range2] = std_readfile( cells, 'components', compinds, 'measure', strcom);
    
    if strcmpi(measureType, 'erp')
        for i=1:size(X,2)
            X(:,i) = filtfilt(b,a, double(X(:,i)));
        end;
    end;
    
    if ndims(X) == 2 % like ERP
        % X  = X(:);
        tmp = [];
        for i=1:length(conditionIdsToRead)  %size(X, 3)
            % concatnetae different conditions across the time dimension.

            conditionData = squeeze(X(:,conditionIdsToRead(i)));
            
            % if a filter structre is provided in erpFilterStructure
            if nargin > 4
                conditionData = filtfilt(erpFilterStructure.b, erpFilterStructure.a, double(conditionData));
            end;
            
            tmp = cat(1, tmp, conditionData);
        end;
        X  = tmp;
    end;
    
    if ndims(X) == 3 % like ERSP and ITC
        tmp = [];
        for i=1:length(conditionIdsToRead)  %size(X, 3)
            % concatnetae different conditions across the time dimension.
            tmp = cat(2, tmp, squeeze(X(:,:,conditionIdsToRead(i))));
        end;
        X  = tmp;
    end;
    
    measure = cat(ndims(X)+1, measure, X);
end

measure = squeeze(measure);
