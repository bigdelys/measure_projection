function varargout = plot_head_surface(headGrid, membershipCube, varargin)
inputOptions = finputcheck(varargin, ...
    {'surfaceColor'              {'real' 'string'} [] [0.1 0.7 0.1]; ...[0.3 1 0.3]
    'surfaceOptions'             'cell'   {} {};...
    'showProjectedOnMrs'        'boolean' [] true;
    'projectionAxis'            'real'    []  [1 2 3];...
    'projectionAlpha'   	    'real'    []  0.15;...
    'potentialPower'            'real'    [1 5] 2;...
    'numberOfClosestNeighbors'  'integer' [1 25] 15;...
    'quality'                   'string'  {'lowest' 'low' 'medium' 'high' 'highest'} 'high';...
    'reductionFactor'           'real'    [1/16 1] 1/2;...
    'isosurfaceDistance'        'real'    [0 100]  headGrid.spacing * 0.5;...
    'mainLightType'             'string'  {'right' 'left' 'headlight'} 'right';...
    'secondaryLightIntensity'   'real'    [0 1]  0.2;...
    'mainLightIntensity'   'real'    [0 1]  0.8;...
    });


% if membershipCube matrix contains no points (no Domain locations), exit with a message.
if ~any(membershipCube(:))
    fprintf('Measure Projection: nothing to plot.\n');
    return;
end;

isoSurfaceDistance = inputOptions.isosurfaceDistance;

potentialPower = inputOptions.potentialPower;
numberOfClosestNeighbors = inputOptions.numberOfClosestNeighbors;

switch inputOptions.quality
    case 'lowest'
        spacing = 6;
    case 'low'
        spacing = 4;
    case 'medium'
        spacing = 3;
    case 'high'
        spacing = 2;
    case 'highest'
        spacing = 1.6;
end;

surfaceColor = inputOptions.surfaceColor;

% if the surface only has one color,otherwise surfaceColor should contain an m x 3 array of colors
% for linear indices of membershipCube.
singlecolorSurface = ischar(inputOptions.surfaceColor) || numel(inputOptions.surfaceColor) == 3;

domainLocation = headGrid.getPosition(membershipCube);

% read CSF locations
csf = load('standard_BEM_vol.mat'); % located in the measure projection toolbox folder
csfVertices = csf.vol.bnd(3).pnt;
distanceFromDomainLocationsToAllCSFLocations = pr.pdist2_fast(domainLocation, csfVertices);
CSFcenter = mean(csfVertices, 1);
distanceToKeepFromCSF = 2.5*isoSurfaceDistance;

for i=1:size(distanceFromDomainLocationsToAllCSFLocations, 1)
    [distanceToCSF id] = min(distanceFromDomainLocationsToAllCSFLocations(i,:));
    
    % if domain points is too close to the CSF, push it back perpendicularly so it maintains a
    % minimum constant distance
    if distanceToCSF < distanceToKeepFromCSF
        
        % use the triangles that is closest to the domain location
        
        % first find all the triangles that the closest point on CSF is a part of.
        [row column] = find(csf.vol.bnd(3).tri == id);
        
        % then find the centers of those triangles
        triangleVerticeId = csf.vol.bnd(3).tri(row,:);
        triangleCenter = zeros(size(triangleVerticeId, 1), 3);
        for j=1:size(triangleVerticeId, 1)
            triangleCenter(j,:) = mean(csfVertices(triangleVerticeId(j,:),:),1);
        end;
        
        % find the triangle with the closest center to the domain location
        triangleDistanceToDomainLocation = pr.pdist2_fast(triangleCenter, domainLocation(i,:));
        [minDistance closestTriangleId] = min(triangleDistanceToDomainLocation);
        
        % find the perpendicular vector of the closest triangle using cross product
        closestTrianglePoint1 = csfVertices(triangleVerticeId(closestTriangleId, 1),:);
        closestTrianglePoint2 =  csfVertices(triangleVerticeId(closestTriangleId, 2),:);
        closestTrianglePoint3 =  csfVertices(triangleVerticeId(closestTriangleId, 3),:);
        
        perpendicularVector = cross(closestTrianglePoint1 - closestTrianglePoint2, closestTrianglePoint1 - closestTrianglePoint3);
        
        % make sure the perpendicular vector points inside the CSF
        if perpendicularVector * (CSFcenter - triangleCenter(closestTriangleId,:))' < 0
            perpendicularVector = - perpendicularVector;
        end;
        
        perpendicularVector = (distanceToKeepFromCSF - 0*minDistance) * perpendicularVector / norm(perpendicularVector, 2);
        domainLocation(i,:) = domainLocation(i,:) + perpendicularVector;
        
    end;
end;

clear csf csfVertices;

% define a finer grid around domain locations (with some offset on each side)
offset = 2 * headGrid.spacing; % extra space from each side of domain location bounding box. We need to include this extra space to make sure all the surfaces are contained in the fine grid and can be closed.
[fineXCube fineYCube fineZCube] = meshgrid((min(domainLocation(:,1)) - offset):spacing:(max(domainLocation(:,1)) + offset),  (min(domainLocation(:,2)) - offset):spacing:(max(domainLocation(:,2)) + offset), (min(domainLocation(:,3)) - offset):spacing:(max(domainLocation(:,3)) + offset));

% use single instead ofdouble to save memory
fineXCube = single(fineXCube);
fineYCube = single(fineYCube);
fineZCube = single(fineZCube);
domainLocation = single(domainLocation);

fineGridPosition = [fineXCube(:) fineYCube(:) fineZCube(:)];

% define a (1/r^n) potential eminating from domain locations and find isopotential surfaces.
distance = pr.pdist2_fast(fineGridPosition, domainLocation);

% insted of sort we could consider looking only at points that are closer at least than some
% threshold to any domain location, then do the sort only on those selection

minimumDistanceToAnyDominLocation = min(distance,[], 2);
findGridPointCloseToDomainLocationId = minimumDistanceToAnyDominLocation < isoSurfaceDistance * 5; % only calculate potential for grid points as far as 5 times the isoSurfaceDistance. Grid locations that are very far will not be a part of the isosurface anyway.

sortedDistance = sort(distance(findGridPointCloseToDomainLocationId,:),2, 'ascend');
numberOfClosestNeighbors = min(numberOfClosestNeighbors, size(sortedDistance, 2));

sortedDistance = sortedDistance(:,1:numberOfClosestNeighbors);

clear distance;

potentialFromDomainLocation = sum((1 ./ sortedDistance) .^ potentialPower, 2);

clear sortedDistance;

potentialCube = zeros(size(fineXCube), 'single');
potentialCube(findGridPointCloseToDomainLocationId) = potentialFromDomainLocation;

isosurfaceFacesAndVerices = isosurface(fineXCube, fineYCube, fineZCube, potentialCube, 1/(isoSurfaceDistance ^ potentialPower));

% remove triangles (faces) that are not connected to any other triangle.
% first find faces that are only attached to one triangle (face), and then remove associated faces
% (triangles);
numberOfRepeatsForVertex = zeros(size(isosurfaceFacesAndVerices.vertices, 1),1, 'int16');
for i=1:numel(isosurfaceFacesAndVerices.faces)
    numberOfRepeatsForVertex(isosurfaceFacesAndVerices.faces(i)) = numberOfRepeatsForVertex(isosurfaceFacesAndVerices.faces(i)) + 1;
end;

% find voxels that only participate in one triangle
verticesForRemoval = find(numberOfRepeatsForVertex < 2);
clear numberOfRepeatsForVertexl
% find triangles conyaining these voxels
triangleForRemoval = any(ismember(isosurfaceFacesAndVerices.faces, verticesForRemoval), 2);
% remove these triangles from the surface
isosurfaceFacesAndVerices.faces(triangleForRemoval,:) = [];
clear triangleForRemoval

isosurafcePatch = patch(isosurfaceFacesAndVerices, 'SpecularColorReflectance', 0.2);

isonormals(fineXCube, fineYCube, fineZCube, potentialCube, isosurafcePatch);
clear potentialCube;

% create a color interpolation matrix for isosurface locations
if singlecolorSurface
    set(isosurafcePatch,'FaceColor', surfaceColor,'EdgeColor','none');
else % multi-color surface
    distanceOfSurfacePointsToDomainLocations = pr.pdist2_fast(isosurfaceFacesAndVerices.vertices, domainLocation);
    [sortedDistanceOfSurfacePointsToDomainLocations sortedSurfacePointId]= sort(distanceOfSurfacePointsToDomainLocations,2, 'ascend');
    clear distanceOfSurfacePointsToDomainLocations;
    potentialFromDomainLocationOnSurfacePoints = (1 ./ sortedDistanceOfSurfacePointsToDomainLocations(:,1:numberOfClosestNeighbors)) .^ potentialPower;
    sortedSurfacePointId = sortedSurfacePointId(:,1:numberOfClosestNeighbors);
    
    % normalize to for a simplex (positive values that sum up to one) for each surface points in
    % regards to to select top (~15) closest domain points.
    potentialFromDomainLocationOnSurfacePoints = potentialFromDomainLocationOnSurfacePoints ./ repmat(sum(potentialFromDomainLocationOnSurfacePoints, 2), 1, size(potentialFromDomainLocationOnSurfacePoints, 2));
    
    surfaceVertexColor = zeros(size(potentialFromDomainLocationOnSurfacePoints, 1), 3);
    for i=1:size(potentialFromDomainLocationOnSurfacePoints, 1)
        surfaceVertexColor(i,:) = potentialFromDomainLocationOnSurfacePoints(i,:) * surfaceColor(sortedSurfacePointId(i,:),:);
    end;
    
    clear potentialFromDomainLocationOnSurfacePoints sortedSurfacePointId;
    
    set(isosurafcePatch, 'Facecolor', 'flat');
    set(isosurafcePatch, 'edgeColor', 'none');
    set(isosurafcePatch, 'FaceVertexCData', surfaceVertexColor);
end;

if ~isempty(inputOptions.surfaceOptions)
    set(isosurafcePatch, inputOptions.surfaceOptions{:});
end;

if inputOptions.showProjectedOnMrs
    
    % projection of the isosurface at three MRI images on the sides
    projectedSurfaceOffset = 0.5; % The offset is to move it slightly away fron the MRI imag
    
    reducedIsosurfacePatch = reducepatch(isosurafcePatch, inputOptions.reductionFactor); 
       
    distanceFromReducedToOriginalVertices = pr.pdist2_fast(single(reducedIsosurfacePatch.vertices), isosurfaceFacesAndVerices.vertices);
    
    % interpolate colors for reduced resolution surface from full-resolution one.
    if ~singlecolorSurface
        [dummy closestVertexId]= min(distanceFromReducedToOriginalVertices, [], 2);
        reducedSurfaceVertexColor = surfaceVertexColor(closestVertexId,:);
    end;
    
    % side MRI
    if ismember(1, inputOptions.projectionAxis)
        isosurfaceFacesAndVericesProjectedOnSideMri = reducedIsosurfacePatch;
        isosurfaceFacesAndVericesProjectedOnSideMri.vertices(:,1) = -90 + projectedSurfaceOffset + isosurfaceFacesAndVericesProjectedOnSideMri.vertices(:,1) / 1000; % we added / 1000 to preserve Z order and prevent random changes while display when multiple z values are the same
        sideMriPatch = patch(isosurfaceFacesAndVericesProjectedOnSideMri);
    else
        sideMriPatch = [];
    end;
    
    % bottom MRI
    if ismember(3, inputOptions.projectionAxis)
        isosurfaceFacesAndVericesProjectedOnBottomMri = reducedIsosurfacePatch;
        isosurfaceFacesAndVericesProjectedOnBottomMri.vertices(:,3) = -72 + projectedSurfaceOffset + isosurfaceFacesAndVericesProjectedOnBottomMri.vertices(:,3) / 1000; % we added / 1000 to preserve Z order and prevent random changes while display when multiple z values are the same
        bottomMriPatch = patch(isosurfaceFacesAndVericesProjectedOnBottomMri);
    else
        bottomMriPatch = [];
    end;
    
    
    % front MRI
    if ismember(2, inputOptions.projectionAxis)
        isosurfaceFacesAndVericesProjectedOnFrontMri = reducedIsosurfacePatch;
        isosurfaceFacesAndVericesProjectedOnFrontMri.vertices(:,2) = 90 - projectedSurfaceOffset  + isosurfaceFacesAndVericesProjectedOnFrontMri.vertices(:,2) / 1000; % we added / 1000 to preserve Z order and prevent random changes while display when multiple z values are the same
        frontMriPatch = patch(isosurfaceFacesAndVericesProjectedOnFrontMri);
    else
        frontMriPatch = [];
    end;
    
    clear reducedIsosurfacePatch;
    
    set([bottomMriPatch sideMriPatch frontMriPatch],'EdgeColor', 'none', 'facealpha', inputOptions.projectionAlpha);
    
    if singlecolorSurface
        set([bottomMriPatch sideMriPatch frontMriPatch], 'FaceColor', surfaceColor);
    else
        set([bottomMriPatch sideMriPatch frontMriPatch], 'Facecolor', 'flat');
        set([bottomMriPatch sideMriPatch frontMriPatch], 'edgeColor', 'none');
        set([bottomMriPatch sideMriPatch frontMriPatch], 'FaceVertexCData', reducedSurfaceVertexColor);
    end
    
    if ~isempty(inputOptions.surfaceOptions)
        set([bottomMriPatch sideMriPatch frontMriPatch], inputOptions.surfaceOptions{:});
    end;
    
end;

sidelLightHandle = findobj(gcf, 'type', 'light');

% dim two light left and right of the camera postion
set(sidelLightHandle(1:2), 'color', inputOptions.secondaryLightIntensity*[1 1 1]);

headLightHandle = camlight(inputOptions.mainLightType);
set(headLightHandle, 'color', inputOptions.mainLightIntensity * [1 1 1]);

WindowButtonMotion(gcf, [], inputOptions.mainLightType);
set(gcf, 'WindowButtonMotionFcn', {@WindowButtonMotion, inputOptions.mainLightType});

lighting phong

    function WindowButtonMotion(handle, eventdata, lightLocation)        
        persistent lastCameraPosition;
        currentCameraPosition = campos;
        if isempty(lastCameraPosition) || any(currentCameraPosition ~= lastCameraPosition)
            lastCameraPosition = currentCameraPosition;
            h = findobj(handle, 'type', 'light');
            % update light 3 to shine from the camera position and give realistic 
             %camlight(h(3), 'headlight');   
             camlight(h(3), lightLocation); 
        end;
    end

end