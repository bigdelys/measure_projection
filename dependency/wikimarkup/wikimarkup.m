% The wikimarkup class
% see the demofile for help.
%
% Usage: Instantiate the class and start adding tables, images, text etc.
%
% (1) CREATE AN OBJECT WITH YOUR DESIRED SYNTAX
% w = wikimarkup('html'); % also 'latex', 'mediawiki', 'xml'
% 
% (2) ADD YOUR IMAGES/TABLES/STRUCTURES/TEXT/SECTIONS
% w.addImage(filename, caption); % caption is optional
% w.addTable(matrix, rownames, colnames, caption); % args 2, 3, 4 are optional
% w.addStruct(structure);
% w.addText(text);
% w.addSection(name);
%
% (3) SAVE
% w.print(filename); if no filename is given, text is printed onto screen
%
% NOTE: Currently there is no XSLT for the XML file generated; However, you can still 
% possibly use it with tools that convert xml to latex, or html that are on the web.
%
% Run the demo.m to generate html/xml/latex and mediawiki formats for tables
% figures and regular text.
%
% Author:        Pavan Mallapragada 
% Organization:  Massachusetts Institute of Technology
% Contact:       <pavan_m@mit.edu>
% Created:       Jun 06, 2011 

classdef wikimarkup < handle & wikisyntax

    properties
	% The string that stores the text resulting from
	% adding tables and images
        wikistr;
    end
	methods
	function [T] = wikimarkup(type)
		if nargin < 1
			type = 'mediawiki';
		end
		T.type = type;
        	T.syntax = T.getSyntax(type);
	end
	end


	methods (Access = public)
        function addImage(T,fn,cap)
            if nargin < 2 || isempty(fn),
                warning('No filename provided. Using empty insertion\n');
                fn = ' ';
            end
	    T.addText(T.syntax.img_begin());
	    T.addText(T.syntax.img(fn));
	    if nargin > 2
	    	T.addText(T.syntax.caption(cap));
	    end
	    T.addText(T.syntax.img_end(''));
        end

        function addTable(T,mat, caption, colnames, rownames)
            %TODO: Ensure it is a two-dimensional matrix;
            [r,c] = size(mat);
	    T.addeol
	    T.addText(T.syntax.tab_begin(caption));
	    % dirty hack for latex.
	    if strcmp(T.type,'latex')
		T.addText('{|');
		if exist('rownames','var')
			T.addText('r|');
		end
	    	for i = 1:c
			T.addText('c|');
	    	end
		T.addText('}');
	    	T.addeol
	    end
            % Print header
	    if exist('colnames','var')
		% <row>
	    	T.addText(T.syntax.tab_rowbegin());
		if exist('rownames','var')
			% <rowhead>
	        	T.addText(T.syntax.tab_rowheadbegin());
			% <cell> <colhead> </colhead> </cell>
	    		T.addText(T.syntax.tab_cell(T.syntax.tab_colhead('')));
			% </rowhead>
	    		T.addText(T.syntax.tab_rowheadend());
	    		T.addText(T.syntax.tab_colsep(''));
		end
            	for i = 1:c-1,
			% <cell> <colhead> </colhead> </cell>
	    	    	T.addText(T.syntax.tab_cell(T.syntax.tab_colhead(colnames{i})));
			% column separator
	    	    	T.addText(T.syntax.tab_colsep(colnames{i}));
            	end
		% <cell> <colhead> </colhead> </cell>
	    	T.addText(T.syntax.tab_cell(T.syntax.tab_colhead(colnames{c})));
	        % </row>
	    	T.addText(T.syntax.tab_rowend(colnames{c}));
	    	%T.addeol;
	    	%T.addText(T.syntax.tab_rowheadend());
	    	T.addeol;
	    end
            if iscell(mat)
            	for i = 1:r,
		    if exist('rownames','var')
	    	         T.addRow({mat{i,:}}, rownames{i});
		    else
	    	         T.addRow({mat{i,:}});
		    end
	        end
	    else
            	for i = 1:r,
	    	    if exist('rownames','var')
	    	    	T.addRow(mat(i,:), rownames{i});
	    	    else
	    	    	T.addRow(mat(i,:));
	    	    end
            	end
	    end

	    T.addeol
	    T.addText(T.syntax.tab_end());
	    T.addeol
            
        end
	function addBulletList(T, cellstr,text)
		if nargin > 2
			T.addText(T.syntax.regulartext(text) );
		end
		T.addText(T.syntax.list_begin());
		T.addeol;
		for i = cellstr,
			T.addText(T.syntax.ul(cell2mat(i)));
			T.addeol;
		end
		T.addText(T.syntax.list_end());
		T.addeol;
	end
	function addSection(T,str)
		T.addText(T.syntax.section(str));
		T.addeol;
	end
 	function addNumberedList(T, cellstr, text)
		if nargin > 2
			T.addText(T.syntax.regulartext(text));
		end
		T.addText(T.syntax.enum_begin());
		T.addeol;
		for i = cellstr,
			T.addText(T.syntax.ol(cell2mat(i)));
			T.addeol;
		end
		T.addText(T.syntax.enum_end());
		T.addeol;
	end       
	function reset(T)
		T.wikistr = '';
	end
        function printWiki(T,fn)
	    str = [T.syntax.doc_begin() '__EOL__' T.wikistr '__EOL__' T.syntax.doc_end()];
	    lines = regexp(str,T.eol,'split');
            if nargin > 1
                fp = fopen(fn,'w');
	    else
		fp = 1;
	    end
	    for i = 1:numel(lines)
            	fprintf(fp,'%s\n',lines{i});
	    end
	    if nargin > 1
            	fclose(fp);
	    end
        end

	function addStruct(T, st, name)
		fields = fieldnames(st);
		for i = 1:numel(fields),
			text{i,1} = fields{i};

			if ~iscell(st.(fields{i})) && isstr(st.(fields{i})) || isscalar(st.(fields{i}))
				text{i,2} = st.(fields{i});
			else
				text{i,2} = 'Class not supported yet.';
			end
		end
		if nargin < 3
			name = 'Unnamed';
		end
		T.addTable(text,['Structure: ' name],{'Field','Value'});
	
	end
	function addText(T, str)
		if isnumeric(str)
			T.wikistr = [T.wikistr num2str(str)];
		elseif ischar(str)
			T.wikistr = [T.wikistr str];
		end
		
	end
    end % methods
    methods (Access = private)
    function [s] = eol(T)
	s = '__EOL__';
    end
	
    function addeol(T)
	T.addText(T.eol);
    end
    function addRow(T,vec, head)
	n = numel(vec);

	T.addText(T.syntax.tab_rowbegin());

	if exist('head','var')
        	T.addText(T.syntax.tab_rowheadbegin());
		T.addText(T.syntax.tab_rowhead(head));
		T.addText(T.syntax.tab_colsep(head));
    		T.addText(T.syntax.tab_rowheadend());
	end
        for j = 1:n-1,
		if iscell(vec)
			T.addText(T.syntax.tab_cell(num2str(vec{j}))); 
		else
			T.addText(T.syntax.tab_cell(num2str(vec(j)))); 
		end
		T.addText(T.syntax.tab_colsep());
        end
	if iscell(vec)
		T.addText(T.syntax.tab_cell(num2str(vec{n})));
	else
		T.addText(T.syntax.tab_cell(num2str(vec(n))));
	end
	T.addText(T.syntax.tab_rowend());
	T.addeol
	T.addText(T.syntax.tab_rowsep());
	T.addeol
    end
    function addCellRow(T,vec)
	n = numel(vec);

	T.addText(T.syntax.tab_rowbegin());
	if exist('head','var')
        	T.addText(T.syntax.tab_rowheadbegin());
		T.addText(T.syntax.tab_rowhead(head));
		T.addText(T.syntax.tab_colsep(head));
    		T.addText(T.syntax.tab_rowheadend());
	end
        for j = 1:n-1,
		T.addText(T.syntax.tab_cell(num2str(vec{j}))); 
		T.addText(T.syntax.tab_colsep());
        end
	T.addText(T.syntax.tab_cell(num2str(vec{n})));
	T.addText(T.syntax.tab_rowend());
	T.addeol
	T.addText(T.syntax.tab_rowsep());
	T.addeol
    end
    end
    
end %classdef
