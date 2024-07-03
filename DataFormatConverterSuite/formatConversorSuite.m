%LAST UPDATE: 20/01/2022
function varargout = formatConversorSuite(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @formatConversorSuite_OpeningFcn, ...
                   'gui_OutputFcn',  @formatConversorSuite_OutputFcn, ...
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

% --- Executes just before formatConversorSuite is made visible.
function formatConversorSuite_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = formatConversorSuite_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% --- Executes on button press in DM3stackToUint16Files.
function DM3stackToUint16Files_Callback(hObject, eventdata, handles)
test = get(handles.checkBox_generalName,'Value');
if test == 0
    generalName = '';
else
    outputDlg=inputdlg('Write the general name for frames:', '', 1, {'Something'});
    if isempty(outputDlg) == 0
        generalName = strcat(outputDlg{1},'_');
    else
        generalName = '';
    end
end
DM3Stack2uint16Tiff(generalName);

% --- Executes on button press in DM3framesToUint16Files.
function DM3framesToUint16Files_Callback(hObject, eventdata, handles)
test = get(handles.checkBox_generalName,'Value');
if test == 0
    generalName = '';
else
    outputDlg=inputdlg('Write the general name for frames:', '', 1, {'Something'});
    if isempty(outputDlg) == 0
        generalName = strcat(outputDlg{1},'_');
    else
        generalName = '';
    end
end
DM3Frames2uint16TIFF(generalName);

% --- Executes on button press in MRCfileToUint16Files.
function MRCfileToUint16Files_Callback(hObject, eventdata, handles)
test = get(handles.checkBox_generalName,'Value');
if test == 0
    generalName = '';
else
    outputDlg=inputdlg('Write the general name for frames:', '', 1, {'Something'});
    if isempty(outputDlg) == 0
        generalName = strcat(outputDlg{1},'_');
    else
        generalName = '';
    end
end
MRCFile2uint16frames(generalName);

% --- Executes on button press in MIBframesToUint16Files.
function MIBframesToUint16Files_Callback(hObject, eventdata, handles)
MIBframes2TifFrames();

% --- Executes on button press in dm3stackToMRCfile.
function dm3stackToMRCfile_Callback(hObject, eventdata, handles)
DM3Stack2MRCfile();

% --- Executes on button press in DM3framesToMRCfile.
function DM3framesToMRCfile_Callback(hObject, eventdata, handles)
DM3Frames2MRCfile_v2();

% --- Executes on button press in tifFramesToMRCfile.
function tifFramesToMRCfile_Callback(hObject, eventdata, handles)
TIFFrames2MRCFile();

% --- Executes on button press in cbfFramesToMRCfile.
function cbfFramesToMRCfile_Callback(hObject, eventdata, handles)
CBFFrames2MRCfile();

% --- Executes on button press in filterHKLYasar.
function filterHKLYasar_Callback(hObject, eventdata, handles)
hkl_filter_YasarVersion();

% --- Executes on button press in generatePETSfile.
function generatePETSfile_Callback(hObject, eventdata, handles)
PETSfileGenerator();

% --- Executes on button press in checkBox_generalName.
function checkBox_generalName_Callback(hObject, eventdata, handles)
