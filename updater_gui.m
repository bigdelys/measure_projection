function varargout = updater_gui(varargin)
% UPDATER_GUI MATLAB code for updater_gui.fig
%      UPDATER_GUI, by itself, creates a new UPDATER_GUI or raises the existing
%      singleton*.
%
%      H = UPDATER_GUI returns the handle to a new UPDATER_GUI or the handle to
%      the existing singleton*.
%
%      UPDATER_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UPDATER_GUI.M with the given input arguments.
%
%      UPDATER_GUI('Property','Value',...) creates a new UPDATER_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before updater_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to updater_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help updater_gui

% Last Modified by GUIDE v2.5 12-Jan-2012 15:37:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @updater_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @updater_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before updater_gui is made visible.
function updater_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to updater_gui (see VARARGIN)

% Choose default command line output for updater_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes updater_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = updater_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in LabelButton.
function LabelButton_Callback(hObject, eventdata, handles)
% hObject    handle to LabelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in installButton.
function installButton_Callback(hObject, eventdata, handles)
% hObject    handle to installButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(gcf);
