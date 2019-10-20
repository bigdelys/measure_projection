classdef domain
    properties %(SetAccess = 'immutable');
        headGrid
        membershipCube % boolean 3D array which isd true on grid points that belong to the domain
        exemplarLinearMeasure
        exemplarLocationId       
        dipoleAndMeasure % contain a copy of the original dipoleAndMeasure but with the most memory-consuming part (linearizedMeasure field) removed.
        scalpMapVisualizationPolarity = 1; % used primarily for making ERP projection to scalp positive.
        projectionParameter % the value which was used to create the domain                
        meanLinearizedProjectedMeasure   % weighted (by dipole denisty) mean of measure over all domain locations.
    end % properties that can only be set on startup
    
    properties
        label
        color
    end; % properties that may be changed
    
    methods (Static = true)
        function obj = loadobj(objBefore)
            % if meanLinearizedProjectedMeasure property is empty, fill it up with calculated value.
            if ~isfield(objBefore, 'meanLinearizedProjectedMeasure') || isempty(objBefore.meanLinearizedProjectedMeasure)
                if isfield(objBefore, 'linearizedProjectedMeasure')
                    
                    % make sure projectionParameter field is set: if it does not exist, use
                    % ifnromation from older class version (where this information was placed directly in the Domain class object) to create it.
                    if ~isfield(objBefore, 'projectionParameter')
                        try
                            objBefore.projectionParameter = pr.projectionParameter(objBefore.standardDeviationOfEstimatedDipoleLocation, objBefore.numberOfStandardDeviationsToTruncatedGaussaian);
                        catch
                            objBefore.projectionParameter = pr.projectionParameter;
                        end;
                    end;
                    
                    [dummy, dipoleDensity]= pr.meanProjection.getProjectionMatrix(objBefore.dipoleAndMeasure, objBefore.headGrid, objBefore.projectionParameter, objBefore.membershipCube);
                    dipoleDensity = dipoleDensity / sum(dipoleDensity);                    
                    objBefore.meanLinearizedProjectedMeasure = objBefore.linearizedProjectedMeasure * dipoleDensity';
                else
                    objBefore.meanLinearizedProjectedMeasure = objBefore.exemplarLinearMeasure;
                    fprintf('Measure Projection: Domain object was made from an older version of the class which did not \n contain meanLinearizedProjectedMeasure property and it is now filled with values from exemplarLinearMeasure.\n');
                end;
            end;
                        
            % create a new object and fill-in fields from the struct or object (in objBefore) that also exit in
            % the latest definition of the class (in pr.domain)
            obj = pr.domain;
            if isstruct(objBefore)
                objBeforeFieldNames = fieldnames(objBefore);
            elseif isobject(objBefore)
                objBeforeFieldNames = properties(objBefore);
            else
                error('Measure Projection: Loaded object is not an object nor a structure.');
            end;
            
            for i=1:length(objBeforeFieldNames)
                if isprop(obj, objBeforeFieldNames{i})
                    obj.(objBeforeFieldNames{i}) = objBefore.(objBeforeFieldNames{i});
                end;
            end;
        end
    end
    
    methods
        function obj = domain(membershipCube, headGrid, meanLinearizedProjectedMeasure, exemplarLocationId, exemplarLinearMeasure, label, dipoleAndMeasure, projectionParameter)
            % newObject = domain(membershipCube, headGrid, meanLinearizedProjectedMeasure, exemplarLocationId, exemplarLinearMeasure, label, dipoleAndMeasure, projectionParameter)
           
            if nargin>0
                obj.membershipCube = membershipCube;
                obj.headGrid = headGrid;
                obj.meanLinearizedProjectedMeasure = meanLinearizedProjectedMeasure;
                obj.exemplarLocationId = exemplarLocationId;
                obj.exemplarLinearMeasure = exemplarLinearMeasure;
                
                % empty the measure to save memory.
                dipoleAndMeasure.linearizedMeasure = [];
                obj.dipoleAndMeasure = dipoleAndMeasure;
                
                obj.projectionParameter = projectionParameter;
                if nargin > 5
                    obj.label = label;
                end;
            end;
        end;
        
        function valueOnFineGrid = plotMri(obj, mri3dplotOptions)
            % to do: add an option to color the plot by correlation ,intead of solid lines
            
            if nargin<2
                mri3dplotOptions = {'mriview' , 'top','mrislices', [-50 -30 -20 -15 -10 -5 0 5 10 15 20 25 30 40 50]};
            end;
            
            valueOnCoarseGrid = double(obj.membershipCube);
            
            valueOnCoarseGrid(valueOnCoarseGrid<0) = 0;
            
            [valueOnFineGrid mri] = convert_coarse_grid_to_mri3d(valueOnCoarseGrid, obj.headGrid.xCube, obj.headGrid.yCube, obj.headGrid.zCube);
            mri3dplot(valueOnFineGrid, mri, mri3dplotOptions{:}); % for some reason, this function hicjacks a currently open figure. even if a new figur is just created.
            title([obj.label ' membership'], 'color', [1 1 1]);
            set(gcf, 'InvertHardcopy', 'off');
        end;
        
        function plotScatter(obj)
            figure;
            
            t = double(obj.membershipCube);
            t(~obj.membershipCube) = eps;
            
            color = value2color(t(:), jet);
            
            scatter3(obj.headGrid.xCube(obj.headGrid.insideBrainCube), obj.headGrid.yCube(obj.headGrid.insideBrainCube), obj.headGrid.zCube(obj.headGrid.insideBrainCube), (t(obj.headGrid.insideBrainCube) * 40)+5, color(obj.headGrid.insideBrainCube), 'filled');
            axis equal;
            set(gcf, 'name', obj.label);
        end
        
        function plotMeasure(obj, varargin) % plots both the measure and the location
            
            % for erp (of study), use erpVisualizationPolarity so erp polarity can be inverted, just
            % for visualization.
            if strcmp(class(obj.dipoleAndMeasure), 'pr.dipoleAndMeasureOfStudyErp')
                obj.dipoleAndMeasure.plot(obj.scalpMapVisualizationPolarity * obj.meanLinearizedProjectedMeasure, varargin{:});
            else
                obj.dipoleAndMeasure.plot(obj.meanLinearizedProjectedMeasure, varargin{:});
            end;
            
            set(gcf, 'name', obj.label);
        end;
        
        function plotConditionDifference(obj, dipoleAndMeasure, varargin)
            % plotConditionDifference(obj, dipoleAndMeasure, {optional 'key', 'value' inputs})
            %
            % plot condition difference between first and second specified conditions (A-B) and
            % mask areas with non-significent differences.
            %
            % Optional 'key', 'value' inputs:
            %
            %   'significanceLevel'       - p-value number for masking condition difference. {default: 0.03}
            %   'twoConditionLabels'      - a cell containing the labels of the two labels to be
            %                               compared. By default the first two are compared.
            %   'statisticsParameter'     - a cell containing statistical parameters for comapring
            %                               two conditions. These parameters are passed to
            %                               statcond() function. See statcond(0 for more detils.
            %                               Example: {'mode', 'perm', 'naccu', 250} to perform permutation
            %                               statistics with 250 random permutations.
            %   'plottingParameter'       - a cell containing additional plotting parameters to be
            %                               pased to the plotting function appropriate for that measure, like std_plottf() for
            %                               ERSP or std_plotcurve() for ERP.
            %   'positionsForStatistics' -  a string that selects the method with which the
            %                               projected measures on domain positions are used in
            %                               statistical comparison between the conditions:
            %                               'each': uses projection from each point of the domain as a sepatrate
            %                               and equivalent measurement for that session.
            %                               'mean': calculate the mean projected measure over the
            %                               domain location.
            %                               'exemplar': only uses th projection and exemplar
            %                               location.
            %                               {default: 'each' which seems to produce best results, as
            %                               more measurements for each session are provided}
            %   'positionForMeasure'     -  position for which the projected measure difference is calculated,
            %                               masked and then plotted. Masking is always controlled by
            %                               'positionsForStatistics' parameters, but
            %                               'positionForMeasure' parameters specifies the projected measure for
            %                                which the difference between the two conditions is
            %                                plotted.
            %                                'exemplar': use projected measure at exemplar location.
            %                                'mean;: use mean projected measure over all domain members (locations).
            %
            
            if nargin < 2
                error('Please provide a variable of type dipoleAndMeasure in the first argument.');
            end;
            
            inputOptions = finputcheck(varargin, ...
                { 'significanceLevel'     'real'     []                        0.03; ...
                'twoConditionLabels'      'cell'     {}                         {};...
                'statisticsParameter'     'cell'     {}                         {};...
                'plottingParameter'       'cell'     {}                         {};...
                'positionsForStatistics'  'string' {'each' 'mean' 'exemplar'}   'mean';...
                'positionForMeasure'      'string' {'exemplar' 'mean'}          'mean';...
                });
            
            % make sure the positions for statistics and plotting are compatible. If for 'each' in
            % positionsForStatistics, both options for measure position could work.
            if ~strcmp(inputOptions.positionsForStatistics, inputOptions.positionForMeasure) && ~strcmp('positionsForStatistics', 'each')
                inputOptions.positionsForStatistics = inputOptions.positionForMeasure;
                fprintf(['Position for measure changed to ' inputOptions.positionsForStatistics ' to be compatible with position for statistics\n']);
            end;
            
            if strcmpi(inputOptions.positionsForStatistics, 'exemplar')
                regionForStatisticsCube = false(size(obj.membershipCube));
                regionForStatisticsCube(obj.exemplarLocationId) = true;
            else
                regionForStatisticsCube = obj.membershipCube;% default, provide all positions in the domain for statistics.
            end;
            
            if strcmpi(inputOptions.positionForMeasure, 'exemplar')
                % for condition comparison, it is better to compare projections to the exemplar
                % location.
                dipoleAndMeasure.plotConditionDifference(obj.exemplarLinearMeasure, obj.headGrid, regionForStatisticsCube, obj.projectionParameter, inputOptions.twoConditionLabels, inputOptions.significanceLevel, inputOptions.positionsForStatistics, inputOptions.statisticsParameter, inputOptions.plottingParameter);
            else % use average measure over the whole domain when inputOptions = 'mean'                
                dipoleAndMeasure.plotConditionDifference(obj.meanLinearizedProjectedMeasure, obj.headGrid, regionForStatisticsCube, obj.projectionParameter, inputOptions.twoConditionLabels, inputOptions.significanceLevel,inputOptions.positionsForStatistics,  inputOptions.statisticsParameter, inputOptions.plottingParameter);
            end;
            
            set(gcf, 'name', obj.label);
        end;
        
        function properties = plotConditionDifferenceGui(obj, dipoleAndMeasure, properties, varargin)
            
            if nargin < 3 || isempty(properties)
                properties = [ ...
                    
                PropertyGridField('condition1', obj.dipoleAndMeasure.conditionLabel{1}, ...
                'Type', PropertyType('char', 'row', obj.dipoleAndMeasure.conditionLabel), ...
                'DisplayName', 'First Condition', ...
                'Category', 'Main', ...
                'Description', 'The first condition to be included in the comparison (first - second). Statistics will be performed on the difference between the first and the second condition.') ...
                
                PropertyGridField('condition2', obj.dipoleAndMeasure.conditionLabel{max(1, length(obj.dipoleAndMeasure.conditionLabel))}, ...
                'Type', PropertyType('char', 'row', obj.dipoleAndMeasure.conditionLabel), ...
                'DisplayName', 'Second Condition', ...
                'Category', 'Main', ...
                'Description', 'The second condition to be included in the comparison (first - second). Statistics will be performed on the difference between the first and the second condition.') ...
                
                PropertyGridField('significance', double(0.05), ...
                'Type', PropertyType('denserealdouble', 'scalar', [0 1]), ...
                'DisplayName', 'Significance Mask', ...
                'Category', 'Main', ...
                'Description', 'Significance threshold (p value) for masking condition differences.') ...
                
                PropertyGridField('positionsForStatistics', 'mean', ...
                'Type', PropertyType('char', 'row', {'each' 'mean' 'exemplar'}), ...
                'Category', 'Statistics Method', ...
                'DisplayName', 'Position for Statistics', ...
                'Description', ['selects the method with which the projected measures on domain positions are used in statistical comparison between the conditions: ' sprintf('\n') '''each'': uses projection from each point of the domain as a sepatrate and equivalent measurement for that session. ' sprintf('\n') '''mean'': calculate the mean projected measure over the domain location.' sprintf('\n') ' ''exemplar'': only uses th projection and exemplar location.']) ...
                
                
                PropertyGridField('significanceCalculationMethod', 'param', ...
                'Type', PropertyType('char', 'row', {'perm','bootstrap','param'}), ...
                'Category', 'Statistics Method', ...
                'DisplayName', 'Significance Calculation Method', ...
                'Description', ['Method for computing the p-values:' sprintf('\n') '''param'' = parametric testing (standard ANOVA or t-test).' sprintf('\n') '''perm'' = non-parametric testing using surrogate data.' sprintf('\n') '''bootstrap'' = non-parametric bootstrap made by permuting the input data.'])
                
                PropertyGridField('numberOfSurrogateCopies', uint16(200), ...
                'Type', PropertyType('uint16', 'scalar', [100 Inf]), ...
                'DisplayName', 'Number of Surrogate Copies', ...
                'Category', 'Statistics Method', ...
                'Description', 'Number of surrogate data copies to use in ''perm'' or ''bootstrap'' method for significance calculation.') ...
                ];
            end;
            
            figureHandle = figure( ...
                'MenuBar', 'none', ...
                'Name', [obj.label ' Condition Difference'], ...
                'NumberTitle', 'off', ...
                'Toolbar', 'none', 'visible', 'on');
            
            % set figure size to be more appropriate.
            positionArray = get(figureHandle, 'position');
            positionArray(3:4) = [375 420];
            set(figureHandle, 'position', positionArray);
            
            % add property pane to figure
            optionsPropertyGrid = PropertyGrid(figureHandle, 'Properties', properties);
            
            % wait for figure to close
            uiwait(figureHandle);
            
            guiPropertyValue = optionsPropertyGrid.GetPropertyValues();
            properties = optionsPropertyGrid.Properties;

            % use input options to launch plotConditionDifference
            plotConditionDifference(obj, dipoleAndMeasure, 'significanceLevel' , guiPropertyValue.significance, 'twoConditionLabels', {guiPropertyValue.condition1 guiPropertyValue.condition2}, ...
                'positionsForStatistics', guiPropertyValue.positionsForStatistics, 'statisticsParameter', {'mode', guiPropertyValue.significanceCalculationMethod, 'naccu', guiPropertyValue.numberOfSurrogateCopies});            
        end;
        
        function plotGroupDifference(obj, dipoleAndMeasure, varargin)
            % plotGroupDifference(obj, dipoleAndMeasure, significanceLevelForConditionDifference, twoGroupLabelsForComparison, conditionLabelsForComparison, statisticsParameter, plottingParametervarargin)
            %
            % plot group difference between first and second specified group (A-B) for a condition and
            % mask areas with non-significent differences.
            
            inputOptions = finputcheck(varargin, ...
                { 'significanceLevel'     'real'     []                        0.05; ...
                'twoGroupLabelsForComparison'      'cell'     {}                         {};...
                'conditionLabel'         'string'    {}                         {};...
                'statisticsParameter'     'cell'     {}                         {};...
                'plottingParameter'       'cell'     {}                         {};...
                'positionsForStatistics'  'string' {'each' 'mean' 'exemplar'}   'mean';...
                'positionForMeasure'      'string' {'exemplar' 'mean'}          'mean';...
                });
            
            if nargin < 2
                error('Please provide a variable of type dipoleAndMeasure in the first argument.');
            end;
            
            if nargin < 3
                significanceLevelForConditionDifference = 0.05;
            end;
            
            % if no group label is provided, use the default which is the first two groups.
            
            
            % for group comparison, we compare average projection to all domain locations.
            dipoleAndMeasure.plotGroupDifference(obj.meanLinearizedProjectedMeasure, obj.headGrid, obj.membershipCube, obj.projectionParameter, inputOptions.twoGroupLabelsForComparison, inputOptions.conditionLabel, inputOptions.significanceLevel, inputOptions.positionsForStatistics, inputOptions.statisticsParameter, inputOptions.plottingParameter);
            set(gcf, 'name', obj.label);
        end;
        
        
        function properties = plotGroupDifferenceGui(obj, dipoleAndMeasure, properties, varargin)
            
            if nargin < 3 || isempty(properties)
                properties = [ ...
                    
                PropertyGridField('condition', obj.dipoleAndMeasure.conditionLabel{1}, ...
                'Type', PropertyType('char', 'row', obj.dipoleAndMeasure.conditionLabel), ...
                'DisplayName', 'Condition', ...
                'Category', 'Main', ...
                'Description', 'The condition to compared across two groups.') ...
                
                PropertyGridField('group1', obj.dipoleAndMeasure.uniqueGroupName{1}, ...
                'Type', PropertyType('char', 'row', obj.dipoleAndMeasure.uniqueGroupName), ...
                'DisplayName', 'First Group', ...
                'Category', 'Main', ...
                'Description', 'The first group to be included in the comparison (first - second). Statistics will be performed on the difference between the first and the second group.') ...
                
                PropertyGridField('group2', obj.dipoleAndMeasure.uniqueGroupName{max(1, length(obj.dipoleAndMeasure.uniqueGroupName))}, ...
                'Type', PropertyType('char', 'row', obj.dipoleAndMeasure.uniqueGroupName), ...
                'DisplayName', 'Second Group', ...
                'Category', 'Main', ...
                'Description', 'The second group to be included in the comparison (first - second). Statistics will be performed on the difference between the first and the second group.') ...
                
                PropertyGridField('significance', double(0.05), ...
                'Type', PropertyType('denserealdouble', 'scalar', [0 1]), ...
                'DisplayName', 'Significance Mask', ...
                'Category', 'Main', ...
                'Description', 'Significance threshold (p value) for masking group differences.') ...
                
                PropertyGridField('positionsForStatistics', 'mean', ...
                'Type', PropertyType('char', 'row', {'each' 'mean' 'exemplar'}), ...
                'Category', 'Statistics Method', ...
                'DisplayName', 'Position for Statistics', ...
                'Description', ['selects the method with which the projected measures on domain positions are used in statistical comparison between the groups: ' sprintf('\n') '''each'': uses projection from each point of the domain as a sepatrate and equivalent measurement for that session. ' sprintf('\n') '''mean'': calculate the mean projected measure over the domain location.' sprintf('\n') ' ''exemplar'': only uses th projection and exemplar location.']) ...
                
                
                PropertyGridField('significanceCalculationMethod', 'param', ...
                'Type', PropertyType('char', 'row', {'perm','bootstrap','param'}), ...
                'Category', 'Statistics Method', ...
                'DisplayName', 'Significance Calculation Method', ...
                'Description', ['Method for computing the p-values:' sprintf('\n') '''param'' = parametric testing (standard ANOVA or t-test).' sprintf('\n') '''perm'' = non-parametric testing using surrogate data.' sprintf('\n') '''bootstrap'' = non-parametric bootstrap made by permuting the input data.'])
                
                PropertyGridField('numberOfSurrogateCopies', uint16(200), ...
                'Type', PropertyType('uint16', 'scalar', [100 Inf]), ...
                'DisplayName', 'Number of Surrogate Copies', ...
                'Category', 'Statistics Method', ...
                'Description', 'Number of surrogate data copies to use in ''perm'' or ''bootstrap'' method for significance calculation.') ...
                ];
            end;
            
            figureHandle = figure( ...
                'MenuBar', 'none', ...
                'Name', [obj.label ' Group Difference'], ...
                'NumberTitle', 'off', ...
                'Toolbar', 'none', 'visible', 'on');
            
            % set figure size to be more appropriate.
            positionArray = get(figureHandle, 'position');
            positionArray(3:4) = [375 420];
            set(figureHandle, 'position', positionArray);
            
            % add property pane to figure
            optionsPropertyGrid = PropertyGrid(figureHandle, 'Properties', properties);
            
            % wait for figure to close
            uiwait(figureHandle);
            
            guiPropertyValue = optionsPropertyGrid.GetPropertyValues();
            properties = optionsPropertyGrid.Properties;

            % use input options to launch plotConditionDifference
            plotGroupDifference(obj, dipoleAndMeasure, 'significanceLevel' , guiPropertyValue.significance, 'twoGroupLabelsForComparison', {guiPropertyValue.group1 guiPropertyValue.group2}, ...
                'positionsForStatistics', guiPropertyValue.positionsForStatistics, 'statisticsParameter', {'mode', guiPropertyValue.significanceCalculationMethod, 'naccu',...
                guiPropertyValue.numberOfSurrogateCopies}, 'conditionLabel', guiPropertyValue.condition);            
        end;
        
        function plotVoxel(obj, regionColor, regionOptions, createNewFigure)
            
            if nargin<2
                if isempty(obj.color)
                    regionColor = 'g';
                else
                    regionColor = obj.color;
                end;
            end;
            
            if nargin<3
                regionOptions = {};
            end;
            
            if nargin<4
                createNewFigure = true;
            end;
            
            if createNewFigure
                figure;
            end;
            
            plot_dipplot_with_cortex;
            pr.plot_head_region(obj.headGrid, obj.membershipCube, 'regionColor' , regionColor, 'regionOptions', regionOptions);
            set(gcf, 'name', obj.label);
        end; 
        
        function plotVolume(obj, surfaceColor, plotOptions, surfaceOptions, createNewFigure)
            % plotVolume(obj, surfaceColor, plotOptions, surfaceOptions, createNewFigure)
            % plotOptions are options that will be passed to plot_head_surface();
            
            if nargin<2
                if isempty(obj.color)
                    surfaceColor = [0.15 0.8 0.15];
                else
                    surfaceColor = obj.color;
                end;
            end;
            
            if nargin<3
                plotOptions = {};
            end;
            
            
            if nargin<4
                surfaceOptions = {};
            end;
            
            if nargin<5
                createNewFigure = true;
            end;
            
            if createNewFigure
                figure;
            end;
            
            plot_dipplot_with_cortex;
            pr.plot_head_surface(obj.headGrid, obj.membershipCube, 'surfaceColor' , surfaceColor, 'surfaceOptions', surfaceOptions, plotOptions{:});
            set(gcf, 'name', obj.label);
        end;
        
        function plotCortex(obj, domainColor, plotOptions, createNewFigure, varargin)
            if nargin<2
                if isempty(obj.color)
                    domainColor = [0.15 0.8 0.15];
                else
                    domainColor = obj.color;
                end;
            end;
            
            if nargin<3
                plotOptions = {};
            end;
                                    
            if nargin<5
                createNewFigure = true;
            end;
            
            fsf = load('MNImesh_dipfit.mat');
            cortexVertices = fsf.vertices;
            
            [dummy, dipoleDensity]= pr.meanProjection.getProjectionMatrix(obj.dipoleAndMeasure, obj.headGrid, obj.projectionParameter, obj.membershipCube);
            dipoleDensity = dipoleDensity / sum(dipoleDensity);
            
            domainLocation = obj.headGrid.getPosition(obj.membershipCube);
            headGridSpacing =  obj.headGrid.spacing;
            
            cortexPointDomainDenisty = pr.project_domain_to_cortex(domainLocation, cortexVertices, headGridSpacing, dipoleDensity);
            pr.plot_cortex(cortexPointDomainDenisty, domainColor, 'newFigure', createNewFigure);

            set(gcf, 'name', obj.label);
        end;
        
        function [brodmannAreaNumber brodmannAreaDipoleDensityRatio additionalDescriptionForBrodmannArea] = getBrodmannArea(obj, cutoffDensity, varargin)
            % [brodmannAreaNumber brodmannAreaDipoleDensityRatio additionalDescriptionForBrodmannArea] = getBrodmannArea(cutoffDensity, {optional arguments})
            %
            % brodmannAreaNumber 1 x N vector containing Brodmann areas numbers, sorted by the amount of dipole mass associated with each.
            %
            % brodmannAreaDipoleDensityRatio 1 X N vector containing the ratio of dipole mass
            % associated with each of the areas returned in brodmannAreaNumber.
            %
            % additionalDescriptionForBrodmannArea 1 X N cell array containing some additional
            % information (e.g. 'Primary visual') associated with each of the domain returned in
            % brodmannAreaNumber.
            
            if nargin < 2
                cutoffDensity = 0.05; % Brodmann areas with less than this dipole denisty ratio will not be reported.
            end;
            
            inputOptions = finputcheck(varargin, ...
                {'printDomainLabel'        'boolean'  []   true;...
                });
            
            % find dipole mass at each domain location
            [projectionMatrix dipoleDensityFromTheDataset]= pr.meanProjection.getProjectionMatrix(obj.dipoleAndMeasure, obj.headGrid, obj.projectionParameter, obj.membershipCube);
            
            % normalize dipole mass
            dipoleDensityFromTheDataset = dipoleDensityFromTheDataset / sum(dipoleDensityFromTheDataset);
            
            insideBrainIndexCube = zeros(obj.headGrid.cubeSize);
            insideBrainIndexCube(obj.headGrid.insideBrainCube(:)) = 1:sum(obj.headGrid.insideBrainCube(:));
            
            domainDipoleDenistyWithInsideBrainIndex = insideBrainIndexCube(obj.membershipCube);
            
            nonZeroIndices = domainDipoleDenistyWithInsideBrainIndex > 0;
            
            insideBrainGridLocationBrodmannAreaCount = obj.headGrid.getBrodmannData;
            
            totalDipoleDensityInBrodmannArea = dipoleDensityFromTheDataset(nonZeroIndices) * insideBrainGridLocationBrodmannAreaCount(domainDipoleDenistyWithInsideBrainIndex(nonZeroIndices),:);
            
            %totalDipoleDensityInBrodmannArea =
            totalDipoleDensityInBrodmannArea = totalDipoleDensityInBrodmannArea / sum(totalDipoleDensityInBrodmannArea);
            
            [sortedTotalDipoleDensityInBrodmannArea sortedBrodmannAreaNumber]= sort(totalDipoleDensityInBrodmannArea, 'descend');
            
            additionalLabelForBrodmannArea = cell(52,1);
            additionalLabelForBrodmannArea(1:3) = {'Primary Somatosensory'};
            
            additionalLabelForBrodmannArea(4) = {'Primary Motor'};
            
            additionalLabelForBrodmannArea(5) = {'Somatosensory Association'};
            additionalLabelForBrodmannArea(6) = {'Premotor and Supplementary Motor'};
            additionalLabelForBrodmannArea(7) = {'Somatosensory Association'};
            additionalLabelForBrodmannArea(8) = {'Includes Frontal eye fields and Lateral and medial supplementary motor area (SMA)'};
            additionalLabelForBrodmannArea(13) = {'Inferior Insula'};            
            additionalLabelForBrodmannArea(17) = {'Primary visual (V1)'};
            additionalLabelForBrodmannArea(18) = {'Secondary visual (V2)'};
            additionalLabelForBrodmannArea(19) = {'Associative visual (V3)'};
            additionalLabelForBrodmannArea(22) = {'Auditory processing'};
            additionalLabelForBrodmannArea(40) = {'Spatial and Semantic Processing'};
            additionalLabelForBrodmannArea(41:42) = {'Primary and Association Auditory '};
            additionalLabelForBrodmannArea(43) = {'Subcentralis'}; 
            %functional rules, so better to not list 'taste' area.
            additionalLabelForBrodmannArea(44) = {'part of Broca''s area'};
            additionalLabelForBrodmannArea(45) = {'pars triangularis Broca''s area'};
            
            if nargout > 0
                reportedAreaId = sortedTotalDipoleDensityInBrodmannArea > cutoffDensity;
                brodmannAreaNumber = sortedBrodmannAreaNumber(reportedAreaId);
                brodmannAreaDipoleDensityRatio = sortedTotalDipoleDensityInBrodmannArea(reportedAreaId);
                additionalDescriptionForBrodmannArea = additionalLabelForBrodmannArea(sortedBrodmannAreaNumber(reportedAreaId));
            end;
            
            % display information as text if no output variable us requested.
            if nargout == 0
                fprintf('\n');
                
                if inputOptions.printDomainLabel
                    fprintf(obj.label);
                    fprintf('\n');
                end;
                
                for i=1:length(sortedTotalDipoleDensityInBrodmannArea)
                    if sortedTotalDipoleDensityInBrodmannArea(i) > cutoffDensity
                        fprintf('BA %d (%3.2f)', sortedBrodmannAreaNumber(i), sortedTotalDipoleDensityInBrodmannArea(i));
                        
                        if ~isempty(additionalLabelForBrodmannArea{sortedBrodmannAreaNumber(i)})
                            fprintf(', %s', additionalLabelForBrodmannArea{sortedBrodmannAreaNumber(i)});
                        end;
                        
                        fprintf('\n');
                    end;
                end;
            end;
        end;
        
        function [regionLabelOutput domainDipoleMassInAnatomicalRegionOutput] = getAnatomicalInformation(obj, cutoffDensity, varargin)
            % [domainDipoleMassInAnatomicalRegion regionLabel] = getAnatomicalInformation(obj, cutoffDensity, varargin)
            %
            % regionLabel 1 x N vector containing anatomical areas numbers, sorted by the amount of dipole mass associated with each.
            %
            % domainDipoleMassInAnatomicalRegion 1 X N vector containing the ratio of dipole mass
            % associated with each of the areas returned in regionLabel.

            inputOptions = finputcheck(varargin, ...
                {'printDomainLabel'        'boolean'  []   true;...
                });
            
            if nargin < 2
                cutoffDensity = 0.05; % Anatomical areas with less than this dipole denisty ratio will not be reported.
            end;
        
            % find dipole mass at each domain location
            [projectionMatrix dipoleDensityFromTheDataset]= pr.meanProjection.getProjectionMatrix(obj.dipoleAndMeasure, obj.headGrid, obj.projectionParameter, obj.membershipCube);
            
            % get anatomical data from headGrid
            anatomicalInformation =  obj.headGrid.getAnatomicalData;
            
            insideBrainIndexCube = zeros(obj.headGrid.cubeSize);
            insideBrainIndexCube(obj.headGrid.insideBrainCube(:)) = 1:sum(obj.headGrid.insideBrainCube(:));
            
            domainDipoleDenistyWithInsideBrainIndex = insideBrainIndexCube(obj.membershipCube);
            
            nonZeroIndices = domainDipoleDenistyWithInsideBrainIndex > 0;
            
            domainDipoleMassInAnatomicalRegion = dipoleDensityFromTheDataset(nonZeroIndices) * anatomicalInformation.probabilityOfEachLocationAndBrainArea(domainDipoleDenistyWithInsideBrainIndex(nonZeroIndices),:);
            domainDipoleMassInAnatomicalRegion = domainDipoleMassInAnatomicalRegion / sum(domainDipoleMassInAnatomicalRegion);
            
            [domainDipoleMassInAnatomicalRegion dipoleMassOrder] = sort(domainDipoleMassInAnatomicalRegion, 'descend');
            regionLabel = anatomicalInformation.brainArealabel(dipoleMassOrder);
            
            regionLabel(domainDipoleMassInAnatomicalRegion < cutoffDensity) = [];
            domainDipoleMassInAnatomicalRegion(domainDipoleMassInAnatomicalRegion < cutoffDensity) = [];
            
            % display information as text if no output variable us requested.
            if nargout == 0
                fprintf('\n');
                
                if inputOptions.printDomainLabel
                    fprintf(obj.label);
                    fprintf('\n');
                end;
                
                for i=1:length(regionLabel)
                        fprintf([regionLabel{i} ' (%3.2f)'], domainDipoleMassInAnatomicalRegion(i));                                                
                        fprintf('\n');
                end;
            else % only if output arguments are requested assign them.
                regionLabelOutput = regionLabel;
                domainDipoleMassInAnatomicalRegionOutput = domainDipoleMassInAnatomicalRegion;
            end;
        end;
        
        function describe(obj, cutoffDensity)
            
            if nargin < 2
                cutoffDensity = 0.05; % Anatomical areas with less than this dipole denisty ratio will not be reported.
            end;
            
            obj.getBrodmannArea(cutoffDensity, 'printDomainLabel', true);
            fprintf('------------------------------------------------');
            obj.getAnatomicalInformation(cutoffDensity, 'printDomainLabel', false);
            fprintf('\n(values in parenthesis indicate dipole mass associated with each anatomical region)\n');
        end;
        
        function [handleArray html] = describeInPopup(obj, cutoffDensity, varargin)
            % describeInPopup(obj, cutoffDensity)
            
            if nargin < 2
                cutoffDensity = 0.05; % Anatomical areas with less than this dipole denisty ratio will not be reported.
            end;
            
            [brodmannAreaNumber brodmannAreaDipoleDensityRatio additionalDescriptionForBrodmannArea] = getBrodmannArea(obj, cutoffDensity,  'printDomainLabel', false);
            [regionLabelOutput domainDipoleMassInAnatomicalRegionOutput] = getAnatomicalInformation(obj, cutoffDensity,  'printDomainLabel', false);
            
            
            %%
            html = 'text://<html>';
            html = [html '<title>' obj.label '</title>'];
            html = [html '<h3>' '<a target="_blank" href = "http://www.talairach.org/daemon.html">Brodmann Areas</a></h3></h3>'];
            
            % add table  of brodmann areas
            html = [html '<table border="1"  style="width: 77%;" cellpadding="3" cellspacing="0" align = "center">  <tbody>'];
            html = [html '<tr> <th style="" align="center">Area</th> <th style="" align="center">Probability</th> <th style="" align="center">Description</th></tr>'];
            
            for i = 1:length(brodmannAreaNumber)
                html = [html '<tr>'];
                
                html = [html '  <td style="" align="center">'];
                html = [html  '<a target="_blank" href=  "http://en.wikipedia.org/wiki/Brodmann_area_' num2str(brodmannAreaNumber(i)) '">BA ' num2str(brodmannAreaNumber(i)) '</a>'];
                html = [html '  </td>'];
                
                % dipole density
                html = [html '  <td style="" align="center">'];
                html = [html sprintf('%3.2f', brodmannAreaDipoleDensityRatio(i))];
                html = [html '  </td>'];
                
                % additional info
                html = [html '  <td style="" align="center">'];
                html = [html additionalDescriptionForBrodmannArea{i}];
                html = [html '  </td>'];
                
                html = [html '</tr>'];
            end;
            
            html = [html '</tbody></table>'];
            
            % Anatomical areas
            html = [html '<h3>' '<a target="_blank" href = "http://www.loni.ucla.edu/Atlases/Atlas_Detail.jsp?atlas_id=12">Anatomical Areas</a></h3>'];
            
            % add table  of brodmann areas
            html = [html '<table border="1"  style="width: 77%;" cellpadding="3" cellspacing="0" align = "center">  <tbody>'];
            html = [html '<tr> <th style="" align="center">Area</th> <th style="" align="center">Probability</th>'];
            
            for i = 1:length(domainDipoleMassInAnatomicalRegionOutput)
                html = [html '<tr>'];
                
                html = [html '  <td style="" align="center">'];
                html = [html regionLabelOutput{i}];
                html = [html '  </td>'];
                
                % dipole density
                html = [html '  <td style="" align="center">'];
                html = [html sprintf('%3.2f', domainDipoleMassInAnatomicalRegionOutput(i))];
                html = [html '  </td>'];
                
                html = [html '</tr>'];
            end;
            
            html = [html '</tbody></table>'];
            html = [html '</html>'];
            
            % place the popup in the center of the main montior monitor #1)
            width = 450;
            height = 550;
            monitorPosition = get(0, 'monitorPositions');
            screenSize = monitorPosition(1,3:4);
            
            left = round(screenSize(1)/2 - width / 2);
            top = round(screenSize(2)/2 - height / 2);
            
            handleArray = sweb(html,{'-new','-notoolbar'},[left, top,width, height]);
        end;
        
        function plotVolumeColoredByAnatomy(obj, anatomicalRegionMassCutoffThreshold, createNewFigure)
            
            if nargin < 2
                anatomicalRegionMassCutoffThreshold = 0.05; % anatomical regions with less than this much relative mass are not displayed.
            end;
            
            if nargin < 3
                createNewFigure = true;
            end;
            
            anatomicalInformation =  obj.headGrid.getAnatomicalData;
            [tmp mostLikelyAnatomicalRegion] = max(anatomicalInformation.probabilityOfEachLocationAndBrainArea,[], 2);
            fullAnatomicalCube  = zeros(obj.headGrid.cubeSize);
            fullAnatomicalCube(obj.headGrid.insideBrainCube(:)) = mostLikelyAnatomicalRegion;
            
            fullAnatomicalCube(~obj.membershipCube) = -1;
            uniqeAnatomicalRegion = unique(fullAnatomicalCube(obj.membershipCube));
            
            % find dipole mass at each domain location
            [projectionMatrix dipoleDensityFromTheDataset]= pr.meanProjection.getProjectionMatrix(obj.dipoleAndMeasure, obj.headGrid, obj.projectionParameter, obj.membershipCube);
            
            % normalize dipole mass
            dipoleDensityFromTheDataset = dipoleDensityFromTheDataset / sum(dipoleDensityFromTheDataset);
            
            % find how much of dipole mass lies inside each anatomical region
            domainDipoleMassInAnatomicalRegion = 0;
            for i=1:length(uniqeAnatomicalRegion)
                domainRegionNumers = fullAnatomicalCube(obj.membershipCube);
                regionMemberId = domainRegionNumers == uniqeAnatomicalRegion(i);
                domainDipoleMassInAnatomicalRegion(i) = sum(dipoleDensityFromTheDataset(regionMemberId));
            end;
            
            [domainDipoleMassInAnatomicalRegion dipoleMassOrder] = sort(domainDipoleMassInAnatomicalRegion, 'descend');
            uniqeAnatomicalRegion = uniqeAnatomicalRegion(dipoleMassOrder);
            
            anatomicalRegionssWithLowDipoleMass = domainDipoleMassInAnatomicalRegion < anatomicalRegionMassCutoffThreshold;
            uniqeAnatomicalRegionWithLowDipoleMass = uniqeAnatomicalRegion(anatomicalRegionssWithLowDipoleMass);
            uniqeAnatomicalRegion(anatomicalRegionssWithLowDipoleMass) = [];
            domainDipoleMassInAnatomicalRegion(anatomicalRegionssWithLowDipoleMass) = [];
            
            % plot domain locations colored by anatomical region colors.
            if createNewFigure
                figure;
            end;
            plot_dipplot_with_cortex;
            pr.remove_all_legends_from_figure;
            
            hsvFromRedToBlue = hsv;
            hsvFromRedToBlue = hsvFromRedToBlue(1:44,:);
            voxelColor = value2color(1:length(uniqeAnatomicalRegion),hsvFromRedToBlue);
            
            domainHgGroup = [];
            for i=1:length(uniqeAnatomicalRegion)
                membershipCube = fullAnatomicalCube == uniqeAnatomicalRegion(i);
                legendLabelAsCell = anatomicalInformation.brainArealabel(uniqeAnatomicalRegion(i));
                domainHgGroup(i) = hggroup('DisplayName', [legendLabelAsCell{1} ' (%' num2str(round(domainDipoleMassInAnatomicalRegion(i) * 100)) ')']);
                set(get(get(domainHgGroup(i), 'annotation'), 'LegendInformation'),'IconDisplayStyle', 'on');
                
                pr.plot_head_region(obj.headGrid, membershipCube, 'regionColor', voxelColor(i,:), 'regionOptions', {'parent', domainHgGroup(i)});
            end;
            
            
            % plot the rest (all anatomical regions with low dipole dennisty)
            
            membershipCube = ismember(fullAnatomicalCube, uniqeAnatomicalRegionWithLowDipoleMass);
            domainHgGroup(end+1) = hggroup('DisplayName', ['Other (%' num2str(round((1 - sum(domainDipoleMassInAnatomicalRegion)) * 100)) ')']);
            set(get(get(domainHgGroup(end), 'annotation'), 'LegendInformation'),'IconDisplayStyle', 'on');
            
            pr.plot_head_region(obj.headGrid, membershipCube, 'regionColor', [0.5 0.5 0.5], 'regionOptions', {'parent', domainHgGroup(end)});
            
            legendHandle = legend('show');
            set(legendHandle,  'textcolor', [1 1 1]);
        end;
        
        function plotDipole(obj, dipoleAndMeasure, cutoffRatio, regionAlpha, regionColor, createNewFigure, varargin)
            % plotDipole(obj, cutoffRatio, regionAlpha, regionColor, createNewFigure)
            
              inputOptions = finputcheck(varargin, ...
                {'cutoffRatio'     'real'     []   [1 0.05]; ...
                'surfaceAlpha'     'real'     []   0.4;...
                'surfaceColor'     'real'     []   [0.15 0.8 0.15];...
                'newFigure'        'boolean'  []   true;...
                'domainPlot'       'string'   {'voxel', 'volume'}     'volume';...
                });
            

            if inputOptions.newFigure
                figure;
            end;           
            
            [dipoleId sortedDipoleDensity orderOfDipoles dipoleDenisty dipoleDenistyInRegion] = dipoleAndMeasure.getDipoleDensityContributionToRegionOfInterest(obj.membershipCube, obj, inputOptions.cutoffRatio);
            
            % calculate correlations with exemplar and peoduce colors accordingly
            correlationWithExcemplar = zeros(length(dipoleId), 1);
            for i=1:length(dipoleId)
                t = corrcoef(obj.exemplarLinearMeasure, dipoleAndMeasure.linearizedMeasure(:, dipoleId(i)));
                correlationWithExcemplar(i) = t(1,2);
            end;
            
            % -1 and 1 anre references for correlation
            correlationWithExcemplar = [correlationWithExcemplar; 1 ;-1];
            colors = value2color(correlationWithExcemplar, jet);
            
            colorAsCell = {};
            for i=1:size(colors, 1)-2
                colorAsCell{i} = colors(i,:);
            end;
                                    
            % to do: show projection on MRI sides (cannot be done currently in dipplot since
            % 'projimg' option does not work with 'spheres' set to 'on')
            plot_dipplot_with_cortex(dipoleAndMeasure.location(dipoleId,:), true, 'coordformat', 'MNI', 'gui', 'off', 'spheres', 'on', 'color', colorAsCell);
            
            switch inputOptions.domainPlot
                case 'voxel' 
                    pr.plot_head_region(obj.headGrid, obj.membershipCube, 'regionColor', inputOptions.surfaceColor, 'regionOptions', {'facealpha', inputOptions.surfaceAlpha, 'edgealpha', 0.9});
                case 'volume' 
                    pr.plot_head_surface( obj.headGrid, obj.membershipCube, 'surfaceColor', inputOptions.surfaceColor, 'surfaceOptions', {'facealpha', inputOptions.surfaceAlpha});
            end;            
            
            set(gcf, 'name', obj.label);
            
            % modify transparency accoring to the dipole mass of rach dipole placed in the domain
            for dipoleIdNumber = 1:length(dipoleId)
                set(findobj(gcf, 'tag', ['dipole' num2str(dipoleIdNumber)]), 'facealpha', max(0.05, sqrt(dipoleDenistyInRegion(dipoleId(dipoleIdNumber)) / max(dipoleDenistyInRegion))));
            end;
            
            % add a colorbar
            colormap(jet);
            handle = cbar('vert', [1:64], [-1 1], 3);
            set(handle, 'ycolor', 0.7*[1 1 1]);
            set(handle, 'xcolor', 0.7*[1 1 1]);
            set(handle, 'xtick', []);
            set(handle, 'position', [ 0.9250    0.1100    0.0310    0.4]);
        end;
        
        function varargout = plotScalpMap(obj, varargin)
            % [numberOfContributingIcs maxNumberOfScalpmapsToShow] = obj.plotScalpMap({optional key, values})
            % optional key, value   pairs
            % createNewFigure   boolean value (true or false) that controls if a new figure show be created or just the current
            % axis/figure to be used.
            %
            % weighting    string value that can be any of {'none' 'mass' 'massAndProduct'
            %               'product'}. 'mass' means that each scalpmap is weighted by the ratio of IC dipole mass that 
            %                is indide the domain, 'product means that the weghting is based on the
            %                inner product of dipole measure by domain exemplar, and
            %                'massAndProduct' means tha the weighting is based on multipication of 
            %                 both last two values.
            %
            % cutoffRatio  is a 2-vector. The first number contains the percent of
            %              region (domain) dipole mass explained by selected dipoles after which there will be a no
            %              other dipole selected. The second is the miminum dipole mass ratio contribution to the
            %              region (dipoles with a  contribution less than this value will not be selected).
            %              For example cutoffRatio = 0.98 requires selected dipoles to at least explain 98% of
            %              dipoles mass in the region.
            %              cutoffRatio = [1 0.05] means that all dipoles that at least contribute %5 of their
            %              mass to the region will be selected. Default cutoffRatio is [1 0.05].
            %
            % dipoleAndMeasure  a 'dipoleAndMeasure' class object is needed when any of
            % 'massAndProduct' 'product' weighting options are activated.
            
            % check if an input key, value (like 'newFigure', false) is provided. If so it processes
            % it and remove it from the argument list.
            
            
            inputOptions = finputcheck(varargin, ...
                { ...
                'createNewFigure'     'boolean'  [true false]  true; ...
                'weighting'           'string'     {'none' 'mass' 'massAndProduct' 'product'}   'none'; ...
                'cutoffRatio'         'real'   [] [1 0.05];...
                'dipoleAndMeasure'    'object' [] [];...
                });
            
            
            if ischar(inputOptions)
                error(inputOptions);
            end
            
            if ismember(inputOptions.weighting, {'massAndProduct' 'product'}) && isempty(inputOptions.dipoleAndMeasure)
                error('Measure Projection: a ''dipoleAndMeasure'' class object is needed when any of ''massAndProduct''  or ''product'' weighting options are activated.');
            end;
            
            %  [dipoleId sortedDipoleDensity]= obj.dipoleAndMeasure.getDipoleDensityContributionToRegionOfInterest(obj.membershipCube, obj, varargin{:});
            % only for test, the above one is the actual one to be used.
            [dipoleId sortedDipoleDensity]= obj.dipoleAndMeasure.getDipoleDensityContributionToRegionOfInterest(obj.membershipCube, obj);
            
            maxNumberOfScalpmapsToShow = 100;
            numberOfContributingIcs = length(dipoleId);
            if numberOfContributingIcs > maxNumberOfScalpmapsToShow
                fprintf('There are %d ICs that significantly contribute to this domain. \nOnly scalpmaps from the %d highest contributing ICs are displayed.\n', numberOfContributingIcs, maxNumberOfScalpmapsToShow);
                dipoleId = dipoleId(1:maxNumberOfScalpmapsToShow);
            end;
            
            switch lower(inputOptions.weighting)
                case 'none'
                    % color each scalpmap independently (not weighted)
                    obj.dipoleAndMeasure.scalpmap.plot(dipoleId, obj.scalpMapVisualizationPolarity, inputOptions.createNewFigure);
                case {'mass'  'massandproduct' 'product'}
                    % weight scalpmaps for dipole mass contribution to Domain.
                    tempScalpmap = obj.dipoleAndMeasure.scalpmap;
                    tempScalpmap.normalizedChannelWeight = tempScalpmap.normalizedChannelWeight(dipoleId,:,:);
                    
                    % scale each scalpmap by its dipole mass contribution to the Domain.
                    for i=1:length(dipoleId)
                        %
                        
                        % only for test, the above one is the actual one to be used.
                        % weight also by inner product of measure to domain exemplar
                        switch lower(inputOptions.weighting)
                            case 'mass'
                                tempScalpmap.normalizedChannelWeight(i,:,:) = sortedDipoleDensity(i) * tempScalpmap.normalizedChannelWeight(i,:,:);
                            case 'massandproduct'
                                tempScalpmap.normalizedChannelWeight(i,:,:) = (inputOptions.dipoleAndMeasure.linearizedMeasure(:,dipoleId(i))' * obj.exemplarLinearMeasure) * sortedDipoleDensity(i) * tempScalpmap.normalizedChannelWeight(i,:,:);
                            case 'product'
                                tempScalpmap.normalizedChannelWeight(i,:,:) = (inputOptions.dipoleAndMeasure.linearizedMeasure(:,dipoleId(i))' * obj.exemplarLinearMeasure) * tempScalpmap.normalizedChannelWeight(i,:,:);
                        end;
                        
                        
                    end;
                    tempScalpmap.plot(1:length(dipoleId), obj.scalpMapVisualizationPolarity, inputOptions.createNewFigure);
                    
                    % set all color scales the same
                    axisHandle = findobj(gcf, 'type', 'axes');
                    
                    maxAbs = quantile(abs(tempScalpmap.normalizedChannelWeight(~isnan(tempScalpmap.normalizedChannelWeight(:)))), 0.999); % leave 0.5% saturation for outliers
                    set(axisHandle, 'clim', [-maxAbs maxAbs]);
            end;
            
            set(gcf, 'name', [obj.label ' (subject/ic)']);
            
            if nargout > 0
                varargout{1} = numberOfContributingIcs;
            end;
            
            if nargout > 1
                varargout{2} = maxNumberOfScalpmapsToShow;
            end;
        end;
        
        function plotMeanScalpMap(obj, varargin)
            
            % check if an input key, value (like 'newFigure', false) is provided. If so it processes
            % it and remove it from the argument list.
            creareNewFigure = true;
            for i=1:length(varargin)
                if ischar(varargin{i}) && strcmpi(varargin{i}, 'newFigure')
                    creareNewFigure = varargin{i+1};
                    
                    % remove the argument before passing it to
                    % getDipoleDensityContributionToRegionOfInterest()
                    varargin(i) = [];
                    varargin(i) = [];
                    
                    break;
                end;
            end;
            
            [dipoleId sortedDipoleDensity orderOfDipoles dipoleDenisty dipoleDenistyInRegion] = obj.dipoleAndMeasure.getDipoleDensityContributionToRegionOfInterest(obj.membershipCube, obj, varargin{:});
            
            % weighted sum of dipole scalpmaps using dipole mass contributions to the domain as
            % weights.
            meanScalpMap = obj.scalpMapVisualizationPolarity * squeeze(sum(repmat(dipoleDenistyInRegion, [1, size(obj.dipoleAndMeasure.scalpmap.normalizedChannelWeight,2),  size(obj.dipoleAndMeasure.scalpmap.normalizedChannelWeight,3)]) .* obj.dipoleAndMeasure.scalpmap.normalizedChannelWeight, 1));
            
            if creareNewFigure
                figure;
            end;
            
            toporeplot(meanScalpMap, 'plotrad',0.5,  'intrad' , 0.5);
            set(gcf, 'name', [obj.label ' mean scalpmap']);
        end;
        
        function [sessionDipoleDensity uniqeDatasetId groupId] = getSessionDipoleDensity(obj, varargin)
            % [sessionDipoleDensity uniqeDatasetId groupId] = getSessionDipoleDensity;
            % get dipole denisty for each sessions that is associated with the domain (in units of 'dipole')
            [linearProjectedMeasure groupId uniqeDatasetId dipoleDensity] =  obj.dipoleAndMeasure.getProjectedMeasureForEachSession(obj.headGrid, obj.membershipCube, obj.projectionParameter, 'calculateMeasure', 'off');
            sessionDipoleDensity = sum(dipoleDensity);
        end;
        
        function [subjectDipoleDensity uniqeSubjectId] = getSubjectDipoleDensity(obj, varargin)
            % [subjectDipoleDensity uniqeDatasetId] = getSubjectDipoleDensity;
            % get dipole denisty for each subject (potentially from multiple sessions) that is associated with the domain (in units of 'dipole')
            [linearProjectedMeasure dipoleDensity uniqeSubjectId] =  obj.dipoleAndMeasure.getProjectedMeasureForEachSubject(obj.headGrid, obj.membershipCube, obj.projectionParameter, 'calculateMeasure', 'off');
            subjectDipoleDensity = sum(dipoleDensity);
        end;
        
        function totalVolume = getTotalVolume(obj, varargin)
            % totalVolume = getTotalVolume(varargin)
            % get total volume associated with the domain (in mm^3)
            
            volxelVolume = obj.headGrid.spacing ^ 3;
            totalVolume = sum(obj.membershipCube(:)) * volxelVolume;
        end;
        
        function totalMass = getTotalDipoleMass(obj, varargin)
            % totalMass = getTotalDipoleMass;
            % get total dipole mass volume associated with the domain (in units of 'Dipole')
            
            [dummy, dipoleDensity]= pr.meanProjection.getProjectionMatrix(obj.dipoleAndMeasure, obj.headGrid, obj.projectionParameter, obj.membershipCube);
            totalMass = sum(dipoleDensity);
        end;
        
        function subjectEntropy = getSubjectEntropy(obj, varargin)
            % subjectEntropy = getSubjectEntropy;
            % get entropy of dipole density contibuted by different subjects to the Domain. This
            % function combines ICs from all sessions associated with each subject.
            
            subjectDipoleDensity = obj.getSubjectDipoleDensity;
            
            % normalize denisty to have sum of 1 (and can be interpreted as probability)
            subjectDipoleDensity = subjectDipoleDensity / sum(subjectDipoleDensity);
            
            % ignore subjects with zero denisty.
            subjectDipoleDensity(subjectDipoleDensity < eps) = [];
            
            subjectEntropy = -sum(subjectDipoleDensity .* log(subjectDipoleDensity));
        end;
        
        function sessiontEntropy = getSessionEntropy(obj, varargin)
            % sessiontEntropy = getSessionEntropy;
            % get entropy of dipole density contibuted by different sessions to the Domain.
            
            subjectDipoleDensity = obj.getSessionDipoleDensity;
            
            % normalize denisty to have sum of 1 (and can be interpreted as probability)
            subjectDipoleDensity = subjectDipoleDensity / sum(subjectDipoleDensity);
            
            % ignore subjects with zero denisty.
            subjectDipoleDensity(subjectDipoleDensity < eps) = [];
            
            sessiontEntropy = -sum(subjectDipoleDensity .* log(subjectDipoleDensity));
        end;
        
        function domainArray = createChildDomain(obj, positionSubdomainId, dipoleAndMeasure, varargin)
            % domainArray = createChildDomain(positionSubdomainId, dipoleAndMeasure, varargin)
            % create new sub-domains (child domains) from the domain by segmenting domain locations
            % according to integer-valued labels (ids) in positionSubdomainId.
            if isempty(positionSubdomainId)
                domainArray = obj;
            else
             uniqueSubdomainId = unique(positionSubdomainId);
             numberOfChildDomains = length(uniqueSubdomainId);
             
             if numberOfChildDomains == 1
                 domainArray = obj;
             else % more than one child domain
                 % copy all variables into new segments (child Domains).
                 
                 childMemberShipCube = zeros(size(obj.membershipCube));
                 childMemberShipCube(obj.membershipCube) = positionSubdomainId;
                 
                 for i=1:numberOfChildDomains
                     domainArray(i) = obj;
                     
                     % add - followed by a number to distinguish child domains, e.g. Dmain 2-1,
                     % Domain 2-4...
                     domainArray(i).label = [domainArray(i).label '-' num2str(i)];
                     
                     domainArray(i).membershipCube = childMemberShipCube == i;
                     
                     % caluclate mean projected value for the child domain (by projecting to child
                     % domain locations)
                     [projectionMatrix dipoleDensity]= pr.meanProjection.getProjectionMatrix(dipoleAndMeasure, obj.headGrid, obj.projectionParameter, domainArray(i).membershipCube);
                     linearizedProjectedMeasure = dipoleAndMeasure.linearizedMeasure * projectionMatrix;
                     
                     dipoleDensity = dipoleDensity / sum(dipoleDensity);
                     domainArray(i).meanLinearizedProjectedMeasure = linearizedProjectedMeasure * dipoleDensity';
                 end;
             end
            end;
        end;
                
        function domainArray = segmentByDomainTopography(obj, dipoleAndMeasure, varargin)
            % domainArray = segmentByDomainTopography(obj, dipoleAndMeasure, varargin)
            % get positions of domain members
            
            position = obj.headGrid.getPosition(obj.membershipCube);
            if size(position, 1) > 1 % segment only if domain has more than one point.
            
            % calculate a pair-wise euclidean distance matrix between domain members
            pairwiseDistance = squareform(pdist(position));
            
            % define each pair connected if they are closer than a threshold
            connectivityThreshold = obj.headGrid.spacing * 3;
            pairIsConnected  = pairwiseDistance <= connectivityThreshold;
            
            
            % now we have to segment this pairwise connectivity matrix (representing a graph)
            % into few subgrpahs that have no connectivity to each other.                    
            positionNewLabel = pr.connected_components(pairIsConnected);              
            domainArray = obj.createChildDomain(positionNewLabel, dipoleAndMeasure);
            else % if domain has only one point
                domainArray = obj;
            end;
        end;
    end;
end