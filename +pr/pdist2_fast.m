function distance = pdist2_fast(A,B)
% when pdist2 is not available this can replace it (and it is potentiallt faster on large inputs)

try
    distance = pdist2(A,B); % pdist2 if it can be found.
catch
    distance = sqrt( bsxfun(@plus,sum(A.^2,2),sum(B.^2,2)') - 2*(A*B') );
end;
