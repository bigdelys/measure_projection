function show_or_hide_cortex_hemisphere(side)
% side is right, left or both

brainSide = side(1);

figureUserData = get(gcf, 'UserData');
fsfHandle = figureUserData.fsfHandle;

vertices = get(fsfHandle, 'Vertices');

if strcmpi(brainSide, 'b') || strcmpi(brainSide, 'a') || strcmpi(brainSide, 'f')
    set(fsfHandle, 'edgealpha', 0.2);
    set(fsfHandle,'facealpha', 1);
elseif ismember(lower(brainSide), {'l' 'r' 'f' 'b' 'a'})
    
    if strcmpi(brainSide, 'r') || strcmpi(brainSide, 'l')
        vertexAlpha = vertices(:,1) + -0.01 *vertices(:,2)  > 0.0;
    end;
    
    if strcmpi(brainSide, 'r')
        vertexAlpha =  vertexAlpha & ~(vertices(:,2) <-60 & vertices(:,1) + 0.2 *vertices(:,2)  < -10);
    end;
    
    if strcmpi(brainSide, 'l')
        vertexAlpha = ~vertexAlpha;
    end;
    
    edgeAlpha = double(vertexAlpha) * 0.2;
    
    set(fsfHandle, 'FaceVertexAlphaData', double(vertexAlpha));
    set(fsfHandle,'facealpha', 'interp');
    
    set(fsfHandle,'edgealpha', 0);
end;