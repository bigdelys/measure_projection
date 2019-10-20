function plot_head_region_projected_on_mrs(headGrid, membershipCube, regionColor, regionOptions, projectionAxis, projectionAlpha)

if nargin < 5 || isempty(projectionAxis)
    projectionAxis = [1 2 3];
end;

if nargin < 6
    projectionAlpha = 0.3;
end;

position = headGrid.getPosition(membershipCube);

serializedPatchValues = [];

for currentProjectionAxis = projectionAxis
    
    for p = 1:size(position,1)
        cubeSize = headGrid.spacing;
        x= position(p,1) - cubeSize * 0.5 + [0 1 1 0 0 0;1 1 0 0 1 1;1 1 0 0 1 1;0 1 1 0 0 0] * cubeSize;
        y= position(p,2) - cubeSize * 0.5 + [0 0 1 1 0 0;0 1 1 0 0 0;0 1 1 0 1 1;0 0 1 1 1 1] * cubeSize;
        z= position(p,3) - cubeSize * 0.5 + [0 0 0 0 0 1;0 0 0 0 0 1;1 1 1 1 0 1;1 1 1 1 0 1] * cubeSize;
        
        switch currentProjectionAxis
            case 1
                x = -90 + cubeSize * 0.5 + [0 1 1 0 0 0;1 1 0 0 1 1;1 1 0 0 1 1;0 1 1 0 0 0] * 0;
            case 2
                y = 90 - cubeSize * 0.5 + [0 0 1 1 0 0;0 1 1 0 0 0;0 1 1 0 1 1;0 0 1 1 1 1] * 0;
            case 3
                z = -72 + cubeSize * 0.5 + [0 0 0 0 0 1;0 0 0 0 0 1;1 1 1 1 0 1;1 1 1 1 0 1] * 0;
        end;
        
        for i=1:6
            
            % prevent face that are already plotted to be painted agains.
            if ~isempty(serializedPatchValues)
                potentialSerializedPatchValues = [mean(x(:,i));mean(y(:,i));mean(z(:,i))];
                difference  = serializedPatchValues(1:end-1,:) - repmat(potentialSerializedPatchValues, 1, size(serializedPatchValues,2));
                sumAbsoluteDifference = max(abs(difference));
                sameFaceId  = find(sumAbsoluteDifference < eps);
            end;
            
            if isempty(serializedPatchValues) || ~any(sumAbsoluteDifference < eps)
                h=patch(x(:,i),y(:,i),z(:,i),'r');
                
                serializedPatchValues = cat(2, serializedPatchValues, [mean(x(:,i));mean(y(:,i));mean(z(:,i)); h]);
                
                set(h,'facecolor',regionColor , 'facealpha', projectionAlpha, 'edgealpha', 0);
                
                if nargin > 3 && ~isempty(regionOptions)
                    set(h,regionOptions{:});
                end;
            end;
        end
    end;
end;