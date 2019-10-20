%SWEB		start a WEB session with user options
%
%		SWEB starts a WEB session and optionally sets
%		-  the url
%		-  the browser position
%		-  the browser type
%		the optional output returns a handle to the browser's
%		   content and frame, which may be used to
%		   further fine-tune their respective properties
%
%		see also: web, urlread, urlwrite, methods, get, set
%
%SYNTAX
%-------------------------------------------------------------------------------
%		P = SWEB(POS,URL,WOPT);
%
%INPUT		in any order(!)
%-------------------------------------------------------------------------------
%  POS	:	browser position		[double vector: 1x2 or 1x4]
%		   [xoff,yoff]
%		   [xoff,yoff,width,height]
%  URL	:	valid url or ''			[char string]
% WOPT	:	valid WEB option(s)		[cells]
%
%OUTPUT
%-------------------------------------------------------------------------------
%    P	:	output structure with fields
%		.isb	:	true if P.f is a native ML browser
%		.u	:	URL
%		.p	:	current browser position
%		.b	:	handle  to browser content (see NOTE)
%		.f	:	handle  to browser frame   (see NOTE)
%
%NOTE
%-------------------------------------------------------------------------------
%		- if multiple inputs of the same type are entered,
%		     the last respective argument is used
%		- see
%				methods(P.X);
%				get(P.X);
%				set(P.X);
%		     for options to fine-tune the respective components
%				P.b or P.f
%		     programmatically
%
%EXAMPLE
%-------------------------------------------------------------------------------
%		opt={'-new','-notoolbar'};
%		p=sweb('www.mathworks.com',opt,[16,16,700,600]);
%		p.f.setAlwaysOnTop(true);
% %		- use  browser -
% %		- hide browser -
% %		p.f.hide;

% created:
%	us	06-Dec-2009 us@neurol.unizh.ch
% modified:
%	us	07-Dec-2009 20:20:22
%
% localid:	us@USZ|ws-nos-36362|x86|Windows XP|7.9.0.529.R2009b

%-------------------------------------------------------------------------------
function	p=sweb(varargin)

		isb=false;
		arg=[];
		pos=[];
		url='';

	if	nargout
		p=[];
	end

	if	nargin < 1
		help(mfilename);
		return;
	end

% assign input
		isp=find(cellfun(@isnumeric,varargin),1,'last');
		isu=find(cellfun(@ischar,varargin),1,'last');
		iso=find(cellfun(@iscell,varargin),1,'last');
	if	~isempty(isp)
		pos=varargin{isp};
	end
	if	~isempty(isu)
		url=varargin{isu};
	end
	if	~isempty(iso)
		arg=varargin{iso};
	end

% start WEB session
	if	~isempty(arg)
	try
		[bh,bh]=web(url,arg{:});		%#ok
		isb=true;
	catch						%#ok
		bh=web(url,arg{:});
	end
	else
		[bh,bh]=web(url);			%#ok
		isb=true;
    end

    for i=1:1000
        pause(0.1);
        if bh.isValid
            break;
        end;
    end;
    
 	if	~bh.isValid
 		error(sprintf('SWEB> WEB browser is invalid\nSWEB> try option  {''-new''}'));	%#ok
 	end

% set browser window
	if	isb
		bf=bh.getRootPane.getParent;
	if	~isempty(pos)				&&...
		isnumeric(pos)
	if	numel(pos) >= 2
		bf.setLocation(pos(1),pos(2));
	if	numel(pos) >= 4
		bf.setSize(pos(3),pos(4));
	end
	end
	end

% - get current position
		npos=	[
			get(bf.getLocationOnScreen,'location'),...
			get(bf.getSize,'width'),...
			get(bf.getSize,'height')
			];
	else
		npos=nan(1,4);
		bf=[];
	end

% assign output structure
	if	nargout
		p.ver='07-Dec-2009 20:20:22';
		p.MLver=version;
		p.isb=isb;
		p.u=url;
		p.p=npos;
		p.b=bh;
		p.f=bf;
	end
end
%-------------------------------------------------------------------------------