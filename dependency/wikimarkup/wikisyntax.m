% The wikisyntax class. Helper class for wikimarkup; 
% Modify to suit your own syntactic needs, if you don't like what is already there.
%
% Run the demo.m to generate html/xml/latex and mediawiki formats for tables
% figures and regular text.
%
% Author:        Pavan Mallapragada 
% Organization:  Massachusetts Institute of Technology
% Contact:       <pavan_m@mit.edu>
% Created:       Jun 06, 2011 

classdef wikisyntax < handle

	properties (Access = protected)
		type
		syntax
	end
	methods (Access = protected)
		function T = wikisyntax(type)
		end
	end

	methods (Access = protected)
	function syntax = getSyntax(T, type)
		switch type
			case {'mediawiki'}
				syntax = T.getMediaWikiSyntax();
			case {'latex'}
				syntax = T.getLatexSyntax();
			case {'html'}
				syntax = T.getHTMLSyntax();
			case {'xml'}
				syntax = T.getXMLSyntax();
				
			otherwise
				error('Unknown wikitype\n');
		end
	end
	end

	
	methods (Access = public)
		function syntax = getMediaWikiSyntax(T)
		    syntax.doc_begin    = @(s) [];
		    syntax.doc_end      = @(s) [];

		    syntax.img_begin    = @(s) [];
		    syntax.img          = @(s) ['[[Image:' s ']]__EOL__'];
		    syntax.img_end      = @(s) [''];
		    syntax.caption      = @(s) [s '__EOL__'];

		    syntax.tab_cell     = @(s) [s];
		    syntax.tab_rowbegin = @(s) ['|'];
		    syntax.tab_rowend   = @(s) ['__EOL__|-'];

		    syntax.tab_colbegin = @(s) [];
		    syntax.tab_colend   = @(s) [];

		    syntax.tab_rowsep   = @(s) [''];
		    syntax.tab_colsep   = @(s) ['__EOL__|'];

		    syntax.tab_colhead  = @(s) [s];
		    syntax.tab_rowhead  = @(s) [s '__EOL__'];

		    syntax.tab_begin    = @(s) ['{|border=1 cellpadding=2__EOL__'];
		    syntax.tab_end      = @(s) ['|}'];

		    syntax.ul           = @(s) ['* ' s ];
		    syntax.ol           = @(s) ['# ' s ];
		    syntax.section      = @(s) ['==' s '==' ];

		    syntax.tab_rowheadbegin = @(s) [''];
		    syntax.tab_rowheadend   = @(s) ['|-'];


		    syntax.list_begin    = @(s) ['__EOL__'];
		    syntax.list_end      = @(s) ['__EOL__'];

		    syntax.enum_begin    = @(s) ['__EOL__'];
		    syntax.enum_end      = @(s) ['__EOL__'];



		    syntax.regulartext      = @(s) [s];


		end
	end
	methods (Access = public)
		function syntax = getLatexSyntax(T)

		    syntax.doc_begin    = @(s) ['\documentclass{article} __EOL__ \usepackage{graphicx} __EOL__ \begin{document}'];
		    syntax.doc_end    = @(s)   ['\end{document}'];

		    syntax.img_begin    = @(s) ['\begin{figure}__EOL__\begin{center}__EOL__'];
		    syntax.img          = @(s) ['\includegraphics[width=0.8\columnwidth]{' s '}'];
		    syntax.img_end      = @(s) ['__EOL__\end{center}__EOL__\end{figure}'];

		    syntax.caption      = @(s) ['\caption{' s '}__EOL__'];

		    syntax.tab_cell     = @(s) s;
		    syntax.tab_rowbegin = @(s) ['\hline__EOL__'];
		    syntax.tab_rowend   = @(s) ['\\'];
		    syntax.tab_rowsep   = @(s) [];
		    syntax.tab_rowhead  = @(s) [s];

		    syntax.tab_colbegin = @(s) [];
		    syntax.tab_colend   = @(s) [];
		    syntax.tab_colsep   = @(s) [' & '];
		    syntax.tab_colhead  = @(s) [s];

		    syntax.tab_rowheadbegin   = @(s) [];
		    syntax.tab_rowheadend   = @(s) [];

		    syntax.tab_begin    = @(s) ['__EOL__\begin{table}__EOL__\begin{center}__EOL__' syntax.caption(s) '\begin{tabular}'];
		    syntax.tab_end      = @(s) ['\hline__EOL__\end{tabular}__EOL__\end{center}__EOL__\end{table}'];

		    syntax.list_begin    = @(s) ['__EOL__\begin{itemize}'];
		    syntax.list_end      = @(s) ['\end{itemize}'];

		    syntax.enum_begin    = @(s) ['__EOL__\begin{enumerate}'];
		    syntax.enum_end      = @(s) ['\end{enumerate}'];

		    syntax.ul           = @(s) ['\item ' s ];
		    syntax.ol           = @(s) ['\item ' s ];

		    syntax.section      = @(s) ['\section{' s '}'];

		    syntax.regulartext      = @(s) [s];

		end
	end

 	methods (Access = public)
		function syntax = getHTMLSyntax(T)
		    syntax.doc_begin    = @(s) ['<html><body>'];
		    syntax.doc_end    = @(s) ['</html></body>'];

		    syntax.img_begin    = @(s) [''];
		    syntax.img          = @(s) ['<br><img src=' s '>'];
		    syntax.caption      = @(s) ['<br><caption>' s '</caption>__EOL__'];
		    syntax.img_end      = @(s) [s '</img><br><br>'];

		    syntax.tab_cell     = @(s) ['<td>' s '</td>'];
		    syntax.tab_rowbegin = @(s) ['<tr>__EOL__'];
		    syntax.tab_rowsep   = @(s) [' '];
		    syntax.tab_rowend   = @(s) ['__EOL__</tr>'];
		    syntax.tab_rowhead  = @(s) ['<td><b>'  s '</b></td>'];

		    syntax.tab_colbegin = @(s) [];
		    syntax.tab_colend   = @(s) [];
		    syntax.tab_colsep   = @(s) [];
		    syntax.tab_colhead  = @(s) ['<b>' s '</b>'];

		    syntax.tab_rowheadbegin   = @(s) ['<b>'];
		    syntax.tab_rowheadend   = @(s) ['</b>'];

		    syntax.tab_begin    = @(s) ['<table border=1 cellpadding=5>' syntax.caption(s)];
		    syntax.tab_end      = @(s) ['</table>'];

		    syntax.list_begin    = @(s) ['<ul>'];
		    syntax.list_end      = @(s) ['</ul>'];

		    syntax.enum_begin    = @(s) ['<ol>'];
		    syntax.enum_end      = @(s) ['</ol>'];

		    syntax.ul           = @(s) ['<li>' s '</li>'];
		    syntax.ol           = @(s) ['<li>' s '</li>'];

		    syntax.section      = @(s) ['<h2>' s '</h2>'];
		    syntax.regulartext      = @(s) ['<p>' s '</p>'];

		end
	end
 	methods (Access = public)
		function syntax = getXMLSyntax(T)
		    syntax.doc_begin    = @(s) ['<doc>'];
		    syntax.doc_end    = @(s) ['</doc>'];

		    syntax.img_begin    = @(s) ['<img>'];
		    syntax.img          = @(s) ['<filename>' s '</filename>'];
		    syntax.caption      = @(s) ['<caption>' s '</caption>__EOL__'];
		    syntax.img_end      = @(s) ['</img>'];

		    syntax.tab_cell     = @(s) ['<cell>' s '</cell>'];
		    syntax.tab_rowbegin = @(s) ['<row>'];
		    syntax.tab_rowsep   = @(s) [''];
		    syntax.tab_rowend   = @(s) ['</row>'];
		    syntax.tab_rowhead  = @(s) [s];

		    syntax.tab_colbegin = @(s) [''];
		    syntax.tab_colend   = @(s) [''];
		    syntax.tab_colsep   = @(s) [''];
		    syntax.tab_colhead  = @(s) ['<colhead>' s '</colhead>'];

		    syntax.tab_rowheadbegin   = @(s) ['<rowhead>'];
		    syntax.tab_rowheadend   = @(s) ['</rowhead>'];

		    syntax.tab_begin    = @(s) ['<table>' syntax.caption(s)];
		    syntax.tab_end      = @(s) ['</table>'];

		    syntax.list_begin    = @(s) ['<ul>'];
		    syntax.list_end      = @(s) ['</ul>'];

		    syntax.enum_begin    = @(s) ['<ol>'];
		    syntax.enum_end      = @(s) ['</ol>'];

		    syntax.ul           = @(s) ['<li>' s '</li>'];
		    syntax.ol           = @(s) ['<li>' s '</li>'];

		    syntax.section      = @(s) ['<section>' s '</section>'];
		    syntax.regulartext      = @(s) ['<text>' s '</text>'];

		end
	end

end
% fid = fopen('wiki.txt','w');
% fprintf(fid,'{|border=1 cellpadding=2\n');
% fprintf(fid,'! Class \n');
% for i = 1:size(m,2)
%     fprintf(fid,'!%s\n',plotopt.legend{i});
% end
% fprintf(fid,'|-\n');
% for j = 1:size(m,1)
%     fprintf(fid,'|%s \n',plotopt.class_names{j});
%     for i = 1:size(m,2)
%         fprintf(fid,' | %2.2f (%2.2f) \n', m(j,i), s(j,i));
%     end
%     fprintf(fid,'|-\n');
% end
% fprintf(fid,'|}');
% fclose(fid);
% end
