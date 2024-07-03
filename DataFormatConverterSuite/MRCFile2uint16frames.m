function MRCFile2uint16frames(generalName)
    [filename, pathname] = uigetfile({'*.MRC';'*.*'}, 'Pick an MRC-file');
    if isequal(filename,0) | isequal(pathname,0) 
        disp('No data loaded.'); return; 
    end;

    fname_mrc_in=[pathname filename];
    no_ext=fname_mrc_in(1, 1:(size(fname_mrc_in, 2)-4));

    fid_mrc_in = fopen(fname_mrc_in,'r');
    Header_in=ta_mrc_read_header(fid_mrc_in);

    newFolder = strcat(filename(1:end-4),'_TiffFrames');
    mkdir(pathname,newFolder)
    newDir = strcat(pathname,newFolder,'\');
    bar = waitbar(0,'Initializing ... ','Name','MRC File to Tif Files');
    for i=1:1:Header_in.MRC.nz
        slice = fread(fid_mrc_in,[Header_in.MRC.nx,Header_in.MRC.ny],'int16');
        numberDP = strcat(generalName,sprintf('%03d', [i]));
        imwrite(uint16(rot90(slice.*2)),strcat(newDir,numberDP,'.tif'),'compression','none');
        percentatge = uint8(100*i/Header_in.MRC.nz);
        waitbar(double(percentatge)/100,bar,sprintf('%d%%',percentatge));
    end
    close(bar)
    fclose(fid_mrc_in);
    msgbox({'MRC File converted to Tif Frames and stored into the following path: ' newDir},'MRC File -> Tif Frames')
end