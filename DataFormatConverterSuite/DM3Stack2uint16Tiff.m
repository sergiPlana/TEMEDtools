function DM3Stack2uint16Tiff(generalName)
    [filename, pathname] = uigetfile({'*.dm3';'*.*'}, 'Select your DM3 Stack File');
    if isequal(filename,0) | isequal(pathname,0) 
        disp('No data loaded.'); return; 
    end
    
    bar = waitbar(0,'Initializing ... ','Name','DM3 Stack to Tif Files');
    fname_in=strcat(pathname,filename);
    slice = getdm3stack(fname_in ,1);
    [x, y, z] = size(slice);

    newFolder = strcat(filename(1:end-4),'_TiffFrames');
    mkdir(pathname,newFolder)
    newDir = strcat(pathname,newFolder,'\');
    for i=1:z

        frame = rot90(fliplr(slice(:,:,i)) , 1);
        numberDP = strcat(generalName,sprintf('%03d', [i]));
        imwrite(uint16(frame),strcat(newDir,numberDP,'.tif'),'compression','none')
        percentatge = uint8(100*i/z);
        waitbar(double(percentatge)/100,bar,sprintf('%d%%',percentatge));

    end
    close(bar)
    msgbox({'DM3 stack converted to Tif Frames and stored into the following path: ' newDir},'DM3 Stack -> Tif Frames')
end