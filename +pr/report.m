classdef report <  wikimarkup
    properties
        reportName
        reportFolder % top-level folder uner which all files are placed.
        imagesAndFiguresFolderName = 'images_and_figures'; % sub-folder in the top-level folder which contains all images and figures (png, eps, fig...)
        imageExtensions = {'png' 'eps' 'fig'};
        defaultOutputIndexFileName = 'index.html';
        updateInBetween = true;   % update index.html while the report being generated (currently only after saving each image).
        showBrowserOnUpdate = true;
        matlabBrowserHandle = [];
        createConsoleLog = true; % create a log of Matlab outputs during creation of the report using diary() command of Matlab;
        logFilename = 'log.txt';
    end;
    
    properties (Access = 'protected')
        reportImagesAndFiguresFolderName
        originalDiaryState
        startTime
    end;
    
    methods
        function obj = report(reportName, reportFolder, varargin) % constructor
            obj = obj@wikimarkup(varargin{:}); % call the super class constructor
            
            obj.reportName = reportName;
            obj.reportFolder = reportFolder;
            
            obj.reportImagesAndFiguresFolderName = [obj.reportFolder filesep obj.imagesAndFiguresFolderName filesep];
            
            % create folders (top level and images folder)
            mkdir(obj.reportFolder);
            mkdir(obj.reportImagesAndFiguresFolderName);
            
            % initialize the log (matlab diary)
            if obj.createConsoleLog
                obj.originalDiaryState = get(0,'Diary');
                diary([obj.reportFolder filesep obj.logFilename]);
            end;
            
            % save start time to measure how long the report have taken to complete.
            obj.startTime = tic;
            
        end;
        
        function insertFigureAndSaveWithAllExtensions(obj, figureHandle, fileNamewithoutExtension, closeFigure)
            % insertFigureAndSaveWithAllExtensions(obj, figureHandle, fileNamewithoutExtension, closeFigure)
            % save the figure with all the extensions and add (insert) the image (png) to the (html
            % or other type) report.
            
            % make sure figure proportions are not changed during saving
            set(figureHandle, 'PaperPositionMode', 'auto')
                        
            if nargin < 4
                closeFigure = true;
            end;
                        
            for imageTypeNumber=1:length(obj.imageExtensions)
                fileName = [obj.reportImagesAndFiguresFolderName fileNamewithoutExtension '.' obj.imageExtensions{imageTypeNumber}];
                try
                    switch obj.imageExtensions{imageTypeNumber}
                        case 'png'
                            print(figureHandle, '-dpng', '-r120',fileName);
                        case 'jpg'
                            print(figureHandle, '-djpg', '-r120', fileName);
                        otherwise
                            saveas(figureHandle, fileName);
                    end;
                catch err
                    fprintf(['For this reason: ' err.identifier ' the file ' fileName ' could not be saved.\n']);
                end;
            end;
            
            % close the hidden figures use to make images
            if closeFigure
                close(figureHandle);
            end;
            
            obj.addImage([obj.imagesAndFiguresFolderName filesep fileNamewithoutExtension '.png']);
            
            % by default update the index.html output after adding each new image.
            % this could be useful when looking at report images already finishd while the rest of
            % the report in being generated.
            if obj.updateInBetween
                obj.saveHtml;
                obj.openMatlabBrowserIfNotAlreadyOpen;
                pause(1); % pause until it is open
                obj.reloadMatlabBrowser;
                obj.updateLogIfActive
            end;
        end;
        
        function saveHtml(obj, indexFileName)
            %  saveHtml(obj, indexFileName)
            
            if nargin < 2
                indexFileName = obj.defaultOutputIndexFileName;
            else% change the defualt index file name to point to the last saved index file.
                obj.defaultOutputIndexFileName = indexFileName;
            end;
            
             obj.printWiki([obj.reportFolder indexFileName]);
        end;
        
        function reloadMatlabBrowser(obj)
            if ~isempty(obj.matlabBrowserHandle) && obj.matlabBrowserHandle.isValid
                obj.matlabBrowserHandle.reload;
            end;
        end;
        
        function openMatlabBrowserIfNotAlreadyOpen(obj)
            if isempty(obj.matlabBrowserHandle) || ~obj.matlabBrowserHandle.isValid
                try
                    [stat obj.matlabBrowserHandle] = web([obj.reportFolder obj.defaultOutputIndexFileName]);
                catch
                    fprintf('Matlab browser could not be initiated. You can always use an external browser (e.g. FireFox or Chrome) and \n open the report from %s instead.', [obj.reportFolder obj.defaultOutputIndexFileName]);
                end;
            end;
        end;
        
        function delete(obj)            
            % return diary state to original
            if obj.createConsoleLog                
                set(0,'Diary', obj.originalDiaryState);
            end;
        end;
        
        function updateLogIfActive(obj)
            if obj.createConsoleLog
                diary off;
                pause(0.1);
                diary on;
            end;
        end;
        
        function insertReportCompletionTime(obj)            
            duration = toc (obj.startTime); % in seconds
            obj.addText(sprintf('It took %3.2d seconds (%3.2f hours) to create this report.', round(duration), duration / 3600));
        end;
        
        function finalize(obj)
            % finalize(obj)
            % inserts compilation time, saves html and refreshes the Matlab browser which is
            % displaying the results (optionally, if showBrowserOnUpdate is set to true)
            
            obj.insertReportCompletionTime;
            obj.saveHtml;
            if obj.showBrowserOnUpdate
                obj.reloadMatlabBrowser;
            end;
            
            % return diary state to original
            if obj.createConsoleLog
                set(0,'Diary', obj.originalDiaryState);
            end;
        end;
    end;
end