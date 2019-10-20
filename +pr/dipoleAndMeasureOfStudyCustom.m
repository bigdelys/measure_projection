classdef dipoleAndMeasureOfStudyCustom < pr.dipoleAndMeasureOfStudy
    methods(Access = 'protected')
        function figureHandle = plotMeasureAsArrayInCell(obj, measureAsArrayInCell, title, varargin)
            if min(size(measureAsArrayInCell)) == 1
                figureHandle = figure;                
                for i=1:length(measureAsArrayInCell)
                    subplot(1, length(measureAsArrayInCell), i);
                    plot(measureAsArrayInCell{i}, 'linewidth', 3);
                end;
            elseif ndims(measureAsArrayInCell) < 3
                figureHandle = figure;                
                for i=1:length(measureAsArrayInCell)
                    subplot(1, length(measureAsArrayInCell), i);
                    imagesc(measureAsArrayInCell{i});
                end;
            end;
        end;
    end;
    
    methods
        function obj = dipoleAndMeasureOfStudyCustom(STUDY, ALLEEG, varargin) % constructor
            obj = obj@pr.dipoleAndMeasureOfStudy(STUDY, ALLEEG);
        end;
    end;
end