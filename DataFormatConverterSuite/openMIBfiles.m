clear all
close all
try 
    id = fopen('test.mib');
    fseek(id,384,'bof');
    A = fread(id,[256,256],'uint32','b');
    A = rot90(A,-1);
    A = flipdim(A,2);
    fclose(id);
catch 
    disp('something went wrong')
end
imwrite(uint16(A),'test.tif','compression','none')