function MIBframes2TifFrames()
    [filename, pathname] = uigetfile({'*.mib'}, 'Select your MIB files','MultiSelect','On');
    if isequal(filename,0) | isequal(pathname,0) 
       disp('No data loaded.'); return; 
    end;
    
    lengthCell = size(filename);

    if (iscell(filename) == 1) 
        
        bar = waitbar(0,'Initializing ... ','Name','MIB Frames to Tif Files');
        for i =1:lengthCell(2)

            inputName = strcat(pathname,filename{i});
            id = fopen(inputName);
            fseek(id,384,'bof');
            A = fread(id,[256,256],'uint32','b');
            A = rot90(A,-1);
            A = flipdim(A,2);
            fclose(id);
            imwrite(uint16(A),strcat(inputName(1:end-4),'.tif'),'compression','none')
            percentatge = uint8(100*i/lengthCell(2));
            waitbar(double(percentatge)/100,bar,sprintf('%d%%',percentatge)); 
        end    
        close(bar)
        
    else

        inputName = strcat(pathname,filename);
        id = fopen(inputName);
        fseek(id,384,'bof');
        A = fread(id,[256,256],'uint32','b');
        A = rot90(A,-1);
        A = flipdim(A,2);
        fclose(id);
        imwrite(uint16(A),strcat(inputName(1:end-4),'.tif'),'compression','none')

    end    

    msgbox({'MIB Frames converted to Tif Frames and stored into the same place as the MIB Frames.'},'MIB Frames -> Tif Frames')
end