function kl = kl_divergence(p,q, dim)
%compute the K-L divergence of two distributions
%KL(p||q) = \sum p_i * log(p_i/q_i)
%
%function kl = kl_hist(p,q, dim)
%	p, q can be multi-dimentional matrix, dim tells the direction of histogram.
%	e.g., p, q are two 3-D matrix, and dim=3, mean each (x,y,:) is a histogram
%	and kl is thus a 2-D matrix

kl = sum(p.*log((p+eps)./(q+eps)),dim);


