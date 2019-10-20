function plot_cortex(cortexPointDomainDenisty, domainColor, varargin)

inputOptions = finputcheck(varargin, ...
    { 'lightAmount'       'real'     []                        0.75;... % the coefficient that controls the total amount of light in the scene
      'domainAlpha'       'real'     []                        1.2;... % the alpha blending coefficient which determines how much of domain colors are added to the underlying cortext colors
      'densityPower'      'real'     [0 2]                     0.7;... % to prevent very high values to dominate and mask the underlying cortical geometry, we  pass the values through a mild non-linearity with this power.
      'minimumDomainLight'  'real'     [0 5]                         0.1;...
      'minimumCortexLight'  'real'     [0 1]                         0.2;...
      'baseDomainLight'     'real'     [0 1]                         0.1;...
      'newFigure'           'boolean'   []  true;...
      'bestView'            'boolean'   []  true;...       % calculating optimal viewing angle.
      'minValueNormalizedTo' 'real'     [0 Inf] 0.1;...      % value to which the minimum projected domain intensity      
      'designer'             'string'    {'scott' 'nima'} 'scott';...
      'noiseAmplitude'       'real'     [0 Inf]   0.04;...
    });


if ischar(inputOptions)
    error(inputOptions);
end;

if strcmpi(inputOptions.designer, 'nima')
    inputOptions.densityPower = 0.87;
    inputOptions.domainAlpha = 1;
    inputOptions.baseDomainLight = 0.05;
    inputOptions.minimumCortexLight = 0;
end;

if inputOptions.newFigure
    figure;
end;

[dummy id ]= max(cortexPointDomainDenisty,[],2);
for i=1:length(id)
    otherProjections = setdiff(1:size(cortexPointDomainDenisty,2),id(i));
    cortexPointDomainDenisty(i,otherProjections) = 0;
end;

cortexPointDomainDenisty(:) = cortexPointDomainDenisty(:) .^ inputOptions.densityPower;

% load cortex vertices from example MNI
fsf = load('MNImesh_dipfit.mat');

% plot and create a matlab patch object
fsfHandle = plotmesh(fsf.faces, fsf.vertices, [], false);

set(gcf,'Renderer' ,'opengl');

% prevent resizing when rotation
set(gca, 'CameraViewAngleMode', 'manual');

% find the best viewing angle for given cortical surface density distribution (by summing up vectors
% from a center and placing the camera to look at that direction to cortex)
if inputOptions.bestView  && nargin > 0
    rotationCenter = [0 0 -15]; %-25 is good too, but maybe too high for frontal.
    density = sum(cortexPointDomainDenisty, 2);
    locationFromCenter = fsf.vertices - repmat(rotationCenter, [size(fsf.vertices, 1) 1]);
    normalizedLocationVector = locationFromCenter ./ repmat(sum(locationFromCenter .^ 2,2) .^ 0.5, [1 3]);
    
    % modulate vector lenght by dipole denisty
    normalizedLocationVector = normalizedLocationVector .* repmat(density(:), [1 3]);
    
    sumVectors = sum(normalizedLocationVector, 1);
    view(sumVectors);
else
    view([40 34]);
end;

zoom(1.7);

% need to keep normals since they are set to empty after lighting is turned off (in MATLAB 2015 and
% later)
figureUserData = struct;
figureUserData.fsfHandle = fsfHandle;
drawnow; % need to do this so normals are populated by MATLAB.
vertexNormals = get(fsfHandle, 'VertexNormals');
% make them have lenght 1
figureUserData.vertexNormals = vertexNormals ./ repmat(sum(vertexNormals .^2,2) .^ 0.5, [1 3]);
set(gcf, 'UserData', figureUserData);


% turn off lighting, since a custom method for visdualization is implemented
lighting none

%set(fsfHandle, 'facecolor', 'interp');

% edges with this alpha produce sharp silhouette corner lines.
set(fsfHandle, 'edgealpha', 0.2);
%set(fsfHandle, 'edgecolor', 'interp');

% black figure background
set(gcf, 'color', [0 0 0]);

% use camera position and surface normals to create a custom 'lighting' method which highlights
% cortex silhouette

% now adding data from projectionof domains into cortex (contained in cortexPointDomainDenisty matrix)
cortextDomainColor = 0;
totalDomainDensity = 0;
if exist('cortexPointDomainDenisty') && ~isempty(cortexPointDomainDenisty)
    for i = 1:size(cortexPointDomainDenisty, 2)
        cortexPointDomainDenisty(:,i) = inputOptions.minValueNormalizedTo * cortexPointDomainDenisty(:,i) / min(cortexPointDomainDenisty(cortexPointDomainDenisty(:,i)>eps, i));
        
        % combine into one color and density matrix
        cortextDomainColor =  cortextDomainColor + cortexPointDomainDenisty(:,i) * domainColor(i,:);
        totalDomainDensity = totalDomainDensity +  cortexPointDomainDenisty(:,i);
    end;
else
    cortextDomainColor = [];
end;

% add a toolbar with buttons to hide/show the hemispheres

toolbarHandle = uitoolbar(gcf);

% load icon images

leftIcon = load_icon(which('cortex_for_icon_left_black.png'));
rightIcon = load_icon(which('cortex_for_icon_right_black.png'));
bothIcon = load_icon(which('cortex_for_icon_both_black.png'));

% Create uipushtools in the toolbar
toolbarRightButtonHandle = uipushtool(toolbarHandle,'CData', rightIcon,...
    'TooltipString','Show only the Right hemisphere',...
    'ClickedCallback',...
    'pr.show_or_hide_cortex_hemisphere(''r'')');

toolbarLeftButtonHandle = uipushtool(toolbarHandle,'CData', leftIcon,...
    'TooltipString','Show only the Left hemisphere',...
    'ClickedCallback',...
    'pr.show_or_hide_cortex_hemisphere(''l'')');

toolbarBothButtonHandle = uipushtool(toolbarHandle,'CData', bothIcon,...
    'TooltipString','Show Both hemispheres',...
    'ClickedCallback',...
    'pr.show_or_hide_cortex_hemisphere(''b'')');

pr.cortex_plot_WindowButtonMotion(gcf, [], true, fsfHandle, cortextDomainColor, totalDomainDensity, inputOptions);
set(gcf, 'WindowButtonMotionFcn', {@pr.cortex_plot_WindowButtonMotion, false, fsfHandle, cortextDomainColor, totalDomainDensity, inputOptions});

% keep the background black when making snapshot images (to keep colors more visible in dark
% background)
set(gcf, 'InvertHardcopy', 'off');

end


% load a toolbar icon
function cols = load_icon(filename)
[cols,palette,alpha] = imread(filename);
if ~isempty(palette)
    error('This function does not handle palettized icons.'); end
cls = class(cols);
cols = double(cols);
cols = cols/double(intmax(cls));
cols([alpha,alpha,alpha]==0) = NaN;
end