function remove_all_legends_from_figure(figureHandle)
handles = get(findobj(gcf, '-property', 'annotation'), 'annotation');

if ishandle(handles) % if a single value, then it is not a cell array of handles
    set(get(handles, 'LegendInformation'),'IconDisplayStyle', 'off');
else
for i=1:length(handles),
    set(get(handles{i}, 'LegendInformation'),'IconDisplayStyle', 'off');
end;
end;