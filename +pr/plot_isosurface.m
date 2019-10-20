function patchList = plot_isosurface(fieldValue, fieldValueThreshold, headGrid, surfaceColor, surfaceAlpha, spacing)

if nargin < 4
    surfaceColor = 'red';
end;

if nargin < 5
    surfaceAlpha = 1;
end;

if nargin < 6
    spacing = 2;
end;

fieldValueHigherThanThreshold = fieldValue >= fieldValueThreshold;

xMask = squeeze(any(any(fieldValueHigherThanThreshold, 2), 3));
yMask = squeeze(any(any(fieldValueHigherThanThreshold, 1), 3));
zMask = squeeze(any(any(fieldValueHigherThanThreshold, 1), 2));


xRangeId =  [max(1, find(xMask, 1, 'first') - 1) min(length(xMask), find(xMask, 1, 'last') + 1)];
yRangeId =  [max(1, find(yMask, 1, 'first') - 1) min(length(yMask), find(yMask, 1, 'last') + 1)];
zRangeId =  [max(1, find(zMask, 1, 'first') - 1) min(length(zMask), find(zMask, 1, 'last') + 1)];

%spacing = 1.05; % in mm, 1.5 is medium quality


[fineXCube fineYCube fineZCube] = meshgrid(headGrid.xCube(1, yRangeId(1),1 ,1):spacing:headGrid.xCube(1,yRangeId(2) ,1),  headGrid.yCube(xRangeId(1),1 ,1):spacing:headGrid.yCube(xRangeId(2),1 ,1),  headGrid.zCube(1,1 ,zRangeId(1)):spacing:headGrid.zCube(1, 1,zRangeId(2)));


% diffuse fieldValue values so they are extended to outside of the brain (to prevent artifact in the
% interpolation during over0sampling process)
smoothfieldValue = fieldValue;

for i=1:100
    smoothfieldValue = smooth3(smoothfieldValue, 'box', [5 5 5]);
    smoothfieldValue(headGrid.insideBrainCube) = fieldValue(headGrid.insideBrainCube);
end;

% a final minimal smoothing (including in-brain values) makes the image look nicer (isosurfaces much more smooth)
smoothfieldValue = smooth3(smoothfieldValue, 'gaussian', [3 3 3]);

% re-calculate the threshold for smoothed values.
%fieldValueThreshold = min(smoothfieldValue(fieldValueHigherThanThreshold));
%fieldValueHigherThanThreshold = fieldValue >= fieldValueThreshold;

%smoothfieldValue(~headGrid.insideBrainCube) = 0;

finefieldValue = interp3(headGrid.xCube, headGrid.yCube, headGrid.zCube, smoothfieldValue, fineXCube, fineYCube, fineZCube, 'cubic');

isosurfaceFacesAndVerices = isosurface(fineXCube, fineYCube, fineZCube, finefieldValue, fieldValueThreshold);


% projection of the isosurface at three MRI images on the sides

projectedSurfaceOffset = 0.5; % The offset is to move it slightly away fron the MRI image. 

% side MRI
isosurfaceFacesAndVericesProjectedOnSideMri = isosurfaceFacesAndVerices;
isosurfaceFacesAndVericesProjectedOnSideMri = reducepatch(isosurfaceFacesAndVericesProjectedOnSideMri, 1/16);
isosurfaceFacesAndVericesProjectedOnSideMri.vertices(:,1) = -90 + projectedSurfaceOffset;
sideMriPatch = patch(isosurfaceFacesAndVericesProjectedOnSideMri);

% bottom MRI
isosurfaceFacesAndVericesProjectedOnBottomMri = isosurfaceFacesAndVerices;
isosurfaceFacesAndVericesProjectedOnBottomMri = reducepatch(isosurfaceFacesAndVericesProjectedOnBottomMri, 1/16);
isosurfaceFacesAndVericesProjectedOnBottomMri.vertices(:,3) = -72 + projectedSurfaceOffset;
bottomMriPatch = patch(isosurfaceFacesAndVericesProjectedOnBottomMri);


% front MRI
isosurfaceFacesAndVericesProjectedOnFrontMri = isosurfaceFacesAndVerices;
isosurfaceFacesAndVericesProjectedOnFrontMri = reducepatch(isosurfaceFacesAndVericesProjectedOnFrontMri, 1/16);
isosurfaceFacesAndVericesProjectedOnFrontMri.vertices(:,2) = 90 - projectedSurfaceOffset;
frontMriPatch = patch(isosurfaceFacesAndVericesProjectedOnFrontMri);


isosurfacePatch = patch(isosurfaceFacesAndVerices);

smoothFinefieldValue= smooth3(finefieldValue, 'box', [11, 11 11]);
isonormals(fineXCube, fineYCube, fineZCube, smoothFinefieldValue, isosurfacePatch);

set(isosurfacePatch,'FaceColor', surfaceColor,'EdgeColor','none', 'facealpha', surfaceAlpha);

set([bottomMriPatch sideMriPatch frontMriPatch] ,'FaceColor', surfaceColor,'EdgeColor', 'none', 'facealpha', 0.1);


if nargout > 0
    patchList.main = isosurfaceFacesAndVerices;
    patchList.side = isosurfaceFacesAndVericesProjectedOnSideMri;
    patchList.bottom = isosurfaceFacesAndVericesProjectedOnBottomMri;
    patchList.front = isosurfaceFacesAndVericesProjectedOnFrontMri;
end;