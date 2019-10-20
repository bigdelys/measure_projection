function C = correlation_of_columns(A, B)
% faster (than corr and crrcoef) calculation of correlation between columns of A and B.
An=bsxfun(@minus,A,mean(A,1)); %%% zero-mean
Bn=bsxfun(@minus,B,mean(B,1)); %%% zero-mean
An=bsxfun(@times,An,1./sqrt(sum(An.^2,1))); %% L2-normalization
Bn=bsxfun(@times,Bn,1./sqrt(sum(Bn.^2,1))); %% L2-normalization
C=sum(An.*Bn,1); %% correlation