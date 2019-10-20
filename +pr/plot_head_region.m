function plot_head_region(headGrid, membershipCube, varargin)
% plot_head_region(headGrid, membershipCube, regionColor, regionOptions, showProjectedOnMrs, projectionAxis)

inputOptions = finputcheck(varargin, ...
    {'regionColor'         {'real' 'string'} [] [0.3 1 0.3]; ...
    'regionOptions'        'cell'    {} {};...
    'showProjectedOnMrs'   'boolean' [] true;
    'projectionAxis'       'real'    []  [1 2 3];...
    'projectionAlpha'      'real'    []  0.3;...
    });

if nargin < 5
    showProjectedOnMrs = true;
end;

position = headGrid.getPosition(membershipCube);

serializedPatchValues = [];

for p = 1:size(position,1)
    cubeSize = headGrid.spacing;
    x= position(p,1) - cubeSize * 0.5 +  [0 1 1 0 0 0;1 1 0 0 1 1;1 1 0 0 1 1;0 1 1 0 0 0]*cubeSize;
    y=position(p,2) - cubeSize * 0.5 + [0 0 1 1 0 0;0 1 1 0 0 0;0 1 1 0 1 1;0 0 1 1 1 1]*cubeSize;
    z=position(p,3) - cubeSize * 0.5 + [0 0 0 0 0 1;0 0 0 0 0 1;1 1 1 1 0 1;1 1 1 1 0 1]*cubeSize;
    for i=1:6
        
        % prevent face that are already plotted to be painted agains.
        if ~isempty(serializedPatchValues)
            potentialSerializedPatchValues = [mean(x(:,i));mean(y(:,i));mean(z(:,i))];
            difference  = serializedPatchValues(1:end-1,:) - repmat(potentialSerializedPatchValues, 1, size(serializedPatchValues,2));
            sumAbsoluteDifference = max(abs(difference));
            sameFaceId  = find(sumAbsoluteDifference < eps);
            
            % delete faces inside (between) other faces (cubes).
            if ~isempty(sameFaceId) && ishandle(serializedPatchValues(end, sameFaceId))
                delete(serializedPatchValues(end, sameFaceId));
            end;
        end;
        
        if isempty(serializedPatchValues) || ~any(sumAbsoluteDifference < eps)
            h=patch(x(:,i),y(:,i),z(:,i),'r');
                        
            serializedPatchValues = cat(2, serializedPatchValues, [mean(x(:,i));mean(y(:,i));mean(z(:,i)); h]);            
            
            set(h,'facecolor', inputOptions.regionColor);
            if nargin > 3 && ~isempty(inputOptions.regionOptions)
                set(h, inputOptions.regionOptions{:});
            end;
        end;
    end
end;

if inputOptions.showProjectedOnMrs
    pr.plot_head_region_projected_on_mrs(headGrid, membershipCube, inputOptions.regionColor, inputOptions.regionOptions, inputOptions.projectionAxis, inputOptions.projectionAlpha);
end;