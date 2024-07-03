function rootgroup = loaddm3(filename);
%Script to load Gatan's DM3 files
%By Andrew Hurst
%   The University of Sheffield
%   April 2005
%Uses a sneaky trick or two(tm)
%based on code from GatanDM3.C -
%EMAN Gatan Library, (c) Baylor College of Medicine
%released under the terms of the GNU GPL.

%Gatan's dm3 format is a tree structure, stored as a stream.
%This function rebuilds the tree from the stream.
%Use lookupdm3tag() to get a tree node by name
%Use getdm3image() to read ImageData from a filename.
%Note it should be fairly easy to infer the reverse process and
% write .dm3 files from a tree.
%Figuring out a standard tree structure (if one exists) will be a
% matter of gratuitous use of matlab's debugger when loading an
% example .dm3 file.

    %some global definitions
    global ARRAY_TYPE;
        ARRAY_TYPE = 20;
    global STRING_TYPE;
        STRING_TYPE = 18;
    global STRUCT_TYPE;
        STRUCT_TYPE = 15;
    global GROUP_TAG;
        GROUP_TAG = 20;
    global DATA_TAG;
        DATA_TAG = 21;

    %endianism of tagdata, nontagdata
    global tagendian;
        tagendian = 'l';
    global nontagendian;
        nontagendian = 'b';

    %open file.
    file = fopen(filename, 'r');

    %initialise file reading
    [image_size, myerror] = initdm3(file);
    rootgroup = [];

    %if init succeeds, read root TagGroup (recurses)
    if(~myerror)
        rootgroup = readGroup(file, 'root');
    else
        error(myerror);
    end

    %close file
    fclose(file);

end

%DM3 loading functions begin ...
function [image_size, error] = initdm3(file)
    
    global tagendian;
    global nontagendian;

    image_ver = fread(file, 1, 'int32', nontagendian);
    image_size = fread(file, 1, 'int32', nontagendian);
    byte_order = fread(file, 1, 'int32', nontagendian);
    
    if byte_order == 0
        tagendian = 'b';
    elseif byte_order == 1
        tagendian = 'l';
    end
    
    if (image_ver ~= 3)
        error = ['Image version ' image_ver ' not supported'];
    else
        error = 0;
    end
end 

function byte = readByte(file)
    byte = fread(file, 1);
end

function word = readShort(file, endian)
    word = fread(file, 1, 'uint16', endian);
end

function dword = readLong(file, endian)
    dword = fread(file, 1, 'int32', endian);
end

function string = readStringData(file, count, bytesperchar, endian)
    if bytesperchar == 1
        string = fread(file, count, 'uchar');
    elseif bytesperchar == 2
        string = fread(file, count, 'uint16', endian);
    end
    
    string = char(string');
end

function array = readArrayData(file, types)
    global tagendian;
    global nontagendian;
    item_size = 0;
    
    for i = types
        [size, precision] = gatanDataTypeInfo(i);
        item_size = item_size + size;
    end    

    array_size = readLong(file, nontagendian);    
    bytes_to_read = item_size * array_size;
    
    %Doesn't yet handle any nested data structures.
    %Could simply build multi-dim array by recursion.
    if length(types) == 1
        [size, precision] = gatanDataTypeInfo(types);
        array = fread(file, array_size, precision, tagendian);
    else
        array = fread(file, bytes_to_read, 'uchar', tagendian);
    end
    
end

function s = readStructData(file, types)
    for i = types
        value = readNativeType(file, i);
        s(i) = value;
    end
end

function native = readNativeType(file, typeval)
    global tagendian;
    global nontagendian;
    [size, precision] = gatanDataTypeInfo(typeval);
    native = fread(file, 1, precision, tagendian);
end

function [name, child, numchildren] = readEntry(file, parentname, nchild)
    global GROUP_TAG;
    global DATA_TAG;
    global tagendian;
    global nontagendian;
    name = '';
        
    tag_type = readByte(file);
    name_len = readShort(file, nontagendian);
    %Note this method assumes anonymous children are adjacent
    if name_len
        %named node
        name = readStringData(file, name_len, 1);
        nchild = 0; %num anonymous children reset
    else
        %anonymous child
        name = [parentname ' #' int2str(nchild)];
        nchild = nchild + 1; %num anon children incremented
    end
    
    if tag_type == GROUP_TAG
        %Add node
        child = readGroup(file, name); % returns array
    elseif tag_type == DATA_TAG
        %Add leaf
        child = readData(file); % returns native type or an array
    end
    numchildren = nchild;

end

function node = readGroup(file, parentname)
    %return node to be added to parentnode
    global tagendian;
    global nontagendian;
    
    nchildren = 0;
    node = struct([]);

    issorted = readByte(file);
    isopen = readByte(file);
    ntags = readLong(file, nontagendian);

    %this node will have ntags children
    %nchildren keeps track of anonymous children
    for i = 1:ntags
         [name, child, nchildren] = readEntry(file, parentname, nchildren);
         node(i).name = name;
         node(i).child = child;
    end
    
end

function leaf = readData(file)
    global ARRAY_TYPE;
    global STRING_TYPE;
    global STRUCT_TYPE;
    global tagendian;
    global nontagendian;
    
    marker = readStringData(file, 4, 1, nontagendian);
    if strcmp(marker, '%%%%')
        %data marker ok - load 
        encoded_types_size = readLong(file, nontagendian);
        tag_type = readLong(file, nontagendian);
        
        switch tag_type
            case ARRAY_TYPE
                leaf = readArray(file);
            case STRING_TYPE
                str_len = readLong(file, tagendian);
                %strings in tag data are unicode - 2 bytes each
                leaf = readStringData(file, str_len, 2, tagendian)     
            case  STRUCT_TYPE
                leaf = readStruct(file);
            otherwise
                leaf = readNativeType(file, tag_type);
        end
        
    else
        error('Data marker not found - malformed tree');
    end
end

function array = readArray(file)
    types = readArrayTypes(file);
    array = readArrayData(file, types);
end

function struct = readStruct(file)
    types = readStructTypes(file);
    struct = readStructData(file, types);
end

function outtypes = readArrayTypes(file)
    global ARRAY_TYPE;
    global STRUCT_TYPE;
    global tagendian;
    global nontagendian;
    
    outtypes = [];

    array_type = readLong(file, nontagendian);
    
    switch array_type
        case ARRAY_TYPE
            outtypes = [outtypes readArrayTypes(file)];
        case STRUCT_TYPE
            outtypes = [outtypes readStructTypes(file)];
        otherwise
            outtypes = array_type;
    end
end

function outtypes = readStructTypes(file)
    global ARRAY_TYPE;
    global STRUCT_TYPE;
    global tagendian;
    global nontagendian;
    
    outtypes = [];
    
    namelength = readLong(file, nontagendian);
    nfields = readLong(file, nontagendian);
    
    for i = 1:nfields
        name = readLong(file, nontagendian);
        struct_type = readLong(file, nontagendian);
        outtypes = [outtypes struct_type];
    end
end

function [size,name] = gatanDataTypeInfo(type)
    switch(type)
        case {8, 9, 10}
            %BOOLEAN, CHAR, OCTET
            size = 1;
            name = 'uchar';
        case 2
            %SHORT
            size = 2;
            name = 'int16';
        case 4
            %USHORT
            size = 2;
            name = 'uint16';
        case 3
            %LONG
            size = 4;
            name = 'int32';
        case 5
            %ULONG
            size = 4;
            name = 'uint32';
        case 6
            %FLOAT
            size = 4;
            name = 'float32';
        case 7
            %DOUBLE
            size = 8;
            name = 'double';
        case 15
            %STRUCT
            size = 0;
            name = 'struct';
        case 18
            %STRING
            size = 0;
            name = 'string';
        case 20
            %ARRAY
            size = 0;
            name = 'array';
        otherwise
            size = 0;
            name = 'unknown type';
    end
end

%From GatanDM3.h
%
%     class TagEntry {
%     public:
% 	  enum EntryType {
% 	    GROUP_TAG = 20,
% 	    DATA_TAG = 21 };};
%
%
%     class TagData {
%     public:
%	  enum Type {
%	    SHORT   = 2,
%	    LONG    = 3,
%	    USHORT  = 4,
%	    ULONG   = 5,
%	    FLOAT   = 6,
%	    DOUBLE  = 7,
%	    BOOLEAN = 8,
%	    CHAR    = 9,
%	    OCTET   = 10,
%	    STRUCT  = 15,
%	    STRING  = 18,
%	    ARRAY   = 20 }; };

%     class DataType {
%     public:
%     enum Type {
% 	    NULL_DATA,
% 	    SIGNED_INT16_DATA,
% 	    REAL4_DATA,
% 	    COMPLEX8_DATA,
% 	    OBSELETE_DATA,
% 	    PACKED_DATA,
% 	    UNSIGNED_INT8_DATA,
% 	    SIGNED_INT32_DATA,
% 	    RGB_DATA,
% 	    SIGNED_INT8_DATA,
% 	    UNSIGNED_INT16_DATA,
% 	    UNSIGNED_INT32_DATA,
% 	    REAL8_DATA,
% 	    COMPLEX16_DATA,
% 	    BINARY_DATA,
% 	    RGB_UINT8_0_DATA,
% 	    RGB_UINT8_1_DATA,
% 	    RGB_UINT16_DATA,
% 	    RGB_FLOAT32_DATA,
% 	    RGB_FLOAT64_DATA,
% 	    RGBA_UINT8_0_DATA,
% 	    RGBA_UINT8_1_DATA,
% 	    RGBA_UINT8_2_DATA,
% 	    RGBA_UINT8_3_DATA,
% 	    RGBA_UINT16_DATA,
% 	    RGBA_FLOAT32_DATA,
% 	    RGBA_FLOAT64_DATA,
% 	    POINT2_SINT16_0_DATA,
% 	    POINT2_SINT16_1_DATA,
% 	    POINT2_SINT32_0_DATA,
% 	    POINT2_FLOAT32_0_DATA,
% 	    RECT_SINT16_1_DATA,
% 	    RECT_SINT32_1_DATA,
% 	    RECT_FLOAT32_1_DATA,
% 	    RECT_FLOAT32_0_DATA,
% 	    SIGNED_INT64_DATA,
% 	    UNSIGNED_INT64_DATA,
% 	    LAST_DATA }; };