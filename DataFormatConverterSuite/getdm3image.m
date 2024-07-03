function [image, x, y] = getdm3image(filename, index)
    %Use this function to load an image from a Gatan dm3 file
    %Images are stored, zero-indexed in the ImageList.
    %Our 2010F's Digital Micrograph tends to store a thumbnail in
    % ImageList.ImageList #0, and the full scale image data in
    % ImageList.ImageList #1, hence assumption of index = 1 below.
    %Try dm3browser() if you have a lot of dm3 images you'd like to preview.
    
    %we want the ith image in the ImageList
    image = 0; x = 0; y = 0;
    
    %if filename and index are null, start a filechooser and assume index = 1
    if ~exist('filename', 'var') || ~ischar(filename)
        cwd = pwd();
        cd('..');
        [fn, pn] = uigetfile({'*.dm3'},'Select dm3 file');
        cd(cwd);
        filename = [pn fn];
        
        if ~ischar(filename)
            %we aborted (pressed Cancel) the filechooser, so..
            return;
        end
        
        disp(['Loading ' filename]);
        disp('Assuming ImageList index = 1...');
        index = 1;
    end
        
    if exist(filename, 'file');
        %if file exists, attempt to load tree
        rootgroup = loaddm3(filename);
    else
        %otherwise error
        error(['File ' filename ' does not exist.']);
    end
        
    %look up the appropriate parts of the tree
    imagedatagroup = lookupdm3tag(...
        ['ImageList.ImageList #' int2str(index) '.ImageData'], rootgroup);
    x = lookupdm3tag('Dimensions.Dimensions #0', imagedatagroup);
    y = lookupdm3tag('Dimensions.Dimensions #1', imagedatagroup);
    imagedata = lookupdm3tag('Data', imagedatagroup);

    %reshape the image data into an appropriate array
    image = reshape(imagedata, x, y)';
end