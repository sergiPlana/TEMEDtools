function DM3Frames2uint16TIFF(generalName)
    [filename, pathname] = uigetfile({'*.dm3';'*.*'}, 'Select your DM3 Frames','MultiSelect','On');
    if isequal(filename,0) | isequal(pathname,0) 
        disp('No data loaded.'); return; 
    end
    
    mkdir(pathname,'TiffFrames')
    newDir = strcat(pathname,'TiffFrames\');
    bar = waitbar(0,'Initializing ... ','Name','DM3 Frames to Tif Files');
    for i=1:length(filename)
    
        rootName = char(filename(i));
        name = strcat(pathname,rootName); 
        slice = getdm3image(name ,1);
        numberDP = strcat(generalName,sprintf('%03d', [i]));
        imwrite(uint16(slice),strcat(newDir,numberDP,'.tif'),'compression','none')
        percentatge = uint8(100*i/length(filename));
        waitbar(double(percentatge)/100,bar,sprintf('%d%%',percentatge)); 
    
    end
    close(bar)
    msgbox({'DM3 Frames converted to Tif Frames and stored into the following path: ' newDir},'DM3 Frames -> Tif Frames')
end