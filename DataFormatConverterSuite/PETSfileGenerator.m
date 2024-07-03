function varargout = PETSfileGenerator(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PETSfileGenerator_OpeningFcn, ...
                   'gui_OutputFcn',  @PETSfileGenerator_OutputFcn, ...
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
function PETSfileGenerator_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);

function varargout = PETSfileGenerator_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function noise1_Callback(hObject, eventdata, handles)
function noise1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function noise2_Callback(hObject, eventdata, handles)
function noise2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function bckg_Callback(hObject, eventdata, handles)
function bckg_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lam_Callback(hObject, eventdata, handles)
function lam_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function apixel_Callback(hObject, eventdata, handles)
function apixel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function maxResPS_Callback(hObject, eventdata, handles)
function maxResPS_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function precAng_Callback(hObject, eventdata, handles)
function precAng_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function omega_Callback(hObject, eventdata, handles)
function omega_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function refsize_Callback(hObject, eventdata, handles)
function refsize_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Iovers_Callback(hObject, eventdata, handles)
function Iovers_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function bin_Callback(hObject, eventdata, handles)
function bin_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function folderName_Callback(hObject, eventdata, handles)
function folderName_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function rootName_Callback(hObject, eventdata, handles)
function rootName_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function iniAngle_Callback(hObject, eventdata, handles)
function iniAngle_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function tiltStep_Callback(hObject, eventdata, handles)
function tiltStep_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function numFrames_Callback(hObject, eventdata, handles)
function numFrames_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minResPS_Callback(hObject, eventdata, handles)
function minResPS_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function maxResInt_Callback(hObject, eventdata, handles)
function maxResInt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function minResInt_Callback(hObject, eventdata, handles)
function minResInt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function np2_Callback(hObject, eventdata, handles)
function np2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function np1_Callback(hObject, eventdata, handles)
function np1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function generate_Callback(hObject, eventdata, handles)

[fileName,pathName,index] = uiputfile('*.pts','Select the directory to save the PETS file'); 

if (index == true)

    fileIDinfo = fopen(strcat(pathName,fileName),'w');
    fprintf(fileIDinfo,'%s\t%s\t%s\n','noiseparameters',get(handles.np1,'String'),get(handles.np2,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','background', get(handles.bckg,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','lambda',get(handles.lam,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','Aperpixel',get(handles.apixel,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','dstarminps',get(handles.minResPS,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','dstarmaxps',get(handles.maxResPS,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','dstarmin',get(handles.minResInt,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','dstarmax',get(handles.maxResInt,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','omega',get(handles.omega,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','phi',get(handles.precAng,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','center','auto');
    fprintf(fileIDinfo,'%s\t%s\n','pixelsize','0.005');
    fprintf(fileIDinfo,'%s\t%s\n','reflectionsize',get(handles.refsize,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','I/sigma',get(handles.Iovers,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','bin',get(handles.bin,'String'));
    fprintf(fileIDinfo,'%s\t%s\n','beamstop','no');
    fprintf(fileIDinfo,'%s\n','imagelist');
    folderName = get(handles.folderName,'String');
    rootName = get(handles.rootName,'String');
    iniAngle = str2num(get(handles.iniAngle,'String'));
    tiltStep = str2num(get(handles.tiltStep,'String'));
    for(i = 1:str2double(get(handles.numFrames,'String')))
        numberDP = sprintf('%03d', [i]);
        fprintf(fileIDinfo,'%s\t%.2f\t%s\n',strcat(folderName,'\',rootName,numberDP,'.tif'),(iniAngle + ((i-1)*tiltStep)),'0.00');
    end    
    fprintf(fileIDinfo,'%s','endimagelist');

    fclose(fileIDinfo);

end