function conditionLabels = conditionStringFromCell(conditionLabels)
% conditionLabels = conditionStringFromCell(conditionLabels)
if iscell(conditionLabels)
    conditionLabels = strjoin(' & ', conditionLabels);
end;