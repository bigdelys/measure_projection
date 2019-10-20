function prSuperFolderPath = getToolboxFolder

fullPath = which('pr.dipole');
prSuperFolderPath = fullPath(1:end - length('+pr/dipole.m'));