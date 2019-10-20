classdef subjectSpace
    % holds information and methods (functions) to work with a pairwise subject (or session) similarity matrix, obtained from a certain
    % Projected measure, Dipole desnity or a combination of these.
    
    properties %(SetAccess = 'immutable')
        headGrid;
        projectionParameter % encaplustae all projection parameters, like number of Std., Gaussian Width and whether in-brain density should be normalized
        dipoleAndMeasureWithEmptyMeasure % hold a copy of dipoleAndMeasure object used to create the subject space, but the measure field (linearizedMeasure) filed is emptied to save memory.
        
        dipoleDenistyHistogramSimilarityFunction
        regionOfInterestProbability
        basedOn
        sessionPairSimilaity
        sessionPairSimilaityAugmentedWithAverage
        subjectName
        subjectNumber
        sessionsOrSubjectsWithZeroDipoleDensity = [];
        sessionsOrSubjectsWithNoDipoleDensityRemoved = false;
        
        subjectGroupName
        subjectGroupNumber
        uniqueGroupName
        %sessionDipoleDensityPairSimilaity
    end; % properties that cannot be changed outside the condtructor
    methods
        function [obj regionOfInterestId linearProjectedMeasure dipoleDensity] = subjectSpace(dipoleAndMeasure, headGrid, projectionParameter, regionOfInterest, varargin)
            % [obj regionOfInterestId linearProjectedMeasure dipoleDensity] = subjectSpace(dipoleAndMeasure, headGrid, projectionParameter, varargin)
            %
            % regionOfInterest           either a regionOfInterest object or a 3 dimensional array of ROI probability
            
            % optional key, value pairs
            % basedOn                               Either 'measure' (like ersp) or 'dipoleDensity'
            % weightMeasureByPairDipoleDensity      true or false (default is false)
            % removeSessionsWithNoDipoleDensity     true or false (default is false)
            % histogramSimilarity                   method to calculate the similarity between diple density histograms (only relevent to dipole density):
            %                                       one of : 'product', 'KL divergence', 'intersect'
            %                                       and 'fidelity' (default is 'product', which is the inner product)
            
            inputOptions = finputcheck(varargin, ...
                { 'regionOfInterestProbability'     'real'     []                        []; ... % by default use inside brain volume
                'basedOn'      'string'     {'measure' 'dipoleDensity'}       'measure';...
                'weightMeasureByPairDipoleDensity'     'boolean'     []       false;...
                'removeSessionsWithNoDipoleDensity'   'boolean'       [] false;...
                'histogramSimilarity'     'string' {'correlation' 'product' 'KL divergence' 'intersect' 'fidelity'} 'correlation';...
                'separateSessions'        'boolean'         []  true;...
                });
            
            % Todo: add an option for the aggregation of similarities with L-2 (euclidean) instead
            % of average (suggested by Scott);
            
            obj.headGrid = headGrid;
            obj.dipoleAndMeasureWithEmptyMeasure = dipoleAndMeasure;
            obj.dipoleAndMeasureWithEmptyMeasure.linearizedMeasure = [];
            
            obj.projectionParameter = projectionParameter;
            obj.basedOn = inputOptions.basedOn;
            sessionsOrSubjectsWithNoDipoleDensityRemoved = inputOptions.removeSessionsWithNoDipoleDensity;
            
            if nargin < 4 || isempty(regionOfInterest) % default area in the whole inside brain volume
                obj.regionOfInterestProbability =  double(headGrid.insideBrainCube);
            else                                             
                % if a regionOfInterest object is provided, use its membershipProbabilityCube
                % property, otherwise assume 'regionOfInterest' variable is a 3d array containing
                % probabilities of region membership.
                 if isa(regionOfInterest, 'pr.regionOfInterest')
                     obj.regionOfInterestProbability = regionOfInterest.membershipProbabilityCube;
                 else
                     obj.regionOfInterestProbability = regionOfInterest;
                 end;
            end;
            
            regionOfInterest = obj.regionOfInterestProbability > 0.001; % minimum probability to consider location
            regionOfInterestId = find(regionOfInterest);
            
            obj.dipoleDenistyHistogramSimilarityFunction = inputOptions.histogramSimilarity;
            
            augmentAverage = true; % add average projection to the start of the session indices (a mean session).
            normalizeMeasureByTotalPairwiseDipoleDensity = true;
            
            obj.regionOfInterestProbability = obj.regionOfInterestProbability / sum(obj.regionOfInterestProbability(:)); % make the sum equal to one, so the calculated similarity values becomes an average and is not dependent on the volume of the region.
            
            if strcmpi(inputOptions.basedOn, 'dipoleDensity')
                if inputOptions.separateSessions
                    [linearProjectedMeasure groupId uniqeDatasetId dipoleDensity] = dipoleAndMeasure.getProjectedMeasureForEachSession(headGrid, regionOfInterest, obj.projectionParameter, 'calculateMeasure', 'off');
                else % use subjects (instead of separating projections on sessions).
                    [linearProjectedMeasure dipoleDensity uniqeSubjectId] = dipoleAndMeasure.getProjectedMeasureForEachSubject(headGrid, regionOfInterest, obj.projectionParameter, 'calculateMeasure', 'off'); 
                end
            else % measure
                if inputOptions.separateSessions
                    [linearProjectedMeasure groupId uniqeDatasetId dipoleDensity] = dipoleAndMeasure.getProjectedMeasureForEachSession(headGrid, regionOfInterest, obj.projectionParameter);
                else % based on subejcts instead of sessions
                    [linearProjectedMeasure dipoleDensity uniqeSubjectId] = dipoleAndMeasure.getProjectedMeasureForEachSubject(headGrid, regionOfInterest, obj.projectionParameter);
                end;
            end;
            
            if augmentAverage
                averageSessionDipoleDensity = mean(dipoleDensity,2);
                dipoleDensity = cat(2, averageSessionDipoleDensity, dipoleDensity);
                
                if strcmpi(inputOptions.basedOn, 'measure')
                    [projectionMatrix averageSessionDipoleDensity]= pr.meanProjection.getProjectionMatrix(dipoleAndMeasure, headGrid, projectionParameter, regionOfInterest);
                    averageSessionLinearProjectedMeasure = dipoleAndMeasure.linearizedMeasure * projectionMatrix;
                    
                    linearProjectedMeasure = cat(3, averageSessionLinearProjectedMeasure, linearProjectedMeasure);
                end;
            end;
            
            
            if strcmpi(inputOptions.basedOn, 'dipoleDensity')
                % normalize total density for each session (makes sense most when the whole in-brain space
                % used).
                sessionTotalDensity = sum(dipoleDensity,1);
                for i=1:size(dipoleDensity,2)
                    dipoleDensity(:,i) = dipoleDensity(:,i) / sessionTotalDensity(i);
                end;
                
                switch obj.dipoleDenistyHistogramSimilarityFunction
                    case 'product'
                        % histogram similarity method 1 (sum of Pi*Pj)
                        sessionPairSimilaity = dipoleDensity' * dipoleDensity;
                        
                    case 'correlation'
                        % histogram similarity method 2 (correlation), seems to be the best as the
                        % ratio for same-subject F value was highest in RSVP study.
                        sessionPairSimilaity = corrcoef(dipoleDensity);
                        
                    case 'KL divergence' % does not seems to be too good , as P values for just dipole denisty where higher, around 0.08 instead of 0.02
                        % histogram similarity method 3 (-kl_divergence)
                        sessionPairSimilaity = 0;
                        for i = 1:size(dipoleDensity,2)
                            for j = 1:size(dipoleDensity,2)
                                sessionPairSimilaity(i,j) = -pr.kl_divergence(dipoleDensity(:,i), dipoleDensity(:,j), 1);
                            end;
                        end;
                        
                    case 'intersect'
                        % histogram similarity method 3 (intersect)
                        sessionPairSimilaity = 0;
                        for i = 1:size(dipoleDensity,2)
                            for j = 1:i
                                sessionPairSimilaity(i,j) = sum(min(dipoleDensity(:,i), dipoleDensity(:,j)));
                                sessionPairSimilaity(j,i) = sessionPairSimilaity(i,j); % since it is symmetric
                            end;
                        end;
                        
                    case 'fidelity'
                        % histogram similarity method 4 (sum of sqrt of Pi*Pj)
                        sessionPairSimilaity = 0;
                        for i = 1:size(dipoleDensity,2)
                            for j = 1:i
                                sessionPairSimilaity(i,j) = sum((dipoleDensity(:,i) .* dipoleDensity(:,j)).^0.5);
                                sessionPairSimilaity(j,i) = sessionPairSimilaity(i,j); % since it is symmetric
                            end;
                        end;
                    otherwise
                        error('Measure Projection: Histogram distance could not be recognized.');
                end;
                
                sessionDesnityPairSimilaity = sessionPairSimilaity;
            else % use eithe only measure or both measure and dipole density

             %   some locations have zero projection from certain subjects and pdist have some
             %   issues with this (either errors in some old Matlab version or warnings in the
             %   latest versions), to prevent these we only calculate for non-zero subjects and then
             %   fill-up the matrix for all subjects accordingly.
                correlationSimilaity = zeros(size(linearProjectedMeasure, 2), size(linearProjectedMeasure, 3), size(linearProjectedMeasure, 3));
                for locationNumber = 1:size(linearProjectedMeasure, 2)
                    matrixWithPotentialZeroColumns = squeeze(linearProjectedMeasure(:,locationNumber,:));
                    zeroColumns = var(matrixWithPotentialZeroColumns) < eps;
                    
                    % remove columns with all zeros
                    matrixWithNoZeroColumns = matrixWithPotentialZeroColumns;
                    matrixWithNoZeroColumns(:,zeroColumns) = [];
                    
                    % fill-ip appropriate parts of the matrix (other parts are zero)
                    correlationSimilaity(locationNumber,~zeroColumns,~zeroColumns) = 1-squareform(pdist(matrixWithNoZeroColumns', 'correlation'));
                    
                    % make sure there are all ones on the diagonal since we have placed zeros for
                    % zero columns now.
                    for i=1:size(correlationSimilaity,2)
                        for j=1:size(correlationSimilaity,3)
                            correlationSimilaity(i,j) = 1;
                        end;
                    end;
                end;
                
                % changes nans to zeros (if any left, but they should not in principle)
                correlationSimilaity(isnan(correlationSimilaity)) = 0;
                
                fishersZSimilarity = pr.fishersZfromCorrelation(correlationSimilaity);
                % mutualInformationSimilarity = correlationSimilaity;
                
                % weight each location similarity by the multipication of each of two sesesion dipole denisty.
                sessionPairSimilaity = 0;
                sessionDesnityPairSimilaity = 0;
                for locationNumber = 1:size(linearProjectedMeasure, 2)
                    
                    
                    if inputOptions.weightMeasureByPairDipoleDensity
                        sessionPairSimilaity = sessionPairSimilaity + obj.regionOfInterestProbability(regionOfInterestId(locationNumber)) * squeeze(fishersZSimilarity(locationNumber,:,:)) .* (dipoleDensity(locationNumber,:)' * dipoleDensity(locationNumber,:));
                    else
                        sessionPairSimilaity = sessionPairSimilaity + obj.regionOfInterestProbability(regionOfInterestId(locationNumber)) * squeeze(fishersZSimilarity(locationNumber,:,:));
                    end;
                    
                    sessionDesnityPairSimilaity = sessionDesnityPairSimilaity + obj.regionOfInterestProbability(regionOfInterestId(locationNumber)) * dipoleDensity(locationNumber,:)' * dipoleDensity(locationNumber,:);
                end;
                
                % normalize by the total pair-wise dipole density, but only if it was used above (both density
                % and meaure were used).
                if normalizeMeasureByTotalPairwiseDipoleDensity & inputOptions.weightMeasureByPairDipoleDensity
                    sessionPairSimilaity = sessionPairSimilaity ./ sessionDesnityPairSimilaity;
                    sessionPairSimilaity(isnan(sessionPairSimilaity)) = 0;
                end;
            end;
            
            try
                [uniqeDatasetId uniqeDatasetIdOriginalIndices] = unique(obj.dipoleAndMeasureWithEmptyMeasure.datasetId);
                
                % remove session with no dipole denisty in the region of interest
                sessionsOrSubjectsWithZeroDipoleDensity = find(sum(dipoleDensity(:,2:end),1) < eps); % ignore the average
                obj.sessionsOrSubjectsWithZeroDipoleDensity = sessionsOrSubjectsWithZeroDipoleDensity;
                
                if inputOptions.removeSessionsWithNoDipoleDensity
                    sessionPairSimilaity(augmentAverage + sessionsOrSubjectsWithZeroDipoleDensity, :) = []; % +1 is to offset average
                    sessionPairSimilaity(:, augmentAverage + sessionsOrSubjectsWithZeroDipoleDensity) = [];
                    uniqeDatasetIdOriginalIndices(sessionsOrSubjectsWithZeroDipoleDensity) = []; % since they are removed
                end;
                
                obj.subjectName = obj.dipoleAndMeasureWithEmptyMeasure.subjectName(uniqeDatasetIdOriginalIndices);
                obj.subjectNumber = obj.dipoleAndMeasureWithEmptyMeasure.subjectNumber(uniqeDatasetIdOriginalIndices);
                
                obj.subjectGroupName = obj.dipoleAndMeasureWithEmptyMeasure.groupName(uniqeDatasetIdOriginalIndices);
                obj.subjectGroupNumber = obj.dipoleAndMeasureWithEmptyMeasure.groupNumber(uniqeDatasetIdOriginalIndices);
                obj.uniqueGroupName = obj.dipoleAndMeasureWithEmptyMeasure.uniqueGroupName;
                
            catch % a temporary hack for using subjects indtead, should fix later
                obj.subjectName = obj.dipoleAndMeasureWithEmptyMeasure.uniqueSubjectName;
                obj.subjectNumber = 1:length(obj.dipoleAndMeasureWithEmptyMeasure.uniqueSubjectName);
            end;
            
            obj.sessionPairSimilaity = sessionPairSimilaity(2:end,2:end);
            obj.sessionPairSimilaityAugmentedWithAverage = sessionPairSimilaity;
        end;
        function varargout = plot(obj, varargin)
            
            inputOptions = finputcheck(varargin, ...
                { 'newFigure'     'boolean'     []  true; ... % by default use inside brain volume
                  'lineForSubject'          'boolean'     []  true; ... % plot lines between sessions from the same subject
                  'withAugmentedAverage'    'boolean'     []  true; ... % plot lines between sessions from the same subject
                  'numberOfDimensions'    'integer'     [2 3]  2; ... % plot lines between sessions from the same subject
                });
            
            showWithAugmentedAverage = inputOptions.withAugmentedAverage;
            
            if showWithAugmentedAverage
                mdsSimilarityMatrix = double(obj.sessionPairSimilaityAugmentedWithAverage);
            else
                mdsSimilarityMatrix = double(obj.sessionPairSimilaity);
            end;
            
            mdsSimilarityMatrix = (mdsSimilarityMatrix + mdsSimilarityMatrix')/2; % make sure it is perfectly symmetric
            mdsSimilarityMatrix = mdsSimilarityMatrix - min(mdsSimilarityMatrix(:)); % makes sure it us positive
            mdsSimilarityMatrix = mdsSimilarityMatrix / max(mdsSimilarityMatrix(:)); % make sure maximum is less or equal to one.
            
            for i=1:size(mdsSimilarityMatrix,1) % make sure the diagonal is all ones .
                mdsSimilarityMatrix(i,i) = 1;
            end;
            
            [pos stress] = robust_mdscale(mdsSimilarityMatrix, inputOptions.numberOfDimensions, 100);
            
            fprintf('MDS stress = %d%%\n', round(100 * stress));
            
            subjectName = obj.subjectName;
            subjectNumber = obj.subjectNumber;
            subjectColor = value2color(subjectNumber, @lines);
            
            if showWithAugmentedAverage
                subjectColor = cat(1, [0 0 0], subjectColor);
            end;
            
            if inputOptions.newFigure
                figure;
            end;
            
            
            % to set axis limits correctly
            if inputOptions.numberOfDimensions == 2
                scatter(pos(:,1), pos(:,2), 1, 'w.');
            else
                scatter3(pos(:,1), pos(:,2), pos(:,3), 1, 'w.');
            end;
           
            if inputOptions.lineForSubject % draw lines for subject session pairs
                subjectNumberMatrix = repmat(subjectNumber, [length(subjectNumber) 1]);
                sameSubject = subjectNumberMatrix == subjectNumberMatrix';
                sameSubject = logical(sameSubject - diag(diag(sameSubject)));
                
                for i=1:size(sameSubject,1)
                    for j=1:i
                        if sameSubject(i,j)
                            if inputOptions.numberOfDimensions == 2
                                line([pos(i+showWithAugmentedAverage,1) pos(j+showWithAugmentedAverage,1)], [pos(i+showWithAugmentedAverage,2) pos(j+showWithAugmentedAverage,2)], 'color', subjectColor(i+showWithAugmentedAverage,:), 'linewidth', 3);
                            else
                                line([pos(i+showWithAugmentedAverage,1) pos(j+showWithAugmentedAverage,1)], [pos(i+showWithAugmentedAverage,2) pos(j+showWithAugmentedAverage,2)], [pos(i+showWithAugmentedAverage,3) pos(j+showWithAugmentedAverage,3)], 'color', subjectColor(i+showWithAugmentedAverage,:), 'linewidth', 3);
                            end;
                        end;
                    end;
                end;
            end;
            
            
            if showWithAugmentedAverage
                subjectName = cat(2, 'Average', subjectName);
            end;
            
            if inputOptions.numberOfDimensions == 2
                set(gca, 'xTick', [], 'yTick', [], 'xcolor' ,[1 1 1], 'ycolor', [1 1 1]);
            else
                set(gca, 'xTick', [], 'yTick', [], 'xcolor' ,[1 1 1], 'ycolor', [1 1 1],'zcolor', [0 0 0]);
            end;
            
            axis equal
            
            %             for i=1:size(pos,1)
            %                 if ~showWithAugmentedAverage || i>1
            %                 circle(pos(i,1), pos(i,2), 0.035, subjectColor(i,:), subjectColor(i,:));
            %                 end;
            %             end;
            
            % increase ids with one if augmented with average
            sessionsOrSubjectsWithZeroDipoleDensity = obj.sessionsOrSubjectsWithZeroDipoleDensity + double(showWithAugmentedAverage);
            
            for i=1:size(pos,1)
                if showWithAugmentedAverage & i ==1
                    textColor = [0 0 0];
                    backgroundColor = [1 1 1];
                    edgeColor = [0 0 0];
                else
                    if ismember(i, sessionsOrSubjectsWithZeroDipoleDensity) % make washed-out color for sessions with zero dipole denisty
                        backgroundColor = 1 - 0.2 * (1-subjectColor(i,:));
                        textColor = [0.5 0.5 0.5]'; % gray color
                    else
                        backgroundColor = subjectColor(i,:);
                        textColor = [1 1 1]';
                    end;
                    
                    edgeColor = backgroundColor;
                end;
                if inputOptions.numberOfDimensions == 2
                    text(pos(i,1)+ 0*0.02, pos(i,2), subjectName{i}, 'HorizontalAlignment', 'center', 'BackgroundColor', backgroundColor, 'color', textColor, 'fontsize', 14, 'EdgeColor', edgeColor);
                else
                    text(pos(i,1)+ 0*0.02, pos(i,2), pos(i,3), subjectName{i}, 'HorizontalAlignment', 'center', 'BackgroundColor', backgroundColor, 'color', textColor, 'fontsize', 14, 'EdgeColor', edgeColor);
                end;
            end;
            
            if nargout > 0
                varargout{1} = pos;
                if nargout > 1
                    varargout{2} = stress;
                end;
            end;
        end;
        function varargout = plot3d(obj, varargin)
            
            % add the option which makes it 3D
            varargin{end+1} = 'numberOfDimensions';
            varargin{end+1} = 3;
            
            % pass output argumnets
            if nargout == 1
                varargout{1} = obj.plot(varargin{:});
            elseif  nargout == 2
                [varargout{1} varargout{2}] = obj.plot(varargin{:});
            else
                obj.plot(varargin{:});
            end
        end;
        function [significance ratio] = getSignificanceOfSessionPairSubsetSimilarities(obj,sessionPairSubset, varargin)
                
            inputOptions = finputcheck(varargin, ...
                { 'numberOfPermutations'     'integer'     [2 Inf]      100000; ... % by default use inside brain volume
                });
                                    
            sessionPairComplementarySubset = ~sessionPairSubset;
            sessionPairComplementarySubset = logical(sessionPairComplementarySubset - diag(diag(sessionPairComplementarySubset)));
            
            averageSameSubjectSimilarity =  mean(obj.sessionPairSimilaity(sessionPairSubset));
            averageNotSameSubjectSimilarity =  mean(obj.sessionPairSimilaity(sessionPairComplementarySubset));
            
            ratio = averageSameSubjectSimilarity / averageNotSameSubjectSimilarity;
            
            surrogateRatio = zeros(inputOptions.numberOfPermutations, 1);
            for i=1:inputOptions.numberOfPermutations
                randomPermutation = randperm(size(obj.sessionPairSimilaity,1)); % without repetition
                % randomPermutation = randi(size(obj.sessionPairSimilaity,1), 1, size(obj.sessionPairSimilaity,1)); % with repetition
                
                surrogateSessionPairSimilaity = obj.sessionPairSimilaity(randomPermutation, randomPermutation);
                surrogateAverageSameSubjectSimilarity = mean(surrogateSessionPairSimilaity(sessionPairSubset));
                surrogateAverageNotSameSubjectSimilarity = mean(surrogateSessionPairSimilaity(sessionPairComplementarySubset));
                
                surrogateRatio(i) = surrogateAverageSameSubjectSimilarity / surrogateAverageNotSameSubjectSimilarity;
            end;
            
            significance =  sum(surrogateRatio >= ratio) / inputOptions.numberOfPermutations;
            significance = max(significance, 1/inputOptions.numberOfPermutations);
        end;
        function [significance ratio] = getSignificanceOfSameSubjectSessions(obj, varargin)
            subjectNumberMatrix = repmat(obj.subjectNumber, [length(obj.subjectNumber) 1]);
            sameSubject = subjectNumberMatrix == subjectNumberMatrix';
            sameSubject = logical(sameSubject - diag(diag(sameSubject)));
            
            if ~any(sameSubject(:))
                error('Measure Projection: There are no two sessions that are both associated with the same subject.');
                exit;
            end;
            
            [significance ratio] = obj.getSignificanceOfSessionPairSubsetSimilarities(sameSubject, varargin{:});
        end;
        function [significance correlation] = getSignificanceOfCorrelationWithPairSimilarity(obj, pairwiseSimilarityOrDissimilarity, numberOfPermutations, varargin)
            % here we compare the Spearman correlation between the provided pair-wise
            % (dis)similarity value and the similarity between subjects.
            
            if nargin < 3
                numberOfPermutations = 5000;
            end;
            
            % assume given 'similarityOrDissimilarity' variable is similarity if the larget diagonal
            % value is nonzero (since dissimilarity should have zeros on diagonal)
            isSimilarity = max(diag(pairwiseSimilarityOrDissimilarity)) > eps('single');
            
            %orderMatrix = zeros(size(obj.sessionPairSimilaity));
            %orderMatrix(:) = 1:length(orderMatrix(:));
            
            % we need to exclude diagonal elements (subject similarity with itself) from
            % calculations. This is done by placing nans which are then ignored by corr().
            processedSessionPairSimilaity = obj.sessionPairSimilaity;
            for i=1:size(processedSessionPairSimilaity, 1)
                processedSessionPairSimilaity(i,i) = nan;
            end;
            
            pairwiseSimilarityOrDissimilarity = tiedrank(pairwiseSimilarityOrDissimilarity);            
            processedSessionPairSimilaity = tiedrank(processedSessionPairSimilaity);            
            
            correlation = corr(processedSessionPairSimilaity(:), pairwiseSimilarityOrDissimilarity(:), 'rows', 'pairwise');
            
            surrogateCorrelations = zeros(numberOfPermutations, 1);
            for i=1:numberOfPermutations
                randomPermutation = randperm(size(pairwiseSimilarityOrDissimilarity,1));
                surrogatePairwiseSimilarityOrDissimilarity = pairwiseSimilarityOrDissimilarity(randomPermutation, randomPermutation);
                surrogateCorrelations(i) = corr(processedSessionPairSimilaity(:), surrogatePairwiseSimilarityOrDissimilarity(:), 'rows', 'pairwise');
            end;
            
            if isSimilarity
                significance = sum(surrogateCorrelations >= correlation) / numberOfPermutations;
            else % for dissimilarity
                significance = sum(surrogateCorrelations <= correlation) / numberOfPermutations;
            end;
            
            significance = max(significance, 1 / numberOfPermutations);
        end;
    end
end
