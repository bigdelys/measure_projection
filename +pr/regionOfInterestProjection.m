classdef regionOfInterestProjection
    properties
        headGrid;
        projectionParameter
        similarity;
        convergence = [];
        convergenceSignificance = [];
        numberOfPermutations = 2500;
        pValueThreshold = 0.05;
        fdrThreshold
        
        roiProjection
        regionOfInterest
    end;
    
    
    methods
        function obj = regionOfInterestProjection(dipoleAndMeasure, similarity, headGrid, varargin)
            % obj = regionOfInterestProjection(dipoleAndMeasure, similarity, headGrid, varargin)
            
            inputOptions = finputcheck(varargin, ...
                {'stdOfDipoleGaussian'         'real'  [] 12; ...
                'numberOfPermutations'        'real'    [] obj.numberOfPermutations;...
                'numberOfStdsToTruncateGaussian'   'real'    []  3;...
                'normalizeInBrainDipoleDenisty'   'string'    {'on', 'off'}  'on';...
                'useSurrogateMaxConvergence'    'boolean'  [] false;...   % use an alternative way to calculate significance, using the distribution of max convergence values over all locations.
                });
            
            if nargin < 2
                similarity = []; % empty similarity indicates the request to not perform convergence significance computation.
            end;
            
            obj.similarity = similarity;
            
            if nargin < 3
                obj.headGrid = pr.headGrid;
            else
                obj.headGrid = headGrid;
            end;
            
            obj.numberOfPermutations = double(inputOptions.numberOfPermutations);
            obj.projectionParameter = pr.projectionParameter(inputOptions.stdOfDipoleGaussian, inputOptions.numberOfStdsToTruncateGaussian, strcmpi(inputOptions.normalizeInBrainDipoleDenisty, 'on'));
            
            
            roiLabels = pr.regionOfInterestFromAnatomy.getAllAnatomicalLabels;
            clear regionOfInterest;
            for i=1:length(roiLabels)
                regionOfInterest(i) = pr.regionOfInterestFromAnatomy(pr.headGrid, roiLabels{i});
            end;
            
            obj.regionOfInterest = regionOfInterest;
            clear regionOfInterest;
            
            if isempty(obj.similarity)
                obj.convergence = nan(length(obj.regionOfInterest), 1);
                obj.convergenceSignificance = zeros(length(obj.regionOfInterest), 1);
                obj.fdrThreshold = nan;
            else  % claculate the significanceof each region
                obj.convergence = zeros(length(obj.regionOfInterest), 1);
                
                similarity = similarity - diag(diag(similarity));
                
                pr.progress('init'); % start the text based progress bar
                for i = 1:length(obj.regionOfInterest)
                    [projectionMatrix totalDipoleDenisty gaussianWeightMatrix]= pr.meanProjection.getProjectionMatrix(dipoleAndMeasure, obj.headGrid, obj.projectionParameter, obj.regionOfInterest(i).membershipCube);
                    totalDensityInRoiForDipole =  sum(gaussianWeightMatrix,2);
                    [obj.convergence(i) obj.convergenceSignificance(i)] = pr.get_convergence_significance(similarity, totalDensityInRoiForDipole);
                    
                    pr.progress(i / length(obj.regionOfInterest) , sprintf('\npercent done %d/100',round(100*i /length(obj.regionOfInterest) )));
                end;
                
                obj.fdrThreshold = pr.fdr(obj.convergenceSignificance, obj.pValueThreshold);
            end;
            
            % project into ROIs, to save time do not project into non-significant regions
            clear roiProjection;
            for i=1:length(obj.regionOfInterest)
                if obj.convergenceSignificance(i) < 0.05
                    roiProjection(i) = pr.meanOfProjectionIntoRegionOfInterest(dipoleAndMeasure, pr.projectionParameter,  obj.regionOfInterest(i).membershipCube, obj.headGrid);
                else
                    roiProjection(i) = pr.meanOfProjectionIntoRegionOfInterest;
                end;
            end;
            
            obj.roiProjection = roiProjection;
            clear roiProjection;
            
            pr.progress('close'); % duo to some bug need a pause() before
            fprintf('\n');
        end;
        
        function reportFolder = makeReport(obj, reportName, reportTopFolder)
            
            if reportTopFolder(end) ~= filesep
                reportTopFolder = [reportTopFolder filesep];
            end;
            
            reportFolder = [reportTopFolder reportName filesep]; % top-level folder which contains the index fole underneath
            imagesAndFiguresFolderName = 'images_and_figures'; % sub-folder in the top-level folder which contains all images and figures (png, eps, fig...)
            reportImagesAndFiguresFolderName = [reportFolder filesep imagesAndFiguresFolderName filesep];
            imageExtensions = {'png' 'fig'}; % 'eps' could also be a good idea.
            
            % initiate and add some general description top the report
            autoReport = pr.report(reportName,reportFolder, 'html');
            
            autoReport.addSection(['ROI-MPT Report for ' reportName] );
            autoReport.addText(['Auto-generated by Measure Projection toolbox (MPT) on ' date '.' '<br>']); % <br> is to make it to go another line (it is line-break)
            %  autoReport.addText(['Study file: ' STUDY.filename ' located under ' STUDY.filepath ' folder.']);
            
            
            %reportPlot = {'volume' 'measure' 'meanScalpmap' 'scalpmap' 'dipole' 'coloredByDomain' };
            reportPlot = {'measure' 'volume'};
            
            measureName = 'ersp'; % must be lowercase
            
            % bulletList = {};
            % bulletList{1} = [upper(measureName) ' significance = ' num2str(STUDY.measureProjection.option.([measureName 'Significance']))];
            % if STUDY.measureProjection.option.([measureName 'FdrCorrection'])
            %     bulletList{1} = [bulletList{1} ' (corrected with FDR, final location significance threshold = ' num2str(STUDY.measureProjection.(measureName).projection.significanceLevelForDomain) ')'];
            % end;
            %
            % autoReport.addBulletList(bulletList,'Projection parameters:');
            
            % if ismember('coloredByDomain', reportPlot)
            %     autoReport.addSection('All Domains');
            %     autoReport.addText('Volume colored by domains (colors are based on multi-dimensional scaling of domain exemplars): ');
            %     % image path and file but without extension
            %     imageFilenameWithoutExtension = ['significant_volume_colored_by_domains'];
            %
            %     hiddenFigure = figure('visible', 'off');
            %     STUDY.measureProjection.(measureName).projection.plotVolumeColoredByDomain('newFigure', false);
            %
            %     autoReport.insertFigureAndSaveWithAllExtensions(hiddenFigure, imageFilenameWithoutExtension);
            % end;
            
            
            significantROI = find(obj.convergenceSignificance < 0.05);
            [dummy ord] = sort(obj.convergenceSignificance(significantROI), 'ascend');
            significantROI = significantROI(ord);
            
            % also check by 
            [corrected_p, isSignificantByBonfHolm]= pr.bonf_holm(obj.convergenceSignificance, 0.05);
            
            for i = 1:length(significantROI)
                
                autoReport.addSection([num2str(i) ' - ' obj.regionOfInterest(significantROI(i)).label]);
                roiFileName = strrep(obj.regionOfInterest(significantROI(i)).label, ' ', '_');
                
                statisticsText = ['Statistics: (p < ' num2str(obj.convergenceSignificance(significantROI(i)), 2) ')'];
                
                if obj.convergenceSignificance(significantROI(i)) < obj.fdrThreshold
					statisticsText = [statisticsText ', Significant after FDR with p < 0.05'];
				else
					statisticsText = [statisticsText ', <b>Non-significant</b> after FDR with p < 0.05'];
				end;
				
				if isSignificantByBonfHolm(significantROI(i))
					statisticsText = [statisticsText ', Significant after Bonferroni-Holm correction with p < 0.05'];
				else
					statisticsText = [statisticsText ', <b>Non-significant</b> after Bonferroni-Holm correction with p < 0.05'];
				end;
				
				statisticsText = [statisticsText '. <p></p>']; % an extra paragraph provies enough space between the text and the image.
				
				autoReport.addText(statisticsText);
				
				%% ROI volume
				if ismember('volume', reportPlot)
					%autoReport.addText('Region Of Interest (ROI): ');
					% image path and file but without extension
					imageFilenameWithoutExtension = [roiFileName '_volume'];
					
					hiddenFigure = figure('visible', 'off');
					obj.regionOfInterest(significantROI(i)).plotVolume('newFigure', false);
					
					autoReport.insertFigureAndSaveWithAllExtensions(hiddenFigure, imageFilenameWithoutExtension);
				end;
				%% domain dipoles
				%     if ismember('dipole', reportPlot)
				%         autoReport.addText('Highest contributing dipoles (greater than 0.05 of dipole mass contributed to Domain), colored by the (correlation) similarity of their activity to Domain exemplar:');
				%         % image path and file but without extension
				%         imageFilenameWithoutExtension = [roiFileName '_dipole'];
				%
				%         hiddenFigure = figure('visible', 'off');
				%         STUDY.measureProjection.(measureName).projection.domain(domainNumber).plotDipole( STUDY.measureProjection.(measureName).object, [1 0.05], 0.1, 'g', false);
				%
				%         autoReport.insertFigureAndSaveWithAllExtensions(hiddenFigure, imageFilenameWithoutExtension);
				%     end;
				%% domain measure (currently opens a figure that need to be closed later)
				if ismember('measure', reportPlot)
					autoReport.addText('Measure (p < 0.01): ');
					
					figureHandle = obj.roiProjection(significantROI(i)).plot(0.01);
					
					% save all the measure figures
					for figureCounter = 1:length(figureHandle)
						imageFilenameWithoutExtension = [roiFileName '_measure_' num2str(figureCounter)];
						autoReport.insertFigureAndSaveWithAllExtensions(figureHandle(figureCounter), imageFilenameWithoutExtension);
					end;
				end;
				%% ROI mean scalp-maps
				%     if ismember('meanScalpmap', reportPlot)
				%         autoReport.addText('Average scalpmap (weighted by dipole mass contributions to Domain):');
				%         % image path and file but without extension
				%         imageFilenameWithoutExtension = [roiFileName '_mean_scalpmap'];
				%
				%         hiddenFigure = figure('visible', 'off');
				%         STUDY.measureProjection.(measureName).projection.domain(domainNumber).plotMeanScalpMap('newFigure', false);
				%
				%         autoReport.insertFigureAndSaveWithAllExtensions(hiddenFigure, imageFilenameWithoutExtension);
				%     end;
				%% ROI scalp-maps
				%     if ismember('scalpmap', reportPlot)
				%         autoReport.addText('Highest contributing scalpmaps, sorted by the amount of dipole mass contributed to the Domain (only at most 100 ICs with greater than 5% of their mass inside domain are displayed):');
				%         % image path and file but without extension
				%         imageFilenameWithoutExtension = [roiFileName '_scalpmap'];
				%
				%         hiddenFigure = figure('visible', 'off');
				%         STUDY.measureProjection.(measureName).projection.domain(domainNumber).plotScalpMap('newFigure', false);
				%
				%         autoReport.insertFigureAndSaveWithAllExtensions(hiddenFigure, imageFilenameWithoutExtension);
				%     end;
			end;
			
			autoReport.finalize;
		end;
		
		function figureHandle = plotAllSignificantRegions(obj, varargin)
			% figureHandle = plotAllSignificantRegions(obj, varargin)
			
			            
            inputOptions = finputcheck(varargin, ...
                {'plotType'    'string'    {'together', 'separate'}  'together';...
                'coloring'     'string'    {'distinct', 'MDS'}  'on';...
                'pValueThreshold'   'real'    [0 1]  0.05;...                
                });
			
			significantROI = find(obj.convergenceSignificance < inputOptions.pValueThreshold);
			[dummy ord] = sort(obj.convergenceSignificance(significantROI), 'ascend');
			significantROI = significantROI(ord);
			
			if strcmpi(inputOptions.plotType, 'together') % plot all ROIs as one region
				combinedMembershipCube = false(size(obj.regionOfInterest(1).membershipCube));
				for i = 1:length(significantROI)
					if obj.convergenceSignificance(significantROI(i)) < obj.fdrThreshold
						combinedMembershipCube = combinedMembershipCube | obj.regionOfInterest(significantROI(i)).membershipCube;
					end;
				end;
				
				figureHandle = figure;
				plot_dipplot_with_cortex;
				pr.plot_head_surface(obj.headGrid, combinedMembershipCube);
				
			else % if strcmpi(inputOptions.plotType, 'separate') % plot each ROI separately
				significantROI = find(obj.convergenceSignificance < 0.05);
				[dummy ord] = sort(obj.convergenceSignificance(significantROI), 'ascend');
				significantROI = significantROI(ord);
				
				if strcmpi(inputOptions.coloring, 'distinct')
					roiColor = pr.get_distinct_colors(length(significantROI));
				else % inputOptions.coloring = 'MDS'
					meanLinearizedMeasure = [obj.roiProjection(significantROI).meanLinearizedProjectedMeasure];
					projectedMeasureDissimilarity = squareform(pdist(meanLinearizedMeasure','correlation'));
					
					[pos stress] = robust_mdscale(projectedMeasureDissimilarity, 1);
					
					% make sure that domain colors are not exactly the same or very similar to each
					% other.
					for i=1:100
						d = squareform(pdist(pos));
						for j=1:size(d,1)
							for k=1:(j-1)
								if d(j,k) < 0.15
									middle = (pos(j) + pos(k)) / 2;
									pos(j) = middle - 0.05;
									pos(k) = middle + 0.05;
								end;
							end;
						end;
					end;
					
					% try to normalize the colors (1-D MDS) so they are more or less the same across
					% different runs of the function. This is done by keeping the mean after
					% normalization less than 0.5 (it is not perfect though).
					normalizedPos = pos - min(pos);
					normalizedPos = normalizedPos / max(normalizedPos);
					if mean(normalizedPos) > 0.5
						pos = -pos;
					end;
					
					% map the 1-D representation of projected measures into color
					hsvFromRedToBlue = hsv(64);
					hsvFromRedToBlue = hsvFromRedToBlue(1:44,:);
					
					roiColor = value2color(pos, hsvFromRedToBlue);
				end;
				
				figure;
				plot_dipplot_with_cortex;
				
				for i = 1:length(significantROI)
					pr.plot_head_surface(obj.headGrid, obj.regionOfInterest(significantROI(i)).membershipCube, 'surfaceColor', roiColor(i,:));
				end;
				
			end;
		end;
	end;
end