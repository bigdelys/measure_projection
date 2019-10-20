function [obj icIndexForEachDipole]= convert_dipole_structure_to_array(dipoles, obj)

counter = 1;
icIndexForEachDipole = [];
for i=1:size(dipoles,2)
    if ~isempty(dipoles(i).posxyz) % ignore empty dipoles
        obj.location(counter,:) = dipoles(i).posxyz(1,:);
        obj.direction(counter,:) = dipoles(i).momxyz(1,:);
        icIndexForEachDipole(counter) = i;
        counter = counter + 1;
        
        
        % for ICs with two dipoles
        if size(dipoles(i).posxyz,1) == 2 && ~all(dipoles(i).posxyz(2,:) < eps)
            obj.location(counter,:) = dipoles(i).posxyz(2,:);
            obj.direction(counter,:) = dipoles(i).momxyz(2,:);
            icIndexForEachDipole(counter) = i;
            counter = counter + 1;
        end;
    end;
end;

end