function componentId = connected_components(pairIsConnected)
%  componentId = connected_components(pairIsConnected)
%  Finds connected components from the adjacency matrix pairIsConnected
%  componentId have the component Id (starting from 1) for each node.

% First assigning each node a unique label and then
% going through the connetions and assigning the smallest label to each connected pair
% until there is no change in the labels.
positionLabel = 1:size(pairIsConnected, 1);

aLabelChanged = true;

for k = 1:length(positionLabel)
    if aLabelChanged
        aLabelChanged = false;
        for i=1:size(pairIsConnected, 1)
            for j=i:size(pairIsConnected, 1)
                if pairIsConnected(i,j) && positionLabel(i) ~= positionLabel(j)
                    newLabel = min(positionLabel(i), positionLabel(j));
                    positionLabel(positionLabel == positionLabel(i)) = newLabel;
                    positionLabel(positionLabel == positionLabel(j)) = newLabel;
                    aLabelChanged = true;
                end;
            end;
        end;
    else
        break;
    end;
end;

uniqueLabel = unique(positionLabel);

componentId = zeros(size(positionLabel));
for i=1:length(positionLabel)
    componentId(i) = find(positionLabel(i) == uniqueLabel);
end;