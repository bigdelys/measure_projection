function estimatedMutualInformation = estimate_mutual_information_from_correlation(correlationSimilaity)
%        estimatedMutualInformation = estimate_mutual_information_from_correlation(correlationSimilaity)

% when two dipoles are associated with one IC, their correlation becomes exactly 1 and
% create numerical issues. That is why here we place it to a value slightly less than 1.
correlationSimilaity(correlationSimilaity == 1) = 0.98;

estimatedMutualInformation = (1/2) * log2( 1 ./ (1-correlationSimilaity .^2) ) .* sign(correlationSimilaity);

% remove NaNs on the diagonal, we cannot use minus (-) since Nan - Nan = Nan
estimatedMutualInformation(isnan(estimatedMutualInformation)) = 0;
% 
% for i=1:size(estimatedMutualInformation, 1)
%     estimatedMutualInformation(i,i) = 0;
% end;
