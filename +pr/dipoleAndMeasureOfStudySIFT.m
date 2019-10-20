classdef dipoleAndMeasureOfStudySIFT < pr.dipoleAndMeasureOfStudy
    % Class to handle SIFT data
    % Tim Mullen, SCCN/INC/UCSD Aug, 2013
    properties
        time  = [];     % an array that hold the times (in ms) associated with the ERSP.
        frequency = []; % an array that hold the frequencies (in Hz) associated with the ERSP.
        estimator = ''; % name of SIFT estimator (dDTF, RPDC, etc)
    end % properties
    methods(Access = 'protected')
        function figureHandle = plotMeasureAsArrayInCell(obj, measureAsArrayInCell, titlestr, varargin)
            if isvector(measureAsArrayInCell{1})
                % plot [time x measure] or [freq x measure]
                figureHandle = figure;                
                for i=1:length(measureAsArrayInCell)
                    subplot(1, length(measureAsArrayInCell), i);
                    if length(obj.time)<=1
                        xvals = obj.frequency;
                        xlbl  = 'Frequency (Hz)';
                    else
                        xvals = obj.time/1000;
                        xlbl  = 'Time (sec)';
                    end
                    plot(measureAsArrayInCell{i}, 'linewidth', 3);
                    xlabel(xlbl);
                    ylabel([obj.estimator '  ' obj.measureLabel]);
                    title(titlestr{i});
                end;
            else
                % plot [time x freq x measure]
                figureHandle = figure;                
                for i=1:length(measureAsArrayInCell)
                    subplot(1, length(measureAsArrayInCell), i);
                    imagesc(obj.time/1000,obj.frequency,measureAsArrayInCell{i});
                    xlabel('Time (sec)');
                    ylabel('Frequency (Hz)');
                    title(titlestr{i});
                    suplabel([obj.estimator '  ' obj.measureLabel],'x');
                end;
            end;
        end;
    end;
    
    methods
        function obj = dipoleAndMeasureOfStudySIFT(STUDY, ALLEEG, varargin) % constructor
            obj = obj@pr.dipoleAndMeasureOfStudy(STUDY, ALLEEG);
        end;
    end;
end