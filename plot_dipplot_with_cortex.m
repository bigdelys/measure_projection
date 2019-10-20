function plot_dipplot_with_cortex(location, plotCortex, varargin)
%   plot_dipplot_with_cortex(location, varargin)

if nargin < 2
    plotCortex = true;
end;


if nargin < 1 || isempty(location)
    % dummy dipole
    dummyDipoleExistsAndShouldBeDeleted = true;
    sources(1).posxyz = [-95 -48 -28];
    sources(1).momxyz = [  0 58 -69];
    sources(1).rv     = 0.036;
    varargin = {'coordformat', 'MNI','spheres', 'on', 'dipolesize', 0, 'gui','off'};
else
    % create dummy source sturcture for dipplot, it will be removed later.
    dummyDipoleExistsAndShouldBeDeleted = false;
    sources = [];
    for i=1:size(location, 1)
        sources(i).posxyz = location(i,:);
        sources(i).momxyz = [0 0 0];
        sources(i).rv = 0.001;
    end;    
end;

if isempty(varargin)
    varargin =  {'coordformat', 'MNI'};
end;


dipfit.dipplot(sources, varargin{:});

% remove the dummy dipole
if dummyDipoleExistsAndShouldBeDeleted
    delete(findobj(gcf, 'tag', 'dipole1'));
end;

if plotCortex
    csf = load('standard_BEM_vol.mat'); % located in the measure projection toolbox folder
    % layer two (2) seems to be a bit larger than CSF of layer 3, so it
    % will not intersect less with stuff painted inside.
    
    csfVertices = csf.vol.bnd(2).pnt;
    
    hold on;    
    csfHandle = plotmesh(csf.vol.bnd(2).tri, csf.vol.bnd(2).pnt, [], false);
    set(csfHandle, 'facealpha',0.2);
    set(gcf,'Renderer' ,'opengl');
    reducepatch(csfHandle, 1/2); % 1/8
    
    % each call to dipplot adds two new lights, so we need to remove them all,
    % then add two lights
    delete(findobj(gca, 'type','light')); % nima: was gcf originally but that would not work right when multiple axis of these plots where in the same graph .
    
    camlight left;
    camlight right;
    
    % since each dipplot has a camzoom, we have to zoom out
    %camzoom(1/(1.2^(2*(length(clusterNumbers)-1))));
    
    set(gca, 'CameraViewAngleMode', 'manual');
end;

view([40 34]);