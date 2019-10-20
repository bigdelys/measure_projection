function colors = get_distinct_colors(numberOfRequestdColors)
% when they are four colors, set the fourth one to yellow instead of magenta
if numberOfRequestdColors==4
    colors = hsv(numberOfRequestdColors);
    colors(4,:) = [1 1 0];
elseif numberOfRequestdColors<=5
    colors = hsv(numberOfRequestdColors);
elseif numberOfRequestdColors <=10 % first five with darker versions of themselves
    colors = zeros(10, 3);
    colors(1:5,:) = hsv(5);   
    hsvc = rgb2hsv(colors(1:5,:));
    hsvc(:,3) = 0.3;%0.75;
    colors(6:10,1:3) = hsv2rgb(hsvc);    
    
    colors((numberOfRequestdColors+1):end,:) = [];
elseif  numberOfRequestdColors <= 15% first five with darker versions of themselves and a much darker version.
    colors = zeros(10, 3);
    colors(1:5,:) = hsv(5);
    hsvc = rgb2hsv(colors(1:5,:));
    hsvc(:,3) = 0.3;
    colors(6:10,1:3) = hsv2rgb(hsvc);
    
    
    hsvc = rgb2hsv(colors(1:5,:));
    hsvc(:,3) = 0.7;
    colors(11:15,1:3) = hsv2rgb(hsvc);
    
    colors((numberOfRequestdColors+1):end,:) = [];    
else % hopeless
    colors = hsv(numberOfRequestdColors);
end;