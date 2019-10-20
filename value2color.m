function color = value2color(value, colorMap)
% color = value2color(value, colorMap)
% maps values to colors using the given colorMap after normalizing values (to map to colormap
% range).
% color map can be a color map function handle, for example @jet, @ lines 
% or a colormap matrix (e.g. jet, or lines).

if nargin<2
    colorMap = @jet;
end;

if isa(colorMap ,'function_handle')
    colorMap = colorMap(length(value));
end;

value = value - min(value);
value = value / max(value);

% project to colornap
ids = ceil(value * size(colorMap,1));
ids = max(1, ids);
ids = min(size(colorMap,1), ids);

color = colorMap(ids,:);
