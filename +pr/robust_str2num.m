function number = robust_str2num(inputString)
% number = robust_str2num(inputString)
% convert strings that contains some non-number characters to numbers.

number = str2num(inputString);

if isempty(number)
    
    allowedCharacters = '1234567890-+.';
    purifiedString = [];
    for i=1:length(inputString)
        if ismember(inputString(i), allowedCharacters)
            purifiedString = [purifiedString inputString(i)];
        end;
    end;
    
    number = str2num(purifiedString);
end;
end