function [outputPolarity scalpMapInnerProduct finalCost]= normalize_ic_polarity(scalpMap, method, polarityisFixed, normalizeScalpMapIntensity)
% [outputPolarity scalpMapInnerProduct finalCost]= normalize_ic_polarity(scalpMap, method, polarityisFixed, normalizeScalpMapIntensity)
%
% scalpMap is N x Q array for N ICs, each with Q elements in their scalpmap
% method either 'convex' or 'greedy;'
% optional polarityisFixed is 1 x N
% normalizeScalpMapIntensity is a boolean value which control whether or not the intensity
% (euclidean norm, vector length) of scalmaps should be normalized (to one) before calculating their
% inner products. Default value = false;

if nargin < 3 || isempty(polarityisFixed)
    polarityisFixed = false(1,size(scalpMap,1));
end;

if nargin < 4
    normalizeScalpMapIntensity = true; % we want to use inner products so they should be normnalized
end;

% initialize with nans
outputPolarity = nan(1, size(scalpMap,1));

% scalpMap = [];
% for i=1:length(STUDY.cluster(1).topoall)
%     scalpMap = cat(1, scalpMap, STUDY.cluster(1).topoall{i}(:)');
% end;

% remove NANs
sum1 = sum(scalpMap,1);
scalpMap(:, isnan(sum1)) = [];

% normalize scalpmap vector sizes by making it equal to one. 
if normalizeScalpMapIntensity
    for i=1:size(scalpMap,1)
        scalpMap(i,:) = scalpMap(i,:) / norm(scalpMap(i,:), 2);
    end;
end;

% calculate inner product between scalp maps
scalpMapInnerProduct = scalpMap * scalpMap';

% remove the diagonal
scalpMapInnerProduct = scalpMapInnerProduct - diag(diag(scalpMapInnerProduct));

% currently very large sets (with >3000 IC) produce a low-memoery error, so we bypass them for now
% and fall back to greedy method instead.

if strcmpi(method, 'convex') && size(scalpMapInnerProduct, 1) < 1000 
   try
    fprintf('Using convex optimization to find the best set of IC polarities...\n');
    n = size(scalpMapInnerProduct, 1);
    w = -scalpMapInnerProduct;

    cvx_begin sdp
        variable x(n,n) symmetric
        minimize ( trace(w*x) )
        diag(x) == 1;
        x >= 0;
    cvx_end
    
    [U, T] = schur(x);
    outputPolarity = -sign(U(:,end));
   catch err
       fprintf(['Falling back to greedy scalpmap normalization because of ' err.identifier ' in convex optimization.\n']);
       [outputPolarity scalpMapInnerProduct]= normalize_ic_polarity(scalpMap, 'greedy', polarityisFixed, normalizeScalpMapIntensity);
   end;
elseif strcmpi(method, 'greedy') % greedy method
            
    if ~any(polarityisFixed) % if there are no ICs with fixed polarities in the beginning
        
        % find the highest abs. correlated pair with non-fixed polarity
        surrogatescalpMapInnerProduct = abs(scalpMapInnerProduct);
        surrogatescalpMapInnerProduct(polarityisFixed, polarityisFixed) = -Inf;
        
        [dummy id1D] = max(surrogatescalpMapInnerProduct(:));
        [pairIc(1) pairIc(2)] = ind2sub(size(surrogatescalpMapInnerProduct), id1D);
        
        % first we chnage the polarity of each IC of this pair based on the sign of their mean scalp map
        for i=1:2
            pairIc1MeanPolarity(i) = mean(scalpMap(pairIc(i),:));
            outputPolarity(pairIc(i)) = sign(pairIc1MeanPolarity(i));
        end;
        
        % then we see if after this polarity chance they are still anti-correlated.
        % if so, we change the polarity of the IC with minimum abs. mean scalp map. (since this one has the
        % mean with least confidence between the two)
        if scalpMapInnerProduct(pairIc(1), pairIc(2)) * outputPolarity(pairIc(1)) * outputPolarity(pairIc(2)) < 0
            [dummy id] = min(abs(pairIc1MeanPolarity));
            outputPolarity(pairIc(id)) = -outputPolarity(pairIc(id));
        end;
        
        polarityisFixed(pairIc) = true; % fix the polarity of the first pair
    end;
    
    % now we go through ICs with non-fixed polarities and find the most similar (abs. correlated) IC
    % with any of the fixed polarity ICs. Then we set the polarity if this new IC accordingly and fix
    % it.
    for i=1:sum(~polarityisFixed)
        
        absCorrelationWithFixedPolarityScalpMap = abs(scalpMapInnerProduct(:, polarityisFixed));
        absCorrelationWithFixedPolarityScalpMap(polarityisFixed,:) = -Inf; % ignore fixed-polarity ICs
        
        % maximum over all fixed-polarity ICs
        maxAbsCorrelationWithFixedPolarityScalpMapOverFixedPolarity = max(absCorrelationWithFixedPolarityScalpMap,[],2);
        
        % find the non-polarity fixed ICs with max abs. correlation to the group of fixed-polarity ICs
        [dummy icId] = max(maxAbsCorrelationWithFixedPolarityScalpMapOverFixedPolarity);
        
        % find the fixed-polarity IC with which the newly found IC has the highest abs. correlation
        absCorrelation = abs(scalpMapInnerProduct(icId,:));
        absCorrelation(~polarityisFixed) = -Inf; % ignore non-polarity fixed ICs
        [dummy fixedPolarityIcId] = max(absCorrelation);
        
        
        outputPolarity(icId) = sign(scalpMapInnerProduct(icId, fixedPolarityIcId) * outputPolarity(fixedPolarityIcId));
        polarityisFixed(icId) = true;
    end;
else % monte carlo
	  fprintf('Using Monte Carlo method to find the best set of IC polarities...\n');
    [outputPolarity finalMinCost] = find_polarity_with_monte_carlo(scalpMapInnerProduct);
end;


finalCost = sum(vec(-scalpMapInnerProduct .* (outputPolarity * outputPolarity')));