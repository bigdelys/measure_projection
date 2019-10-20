function move_figures_into_subplots(fig, numberOfColumns, childAxisNumber)

if nargin < 2
    numberOfColumns = 1;
end;

if nargin < 3
    childAxisNumber = 2;
end;

numberOfRows = ceil(length(fig) / numberOfColumns);

hFigure = figure();                              % Create a new figure

for i=1:length(fig)
    hTemp = subplot(numberOfRows, numberOfColumns,i,'Parent',hFigure);         % Create a temporary subplot
    newPos = get(hTemp,'Position');                  % Get its position
    % delete(hTemp);                                   % Delete the subplot
    
    % get the first axis of the figure
    %axisHandle = get(fig(i),'CurrentAxes');
    %axisHandle = get(fig(i),'CurrentAxes');
    axisHandle = get(fig(i), 'children');
    
    set(axisHandle(childAxisNumber),'Parent',hFigure,'Position',newPos);  % Move axes to the new figure   
    
    close(fig(i));
end;
