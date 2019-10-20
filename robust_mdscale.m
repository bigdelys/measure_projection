function [pos stress] = robust_mdscale(inputMatrix, dimension, maximumNumberOfTries)
%  [pos stress] = robust_mdscale(inputMatrix, dimension, maximumNumberOfTries)
% this function is similar to to regular mdscale function but sometimes
% MDS gives an error: 'Unable to decrease criterion along line search direction.' and quits.
% To fix this we have to run it with random initial conditoions many times (~100)
% until it finds a solution. 

if nargin < 3
    maximumNumberOfTries = 100;
end;

counter  = 0;
pos = [];
stress = 0;;
while isempty(pos) && counter < maximumNumberOfTries % maximum ~100 tries
    try
        [pos stress]= mdscale(inputMatrix, dimension, 'options', statset('MaxIter', 500));
    catch
        try
            [pos stress]= mdscale(projectedMeasureSimilarity, dimension,  'Start', 'random'); % use random initial conditons instead of cmdscale
        catch
        end;
    end;
    counter = counter + 1;
end;

if isempty(pos)
    error('robust_mdscale: well, seems that some of these points are Really co-located...');
end;