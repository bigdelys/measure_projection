function [pnt, dhk] = icosahedron();

% ICOSAHEDRON42 creates a 1-fold refined icosahedron

% Copyright (C) 2003, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id: icosahedron42.m 952 2010-04-21 18:29:51Z roboos $

[pnt, dhk] = icosahedron;
[pnt, dhk] = refine(pnt, dhk);

pnt = pnt ./ repmat(sqrt(sum(pnt.^2,2)), 1,3);
