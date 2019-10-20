% Demo script for the wikimarkup Package
% Run the demo to generate html/xml/latex and mediawiki formats for tables
% figures and regular text.
%
% Author:        Pavan Mallapragada 
% Organization:  Massachusetts Institute of Technology
% Contact:       <pavan_m@mit.edu>
% Created:       Jun 06, 2011 


clear all;
clear;
p = wikimarkup('html');
A = rand(10,5);
format bank;
tableheads = {'col1','col2','col3','col4','col5'};
rownames  = {'row1','row2','row3','row4','row5','row6','row7','row8','row9','row10'};
imfile='image.pdf';
imfilejpg='image.jpg';
ezplot('sin(x)');
grid on;
box on;
print('-dpdf','./image.pdf');
print('-djpeg','./image.jpg');

s.a = 1;
s.number = 3;
s.string = 'asdf';
s.cell = {'asdf','asdf','b'};

p.addSection('Demo HTML output of the wikimarkup class.');
p.addStruct(s);
p.addBulletList(rownames,'This is a bulleted list of rownames from the table.');
p.addNumberedList(tableheads,'This is a numbered list of colnames from the table');
p.addImage(['./' imfilejpg]);
p.addImage(['./' imfilejpg],'This is a figure with a caption.');
p.addText('I can add some text here');
p.addTable(A,'With both colheads and rowheads',tableheads,rownames);
p.addTable(A+5,'Only with column headings',tableheads);
p.addTable(A+15,'With no row or column headings.');

 p.printWiki('./test.html');
 
 
 p = wikimarkup('latex');
 p.addSection('Demo Latex output of the wikimarkup class.');
 p.addStruct(s);
 p.addBulletList(rownames,'This is a bulleted list of rownames from the table.');
 p.addNumberedList(tableheads,'This is a numbered list of colnames from the table');
 p.addImage(imfile);
 p.addImage(imfile,'With this caption');
 p.addText('I can add some text here');
 p.addTable(A,'With colheads and rowheads',tableheads,rownames);
 p.addTable(A+5,'Only with colheads',tableheads);
 p.addTable(A+15,'With nothing');
 
 p.printWiki('./test.tex');
 
 
 
 
 p = wikimarkup('mediawiki');
 p.addSection('Demo Latex output of the wikimarkup class.');
 p.addStruct(s);
 p.addBulletList(rownames,'This is a bulleted list of rownames from the table.');
 p.addNumberedList(tableheads,'This is a numbered list of colnames from the table');
 p.addImage(imfilejpg);
 p.addImage(imfilejpg,'With this caption');
 p.addText('I can add some text here');
 p.addTable(A,'With colheads and rowheads',tableheads,rownames);
 p.addTable(A+5,'Only with colheads',tableheads);
 p.addTable(A+15,'With nothing');
 
 p.printWiki('./test.txt');
 
p = wikimarkup('xml');
p.addSection('Demo Latex output of the wikimarkup class.');
p.addStruct(s);
p.addBulletList(rownames,'This is a bulleted list of rownames from the table.');
p.addNumberedList(tableheads,'This is a numbered list of colnames from the table');
p.addImage(imfile);
p.addImage(imfile,'With this caption');
p.addText('I can add some text here');
p.addTable(A,'With colheads and rowheads',tableheads,rownames);
p.addTable(A+5,'Only with colheads',tableheads);
p.addTable(A+15,'With nothing');
p.printWiki('./test.xml');
