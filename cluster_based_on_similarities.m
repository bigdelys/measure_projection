function clusterInfo = cluster_based_on_similarities(similarity, minClusterToExamplarSimilarity, maxBetweenClusterExamplarSimilarity, minNumberOfClusters, plotMds)
% clusterInfo = cluster_based_on_similarities(similarity, minClusterToExamplarSimilarity, maxBetweenClusterExamplarSimilarity, minNumberOfClusters, plotMds)
% similarity: similarity matrix for example pairwise correlations
% minClusterToExamplarSimilarity: each cluster member should have at least this amount of similarity to its exemplar, otherwise it will be considered an outlier.
% maxBetweenClusterExamplarSimilarity: {optional} number of clusters is selected in a way that no two cluster exemplar are closer (more similar)than this value together. It can be set equal to minClusterToExamplarSimilarity which creates non-overlapping clusters, or set to an smaller value to allow for cluster exemplar to get closer to each other (and produce more clusters). By default it is set to minClusterToExamplarSimilarity. You can also use [] to indicate the selection of default value.
% minNumberOfClusters = 2: {optional} our best guess for minimum cluster number, it should not be
% too high, and if is low it will only increases the number of steps to find the right number of clusters. It is
% always safe to set this to 2.
% plotMds: {optional} plot a 2-D or 3D representation of data and clusters using multi-dimensional
% scaling. use true or '2d' for a 2D plot and '3d' for a 3D plot. Use False to prevent calculating
% MDS and plotting.
% OUTPUT
% clusterInfo.IDX contains cluster IDs for each input point.
%
% set minClusterToExamplarSimilarity to -Inf to turn off outlier detection.

if nargin < 3 || isempty(maxBetweenClusterExamplarSimilarity)
    maxBetweenClusterExamplarSimilarity = minClusterToExamplarSimilarity;
end;

if nargin<4 || isempty(minNumberOfClusters)
    minNumberOfClusters = 2;
end;

if nargin<5
    plotMds = '2d';
end;

if islogical(plotMds) & plotMds % default is 3D if input is true
    plotMds = '3d';
end;

if maxBetweenClusterExamplarSimilarity < minClusterToExamplarSimilarity
    fprintf('Warning: maxBetweenClusterExamplarSimilarity is less than minClusterToExamplarSimilarity, this will very likely results in ill-defined clusters. \n You should make maxBetweenClusterExamplarSimilarity equal or higher than minClusterToExamplarSimilarity (to allow some points to be in proximity to both exemplars).\n');
end;

% add a virtual node for clustering all outliers with it.
similarity(end+1,:) = minClusterToExamplarSimilarity;
similarity(:,end+1) = minClusterToExamplarSimilarity;

maxSimilarityBetweenClusterExamplars = -Inf;

%clusterInfo.iteration.numberOfClusters = [];
%clusterInfo.iteration.maxSimilarityBetweenClusterExamplars = [];

clusterInfo.maxBetweenClusterExamplarSimilarity = maxBetweenClusterExamplarSimilarity;
clusterInfo.minClusterToExamplarSimilarity = minClusterToExamplarSimilarity;
clusterInfo.minNumberOfClusters = minNumberOfClusters;


% first find the value of preference for 2 clusters
% we do not want an exact number, so tolerance is set to 40%
%if exist('apclusterK_mex', 'file') == 2 % when an m file with this name exist, use the faster MEX version.
try
    [examplarIdx,netsim,dpsim,expref, prefForMinNumber] = apclusterK_mex(similarity, minNumberOfClusters, 40); % find the preference for two clusters
catch
    [examplarIdx,netsim,dpsim,expref, prefForMinNumber] = apclusterK(similarity, minNumberOfClusters, 40); % find the preference for two clusters
end;

examplar = unique(examplarIdx);
numberOfClusters = numel(examplar);

clusterInfo.numberOfClusters = numberOfClusters;
clusterInfo.numberOfOutliers = 0;


[outlierClusterNumber virtualNodeId IDX comps]  = find_possible_outlier_cluster_number(similarity, examplar);

% last one is the imaginary outlier with constant similarity to all
clusterInfo = prepare_output;

preference = prefForMinNumber;
counter = 1;
numberOfClusters = minNumberOfClusters;

% sometimes the number of clusters remain constant across a large range of preference, we should
% exist after ~50 iterations in this cases to prevent an infinitie loop.
while counter < 100 & (numberOfClusters <= 2 || maxSimilarityBetweenClusterExamplars < maxBetweenClusterExamplarSimilarity)
    
    if counter > 1
        clusterInfo = prepare_output;
        
        
        if exist('similarityBetweenClusterExamplars', 'var')
            clusterInfo.similarityBetweenClusterExamplars = similarityBetweenClusterExamplars;
        else
            clusterInfo.similarityBetweenClusterExamplars = nan;
        end;
    end;
    
    try
        [examplarIdx,netsim,dpsim,expref]=apclustermex(similarity,preference,'dampfact',0.9,'convits',200,'maxits',2000,'nonoise');
    catch
        [examplarIdx,netsim,dpsim,expref]=apcluster(similarity,preference,'dampfact',0.9,'convits',200,'maxits',2000,'nonoise');
    end;
    
    
    examplar = unique(examplarIdx);
    numberOfClusters = numel(examplar);
    
    % check if there exist an outlier cluster
    [outlierClusterNumber virtualNodeId IDX comps]  = find_possible_outlier_cluster_number(similarity, examplar);
    
    %%
    if numberOfClusters > 1
        % exclude outlier cluster members
        examplarIdsExceptVirtualNode = setdiff(examplar, examplarIdx(virtualNodeId));
        
        similarityBetweenClusterExamplars = similarity(examplarIdsExceptVirtualNode, examplarIdsExceptVirtualNode);
        
        % put nans on the diagonal, then ignore them when calculating max
        
        for i=1:size(similarityBetweenClusterExamplars, 1)
            similarityBetweenClusterExamplars(i,i) = nan;
        end;
        
        maxSimilarityBetweenClusterExamplars = max(max(similarityBetweenClusterExamplars(~isnan(similarityBetweenClusterExamplars))));
    else
        maxSimilarityBetweenClusterExamplars = -Inf;
    end;
    
    preference = preference * 0.95;
    counter = counter + 1;
    
    if mod(counter,5) == 0
        if isempty(outlierClusterNumber)
            numberOfOutliers = 0;
        else
            numberOfOutliers = numel(find(IDX == outlierClusterNumber)) - 1;
        end;
        percentageOfOutliers = round(100 * numberOfOutliers / numel(IDX));
        fprintf(['iteration = ' num2str(counter) ', number of outliers = ' num2str(numberOfOutliers) ' (' num2str(percentageOfOutliers) ' percent) ' ', number of clusters (including the outlier cluster)= ' num2str(numberOfClusters) '\n']);
    end;
end;

% if one of the two clusters was the outliers, then there are no
% other cluster exemplars to compare with, so we have to start from
% a higher number of minimum clusters.
if isempty(maxSimilarityBetweenClusterExamplars)
    fprintf('Only one non-outlier cluster was found, you may want to try starting with a higher number of minimum clusters.\n');
end;

if counter == 1
    fprintf('Warning: inner loop exited and clusterInfo only contains information about the original clustering.\n');
end;

fprintf(['Final number of clusters = ' num2str(clusterInfo.numberOfClusters) ', number of outliers = ' num2str(clusterInfo.numberOfOutliers) '\n']);

if strcmpi(plotMds, '2d') || strcmpi(plotMds, '3d')
    try
        plot_multi_dimensional_scaling(clusterInfo, plotMds, similarity);
    catch
        warning('For some reason MDS visualiziation failed.');
    end;
end;


%% sub-functions


    function clusterInfo = prepare_output
        clusterInfo.numberOfClusters = numberOfClusters;
        clusterInfo.outlierClusterNumber = 0;
        clusterInfo.IDX = IDX(1:end-1);
        
        if isempty(outlierClusterNumber) || minClusterToExamplarSimilarity == -Inf
            clusterInfo.numberOfOutliers = 0;
            clusterInfo.examplarId = examplar;
        else
            clusterInfo.numberOfOutliers = numel(find(IDX == outlierClusterNumber)) - 1;
            % change outlier cluster IDX to zero
            clusterInfo.IDX(find(clusterInfo.IDX == outlierClusterNumber)) = 0;
            % shift cluster numbers for the ones above it down
            clusterInfo.IDX(clusterInfo.IDX > outlierClusterNumber) = clusterInfo.IDX(clusterInfo.IDX > outlierClusterNumber) - 1;
            
            % we have to fix this correspondence between exemplars and IDX and also
            % there ia a fundamental problem that maybe outlier cluster is containing the virtual nodes
            % but if we ignore the virtual node still it has a different exemplar and all of points are
            % closer than threshold, so it is not an actuall outlier cluster
            clusterInfo.examplarId = examplar;
            clusterInfo.examplarId(outlierClusterNumber) = [];
        end;
    end

    function [outlierClusterNumber virtualNodeId IDX comps]  = find_possible_outlier_cluster_number(similarity, examplar)
        % an outlier cluster should inlcude the virual node, but it also MUST have the outlier node as
        % its exemplar.
        virtualNodeId = size(similarity,1);
        
        outlierClusterNumber = find(examplar == virtualNodeId);
        
        % if there was no cluster with th e exemplat being the virtual node, then
        % check to see which cluster contains the virtual node.
        
        IDX = zeros(1,length(examplar));
        for i=1:length(examplar)
            comps = find(examplarIdx == examplar(i));
            IDX(comps) = i;
            if  ~isempty(outlierClusterNumber) & ismember(virtualNodeId, comps)
                % if a cluster includes the virtual node, we need to see if it is really an outlier
                % cluster or just have happened to include the virtual node.
                % to do this, we calculate the similarities from all of its members to its exemplar
                % and see if any of them is less than minimim allowed.
                
                clusterSimilarities = similarity(examplar(i),setdiff(comps, [virtualNodeId examplar(i)] )); % exclude the virtual node and the exemplar itself
                if min(clusterSimilarities(:)) < minClusterToExamplarSimilarity
                    outlierClusterNumber = i;
                end;
            end;
        end;
    end




    function plot_multi_dimensional_scaling(clusterInfo, plotMds, similarity)
        dissimilarity = max(max(similarity(1:end-1, 1:end-1))) - similarity(1:end-1, 1:end-1);
        
        for i=1:size(dissimilarity,1)
            for j=i:size(dissimilarity,2)
                dissimilarity(i,j) = dissimilarity(j,i);
            end;
        end;
        
        % make diagonal Exactly zero (required by mdscale)
        dissimilarity = dissimilarity - diag(diag(dissimilarity));
        
        if strcmpi(plotMds, '2d')
            fprintf('calculating a 2D representation of similarities using multidimensional scaling...');
            [pos stress]= mdscale(double(dissimilarity), 2);
            fprintf('multidimensional scaling stress (measure of 2D projection accuracy) is %f.\n', stress);
            clusterInfo.positionIn2D = pos;
        else
            fprintf('calculating a 3D representation of similarities using multidimensional scaling...');
            [pos stress]= mdscale(double(dissimilarity), 3);
            fprintf('multidimensional scaling stress (measure of 3D projection accuracy) is %f.\n', stress);
            clusterInfo.positionIn3D = pos;
        end;
        
        figure;
        hold on;
        %scatter(pos(:,1), pos(:,2), 50, clusterInfo.IDX, 'filled');
        colorTable = lines(length(unique(clusterInfo.IDX)));
        
        % assign Gray color for outliers
        if clusterInfo.numberOfOutliers
            colorTable(1,:) = [0.7 0.7 0.7];
            allUniqueClusterIds = [0 1:(clusterInfo.numberOfClusters-1)];
        else
            allUniqueClusterIds = [1:clusterInfo.numberOfClusters];
        end;
        
        color = value2color(clusterInfo.IDX, colorTable);
        
        for i=1:length(allUniqueClusterIds)
            % id = find(clusterInfo.IDX == i-1);
            id =  find(clusterInfo.IDX == allUniqueClusterIds(i));
            if strcmpi(plotMds, '2d')
                scatter(pos(id,1), pos(id,2), 50, color(id,:), 'filled');
            else
                scatter3(pos(id,1), pos(id,2), pos(id,3), 50, color(id,:), 'filled');
                view(45,45);
                grid on;
            end;
        end;
        
        axis equal;
    end
end
