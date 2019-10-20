function z = outprod(x,y);
% x and y are 3 x N vectors
a = x(1,:); b = x(2,:);c=x(3,:);
ap = y(1,:); bp = y(2,:);cp=y(3,:);
z(1,:) = b .*cp-c .* bp;
z(2,:) = -(a.*cp-ap.*c);
z(3,:) = a.*bp-b.*ap;