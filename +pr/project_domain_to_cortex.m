function cortexPointDomainDenisty = project_domain_to_cortex(domainLocation, cortexVertices, headGridSpacing, domainDipoleDensity, csf)

% if dipole denisty is not provided, assume uniform density.
if nargin < 4
    domainDipoleDensity = ones(1, size(domainLocation, 1));
end;

%domainDipoleDensity = domainDipoleDensity / sum(domainDipoleDensity);
domainDipoleDensity = domainDipoleDensity / max(domainDipoleDensity); % make maximum value to be one

if nargin < 5 % read CSF locations if not provided (could be provided in a for-loop to save time)
    csf = load('standard_BEM_vol.mat'); % located in the measure projection toolbox folder
end;

csfVertices = csf.vol.bnd(3).pnt;

distanceFromDomainLocationsToAllCSFLocations = pr.pdist2_fast(domainLocation, csfVertices);

cortexPointDomainDenisty = zeros(size(cortexVertices, 1), 1);


for i=1:size(domainLocation, 1)
[distanceToCSF, id] = min(distanceFromDomainLocationsToAllCSFLocations(i,:));

closestCsfPointToDomainLocation = csf.vol.bnd(3).pnt(id,:);

vectorFromDomaiinLocationToClosestCsfPoint = closestCsfPointToDomainLocation - domainLocation(i,:);
vectorFromFsfPointsToDomainLocation = cortexVertices - repmat(domainLocation(i,:), [size(cortexVertices, 1) 1]);

distanceFromCortexPointToDomainLocation = sum(vectorFromFsfPointsToDomainLocation .^2, 2) .^0.5;
fsfPointOnTheFrontSide = distanceFromCortexPointToDomainLocation < headGridSpacing * 3;

vectorFromFsfPointsToTheCsfPoint = cortexVertices - repmat(closestCsfPointToDomainLocation, [size(cortexVertices, 1) 1]);
outerProduct = outprod(closestCsfPointToDomainLocation', vectorFromFsfPointsToTheCsfPoint')';
distanceFromCortextPointToLineFromDomainToCsf = (sum(outerProduct .^ 2, 2).^0.5) ./ (sum(vectorFromDomaiinLocationToClosestCsfPoint .^ 2).^0.5);

cortexIsCloseToDomainLocationProjection = fsfPointOnTheFrontSide & (distanceFromCortextPointToLineFromDomainToCsf < 70);

cortexPointDomainDenisty = cortexPointDomainDenisty + domainDipoleDensity(i) * double(cortexIsCloseToDomainLocationProjection);
end;
