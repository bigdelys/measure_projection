function [valueOnFineGrid mri] = convert_coarse_grid_to_mri3d(valueOnCoarseGrid, gridX, gridY, gridZ)
% [valueOnFineGrid mri] = convert_coarse_grid_to_mri3d(valueOnCoarseGrid, gridX, gridY, gridZ)
% % mri3dplot(valueOnFineGrid, mri,    'mriview' , 'side');


% sumWeightedSimilarityMasked = sumWeightedSimilarity;
% brainPositionId = dipoleDensity > 0.03;
% sumWeightedSimilarityMasked(~insideBrain) = min(sumWeightedSimilarity(:));
% 
% 
% valueOnCoarseGrid  = sumWeightedSimilarityMasked;
% 

% load the output of dipoledenisty, which is a 3d array (prob3d) and the location of its points in
% 3D MNI coordinates from a file in the /private subfolder of Measure Projection toolbox. 
if exist('all_dipoledenity_points_in_mni_coordinates.mat', 'file')
    load all_dipoledenity_points_in_mni_coordinates.mat
else % if the file does not exist, calculate these values
    t.posxyz = [0 0 0];t.momxyz = [0 0 0];t.rv = 0;
    [prob3d, mri] = pr.dipoledensity(t,  'methodparam', 100, 'coordformat', 'MNI');
    
    if iscell(prob3d)
        prob3d = prob3d{1};
    end;
    
    g.subsample = 1;
    g.mri  = mri;
    [X Y Z]           = meshgrid(g.mri.xgrid(1:g.subsample:end)+g.subsample/2, ...
        g.mri.ygrid(1:g.subsample:end)+g.subsample/2, ...
        g.mri.zgrid(1:g.subsample:end)+g.subsample/2);
    [indX indY indZ ] = meshgrid(1:length(g.mri.xgrid(1:g.subsample:end)), ...
        1:length(g.mri.ygrid(1:g.subsample:end)), ...
        1:length(g.mri.zgrid(1:g.subsample:end)));
    allpoints = [ X(:)'    ; Y(:)'   ; Z(:)' ];
    allinds   = [ indX(:)' ; indY(:)'; indZ(:)' ];
    allpoints = g.mri.transform * [ allpoints ; ones(1, size(allpoints,2)) ];
    
    allpoints(4,:) = [];   
end;

mins = min(allpoints');
maxs = max(allpoints');
clear allpoints;

[dens3dGridX dens3dGridY dens3dGridZ] = ndgrid(linspace(mins(1), maxs(1), size(prob3d,1)),linspace(mins(2), maxs(2), size(prob3d,2)), linspace(mins(3), maxs(3), size(prob3d,3)));

try
    valueOnFineGrid = griddata3(gridX, gridY, gridZ, valueOnCoarseGrid, dens3dGridX, dens3dGridY, dens3dGridZ);
catch
    valueOnFineGrid = griddata(gridX, gridY, gridZ, valueOnCoarseGrid, dens3dGridX, dens3dGridY, dens3dGridZ);
end;

% we cannot have zeros
valueOnFineGrid = valueOnFineGrid - min(valueOnFineGrid(:)) + eps;

% set points outside brain to zero
valueOnFineGrid(~prob3d) = 0;


valueOnFineGrid = {valueOnFineGrid};