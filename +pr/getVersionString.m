function [versionString dateString]= getVersionString(capitalize)

if nargin < 1
    capitalize = true;
end;

try

    prSuperFolderPath = pr.getToolboxFolder;
    hgtagsFullPath = [prSuperFolderPath '.hgtags'];
    htagsFileText = fileread(hgtagsFullPath);
    
    if nargout > 1
        hgtagsFileInfo = dir(hgtagsFullPath);
        dateString = hgtagsFileInfo.date;
    end;
    
    % find the last space
    lastSpacePosition = 1;
    for lastSpacePosition=length(htagsFileText):-1:1
        if htagsFileText(lastSpacePosition) == ' '
            break;
        end;
    end;
    
    versionString = htagsFileText(lastSpacePosition+1:end-1);
    
    if capitalize
        versionString(1) = upper(versionString(1));
    end;
    
    versionString(find(versionString == '-')) =' ';
catch
    versionString = 'Version unknown';
	dateString = '01-January-2014';	
end;