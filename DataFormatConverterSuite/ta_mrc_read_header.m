function [Header] = ta_mrc_read_header(fid)
error(nargchk(0,2,nargin))
if nargin <1 
   error(['Cannot open: ' mrc ' file']); 
end;
if fid==-1
    error(['Cannot open: ' mrc ' file']); 
end;
Header.MRC.nx = fread(fid,[1],'int');        %integer: 4 bytes
Header.MRC.ny = fread(fid,[1],'int');        %integer: 4 bytes
Header.MRC.nz = fread(fid,[1],'int');        %integer: 4 bytes
Header.MRC.mode = fread(fid,[1],'int');      %integer: 4 bytes
Header.MRC.nxstart= fread(fid,[1],'int');    %integer: 4 bytes
Header.MRC.nystart= fread(fid,[1],'int');    %integer: 4 bytes
Header.MRC.nzstart= fread(fid,[1],'int');    %integer: 4 bytes
Header.MRC.mx= fread(fid,[1],'int');         %integer: 4 bytes
Header.MRC.my= fread(fid,[1],'int');         %integer: 4 bytes
Header.MRC.mz= fread(fid,[1],'int');         %integer: 4 bytes
Header.MRC.xlen= fread(fid,[1],'float');     %float: 4 bytes
Header.MRC.ylen= fread(fid,[1],'float');     %float: 4 bytes
Header.MRC.zlen= fread(fid,[1],'float');     %float: 4 bytes
Header.MRC.alpha= fread(fid,[1],'float');    %float: 4 bytes
Header.MRC.beta= fread(fid,[1],'float');     %float: 4 bytes
Header.MRC.gamma= fread(fid,[1],'float');    %float: 4 bytes
Header.MRC.mapc= fread(fid,[1],'int');       %integer: 4 bytes
Header.MRC.mapr= fread(fid,[1],'int');       %integer: 4 bytes
Header.MRC.maps= fread(fid,[1],'int');       %integer: 4 bytes
Header.MRC.amin= fread(fid,[1],'float');     %float: 4 bytes
Header.MRC.amax= fread(fid,[1],'float');     %float: 4 bytes
Header.MRC.amean= fread(fid,[1],'float');    %float: 4 bytes
Header.MRC.ispg= fread(fid,[1],'short');     %integer: 2 bytes
Header.MRC.nsymbt = fread(fid,[1],'short');  %integer: 2 bytes
Header.MRC.next = fread(fid,[1],'int');      %integer: 4 bytes
Header.MRC.creatid = fread(fid,[1],'short'); %integer: 2 bytes
Header.MRC.unused1 = fread(fid,[30]);        %not used: 30 bytes
Header.MRC.nint = fread(fid,[1],'short');    %integer: 2 bytes
Header.MRC.nreal = fread(fid,[1],'short');   %integer: 2 bytes
Header.MRC.unused2 = fread(fid,[28]);        %not used: 28 bytes
Header.MRC.idtype= fread(fid,[1],'short');   %integer: 2 bytes
Header.MRC.lens=fread(fid,[1],'short');      %integer: 2 bytes
Header.MRC.nd1=fread(fid,[1],'short');       %integer: 2 bytes
Header.MRC.nd2 = fread(fid,[1],'short');     %integer: 2 bytes
Header.MRC.vd1 = fread(fid,[1],'short');     %integer: 2 bytes
Header.MRC.vd2 = fread(fid,[1],'short');     %integer: 2 bytes
for i=1:6                               %24 bytes in total
    Header.MRC.tiltangles(i)=fread(fid,[1],'float');%float: 4 bytes
end
Header.MRC.xorg = fread(fid,[1],'float');    %float: 4 bytes
Header.MRC.yorg = fread(fid,[1],'float');    %float: 4 bytes
Header.MRC.zorg = fread(fid,[1],'float');    %float: 4 bytes
Header.MRC.cmap = fread(fid,[4],'char');     %Character: 4 bytes
Header.MRC.stamp = fread(fid,[4],'char');    %Character: 4 bytes
Header.MRC.rms=fread(fid,[1],'float');       %float: 4 bytes
Header.MRC.nlabl = fread(fid,[1],'int');     %integer: 4 bytes
Header.MRC.labl = fread(fid,[800],'char');   %Character: 800 bytes
if Header.MRC.nz>1
    Data_read=zeros(Header.MRC.nx,Header.MRC.ny,1);
else
    Data_read=zeros(Header.MRC.nx,Header.MRC.ny,1);
end
k=Header.MRC.nreal*4-52;
if Header.MRC.next>0
    for i=1:Header.MRC.nz
        Header.Extended.a_tilt(i)= fread(fid,[1],'float');%float: 4 bytes
        Header.Extended.b_tilt(i)= fread(fid,[1],'float');%float: 4 bytes
        Header.Extended.x_stage(i)= fread(fid,[1],'float');%float: 4 bytes
        Header.Extended.y_stage(i)=fread(fid,[1],'float');%float: 4 bytes
        Header.Extended.z_stage(i)=fread(fid,[1],'float');%float: 4 bytes
        Header.Extended.x_shift(i)=fread(fid,[1],'float');%float: 4 bytes
        Header.Extended.y_shift(i)=fread(fid,[1],'float');%float: 4 bytes
        Header.Extended.defocus(i)=fread(fid,[1],'float');%float: 4 bytes
        Header.Extended.exp_time(i)=fread(fid,[1],'float');%float: 4 bytes
        Header.Extended.mean_int(i)=fread(fid,[1],'float');%float: 4 bytes
        Header.Extended.tiltaxis(i)=fread(fid,[1],'float');%float: 4 bytes
        Header.Extended.pixelsize(i)=fread(fid,[1],'float');%float: 4 bytes
        Header.Extended.magnification(i)=fread(fid,[1],'float'); %float: 4 bytes
        fread(fid,[k],'char');
        Header.Extended;
        
    end
end

if Header.MRC.next>0
    fseek(fid,0,'bof');
    Header.buff= fread(fid, (Header.MRC.nreal*4+1)*1024);        
    
    fseek(fid,1024,'bof');
    Header.Extended.buff= fread(fid,Header.MRC.nreal*4*1024);
    
    fseek(fid,(Header.MRC.nreal*4+1)*1024,'bof'); 
else 
    fseek(fid, 0, 'bof');
    Header.buff= fread(fid, 1024); 
    fseek(fid, 1024, 'bof');
end
