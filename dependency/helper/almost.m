function y = almost(x, m, n)
if nargin < 3
    n = 0.1;
end;
    y = x;
    for i=1:length(x)
        if x(i) < m
            a = 2*n - m;
            b = 2 *m - 3*n;
            t = x(i)/m;
            y(i) = (a * t+b) *t *t + n;
        end;
    end;
end