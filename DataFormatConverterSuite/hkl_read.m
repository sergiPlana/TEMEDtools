disp('************************************************************')
disp('hkl read');
disp('************************************************************')
clear all;

% file in
status = evalin('base','exist(''fname1'')');
if status == 0
[filename, pathname1] = uigetfile({'*.hkl';'*.*'}, 'Pick a hkl-file','L:\Yasar\');
if isequal(filename,0) || isequal(pathname1,0) 
    disp('No data loaded.'); return; 
end;
fname1 =[pathname1 filename];
end;

fid = fopen(fname1,'r');
    formatSpec = '%4s %4s %4s %8s %8s';
    C = textscan(fid,formatSpec,'whitespace','');
fclose(fid);

% cell to double
hkl = str2double([C{:}]);

% rows of matrix
rows_hkl = size(hkl,1);

% delete zeros
temp = [1:5];
rows_temp = 1;
hkl_del = [1:5];
rows_hkl_del = 1;

ind = 1;
while ind <= rows_hkl
[r,c,v] = find(hkl(ind,4)==0);
    if isempty(v) == 0
        hkl_del(rows_hkl_del,:) = [hkl(ind,:)];
        rows_hkl_del = rows_hkl_del + 1;
    else
        temp(rows_temp,:) = [hkl(ind,:)];
        rows_temp = rows_temp + 1;
    end;
    ind = ind + 1;
end


% file out
status = evalin('base','exist(''fname2'')');
if status == 0
[filename, pathname2] = uiputfile({'*.hkl';'*.*'}, 'Put a max hkl-file', pathname1);
if isequal(filename,0) || isequal(pathname2,0) 
    disp('No data wrote.'); return; 
end;
fname2 =[pathname2 filename];
end;

fid = fopen(fname2,'wt');
    formatSpec = '%4.0f%4.0f%4.0f%8.2f%8.2f\n';
    fprintf(fid,formatSpec,temp');
fclose(fid);

disp(' ');
disp('done!');
disp('File is written');
disp('---------------');
