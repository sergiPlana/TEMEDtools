function TIFFrames2MRCFile()
    [filename, pathname] = uigetfile({'*.tif';'*.tiff';'*.*'}, 'Select your Tif Diffraction Patterns','MultiSelect','On');
    if isequal(filename,0) | isequal(pathname,0) 
       return; 
    end;

    fname_in=strcat(pathname,filename{1});
    info=imfinfo(fname_in);

    dialog=inputdlg('Write the MRC Name:', 'TIFF2MRC', 1, {'MRCname'});
    gen_name=[pathname char(dialog)];


    disp('*********************************************************************')
    disp('converting into... ');

    prefix='.tif';

    mrc_name=[gen_name, '.mrc'];
    disp(mrc_name);
    disp('*********************************************************************')

    fid_mrc=fopen(mrc_name, 'w');
    Basic.numfloats=38;
    Basic.next=Basic.numfloats*4*1024;
    buff(1:Basic.next+1024)=0;
    fwrite(fid_mrc, buff, 'char');
    status = fseek(fid_mrc, Basic.next+1024, 'bof');

    i=1;
    Basic.nz=0;
    
    bar = waitbar(0,'Initializing ... ','Name','Tif Frames to MRC File');
    for i=1:length(filename)

        name = strcat(pathname,char(filename(i)));
        info=imfinfo(name);
        fid = fopen(name, 'r');
        if size(info.StripOffsets, 1)>1
            data_start=info.StripOffsets(1, 1);
        else
            data_start=info.StripOffsets;
        end

        status = fseek(fid, data_start(1), 'bof');
        slice = imread(name);   
        % slice = fliplr(slice);

        fclose(fid);
        if isa(slice,'uint16') && max(max(slice)) > 32767
            s=int16((rot90(slice,3))./2);
        else
            s = int16((rot90(slice,3)));
        end
        
        fwrite(fid_mrc, s,'int16');
        Basic.nz=Basic.nz+1;
        percentage = uint8(100*i/length(filename));
        waitbar(double(percentage)/100,bar,sprintf('%d%%',percentage));
    end
    close(bar)
    status = fseek(fid_mrc, 0, 'bof');

    % MRC header definition: BASIC

    Basic.nx=info.Width;
    fwrite(fid_mrc, Basic.nx, 'int');   % integer 4-byte 
    Basic.ny=info.Height;
    fwrite(fid_mrc, Basic.ny, 'int');   % integer 4-byte 
    fwrite(fid_mrc, Basic.nz, 'int');   % integer 4-byte 
    Basic.mode=1;
    fwrite(fid_mrc, Basic.mode, 'int');   % integer 4-byte 
    Basic.nxstart=0;
    fwrite(fid_mrc, Basic.nxstart, 'int');   % integer 4-byte 
    Basic.nystart=0;
    fwrite(fid_mrc, Basic.nystart, 'int');   % integer 4-byte 
    Basic.nzstart=0;
    fwrite(fid_mrc, Basic.nzstart, 'int');   % integer 4-byte 
    Basic.mx=info.Width;
    fwrite(fid_mrc, Basic.mx, 'int');   % integer 4-byte 
    Basic.my=info.Height;
    fwrite(fid_mrc, Basic.my, 'int');   % integer 4-byte 
    Basic.mz=Basic.nz;
    fwrite(fid_mrc, Basic.mz, 'int');   % integer 4-byte 
    Basic.xlen=info.Width;
    fwrite(fid_mrc, Basic.xlen, 'float');   % float 4-byte 
    Basic.ylen=info.Height;
    fwrite(fid_mrc, Basic.ylen, 'float');   % float 4-byte 
    Basic.zlen=Basic.nz;
    fwrite(fid_mrc, Basic.zlen, 'float');   % float 4-byte 
    Basic.alpha=90;
    fwrite(fid_mrc, Basic.alpha, 'float');   % float 4-byte 
    Basic.beta=90;
    fwrite(fid_mrc, Basic.beta, 'float');   % float 4-byte 
    Basic.gamma=90;
    fwrite(fid_mrc, Basic.gamma, 'float');   % float 4-byte 
    Basic.mapc=1;
    fwrite(fid_mrc, Basic.mapc, 'int');   % integer 4-byte 
    Basic.mapr=2;
    fwrite(fid_mrc, Basic.mapr, 'int');   % integer 4-byte 
    Basic.maps=3;
    fwrite(fid_mrc, Basic.maps, 'int');   % integer 4-byte 
    Basic.amin=min(min(slice));
    fwrite(fid_mrc, Basic.amin, 'float');   % float 4-byte 
    Basic.amax=max(max(slice));
    fwrite(fid_mrc, Basic.amax, 'float');   % float 4-byte 
    Basic.amean=mean(mean(slice));
    fwrite(fid_mrc, Basic.amean, 'float');   % float 4-byte 
    Basic.ispg=0;
    fwrite(fid_mrc, Basic.ispg, 'short');   % integer 2-byte 
    Basic.nsymbt=0;
    fwrite(fid_mrc, Basic.nsymbt, 'short');   % integer 2-byte 
    fwrite(fid_mrc, Basic.next, 'int');   % integer 4-byte 
    Basic.dvid=69;
    fwrite(fid_mrc, Basic.dvid, 'short');   % integer 2-byte 
    Basic.extra(1:30)=0;
    fwrite(fid_mrc, Basic.extra, 'char');   % extra 30 bytes data (not used)
    Basic.numintegers=0;
    fwrite(fid_mrc, Basic.numintegers, 'short');   % integer 2-byte 
    fwrite(fid_mrc, Basic.numfloats, 'short');   % integer 2-byte 
    Basic.sub=0;
    fwrite(fid_mrc, Basic.sub, 'short');   % integer 2-byte 
    Basic.zfac=0;
    fwrite(fid_mrc, Basic.zfac, 'short');   % integer 2-byte 
    Basic.min2=0;
    fwrite(fid_mrc, Basic.min2, 'float');   % float 4-byte 
    Basic.max2=0;
    fwrite(fid_mrc, Basic.max2, 'float');   % float 4-byte 
    Basic.min3=0;
    fwrite(fid_mrc, Basic.min3, 'float');   % float 4-byte 
    Basic.max3=0;
    fwrite(fid_mrc, Basic.max3, 'float');   % float 4-byte 
    Basic.min4=0;
    fwrite(fid_mrc, Basic.min4, 'float');   % float 4-byte 
    Basic.max4=0;
    fwrite(fid_mrc, Basic.max4, 'float');   % float 4-byte 
    Basic.idtype=1205;
    fwrite(fid_mrc, Basic.idtype, 'short');   % integer 2-byte 
    Basic.lens=0;
    fwrite(fid_mrc, Basic.lens, 'short');   % integer 2-byte 
    Basic.nd1=0;
    fwrite(fid_mrc, Basic.nd1, 'short');   % integer 2-byte 
    Basic.nd2=0;
    fwrite(fid_mrc, Basic.nd2, 'short');   % integer 2-byte 
    Basic.vd1=0;
    fwrite(fid_mrc, Basic.vd1, 'short');   % integer 2-byte 
    Basic.vd2=0;
    fwrite(fid_mrc, Basic.vd2, 'short');   % integer 2-byte 
    Basic.tiltangles(1:9)=0;

    for i=1:9                               
        fwrite(fid_mrc, Basic.tiltangles(i), 'float');   %float 4-byte
    end

    Basic.zorg=0;
    fwrite(fid_mrc, Basic.zorg, 'float');   % float 4-byte 
    Basic.xorg=0;
    fwrite(fid_mrc, Basic.xorg, 'float');   % float 4-byte 
    Basic.yorg=0;
    fwrite(fid_mrc, Basic.yorg, 'float');   % float 4-byte 
    Basic.nlabl=1;
    fwrite(fid_mrc, Basic.nlabl, 'int');   % integer 4-byte 
    Basic.data='MRC file created by TIF2MRC packer /TG, Modified by SP, Mainz, June 2017';
    fwrite(fid_mrc, Basic.data, 'char');   % 10 text labels with 80 characters

    % ************* Extended ********************

    answer = inputdlg({'Staring tilt angle in deg. (NEGATIVE -> POSITIVE)', 'Tilt step'}, 'Tilt series INFO', 1, {'-60', '1'});
    Extended.a_tilt(1)=str2num(answer{1});
    tilt_step=str2num(answer{2});

    for i=1:Basic.nz
        Extended.a_tilt(i)=Extended.a_tilt(1)+(i-1)*tilt_step;
    end

    Extended.b_tilt=0;
    Extended.x=0;
    Extended.y=0;
    Extended.z=0;
    Extended.x_shift=0;  
    Extended.y_shift=0;  
    Extended.defocus=0;  
    Extended.exposure=0;  
    Extended.mean_intensity=Basic.amean; 
    Extended.tilt_axis=0;  
    answer = inputdlg({'Pixel size in 1/nm', 'Camera length in mm'}, 'Tilt series INFO', 1, {'0.025', '380'});
    Extended.pixel_size = 1e9*str2num(answer{1});
    Extended.magnification = str2num(answer{2});
    Extended.Microscope_type = 99;  
    Extended.Gun_type = 0;
    Extended.Lens_type=0;
    Extended.D_number_of_microscope=0;
    answer = inputdlg({'High tension (kV)', 'Diffraction lens value in %'}, 'Tilt series INFO', 1, {'300', '35'});
    Extended.High_tension=str2num(answer{1});
    Extended.Diffraction_lens_value_in_percent=str2num(answer{2});
    Extended.MTF=0;  
    Extended.Starting_Df=0; 
    Extended.Focus_step=0; 
    Extended.DAC_setting=0;  
    Extended.Spherical_aberration=0; 
    Extended.Semi_convergence=0; 
    Extended.Info_limit=0;  
    Extended.Number_of_images=Basic.nz;  
    for i=1:Basic.nz
        Extended.Image_number_in_series(i)=i;
    end
    Extended.Coma_3_X=0; 
    Extended.Coma_3_Y=0; 
    Extended.Astigmatism_2_X=0; 
    Extended.Astigmatism_2_Y=0; 
    Extended.Astigmatism_3_X=0; 
    Extended.Astigmatism_3_Y=0; 
    Extended.Camera_type_number=0;  
    Extended.Camera_position=0; 
    Extended.Spherical_Aberration_4=0; 
    Extended.Star_Aberration_4_X=0; 
    Extended.Star_Aberration_4_Y=0; 
    Extended.Astigmatism_4_X=0; 
    Extended.Astigmatism_4_Y=0; 
    Extended.Coma_5_X=0; 
    Extended.Coma_5_Y=0; 
    Extended.Three_Lobe_5_X=0; 
    Extended.Three_Lobe_5_Y=0; 
    Extended.Astigmatism_5_X=0; 
    Extended.Astigmatism_5_Y=0; 
    Extended.Spherical_Aberration_6=0; 
    Extended.Star_Aberration_6_X=0; 
    Extended.Star_Aberration_6_Y=0; 
    Extended.Rosette_Aberration_6_X=0; 
    Extended.Rosette_Aberration_6_Y=0; 
    Extended.Astigmatism_6_X=0; 
    Extended.Astigmatism_6_Y=0; 
    Extended.SI_Units=1; 

    %%%%%%% WRITING EXTENDED HEADER

    for i=1:Basic.nz

        status = fseek(fid_mrc, 1024+Basic.numfloats*4*(i-1), 'bof');
        fwrite(fid_mrc, Extended.a_tilt(i), 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.b_tilt, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.x, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.y, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.z, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.x_shift, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.y_shift, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.defocus, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.exposure, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.mean_intensity, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.tilt_axis, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.pixel_size, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.magnification, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Microscope_type, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Gun_type, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Lens_type, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.D_number_of_microscope, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.High_tension, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Diffraction_lens_value_in_percent, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.MTF, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Starting_Df, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Focus_step, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.DAC_setting, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Spherical_aberration, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Semi_convergence, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Info_limit, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Number_of_images, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Image_number_in_series(i), 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Coma_3_X, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Coma_3_Y, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Astigmatism_2_X, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Astigmatism_2_Y, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Astigmatism_3_X, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Astigmatism_3_Y, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Camera_type_number, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Camera_position, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Spherical_Aberration_4, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Star_Aberration_4_X, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Star_Aberration_4_Y, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Astigmatism_4_X, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Astigmatism_4_Y, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Coma_5_X, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Coma_5_Y, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Three_Lobe_5_X, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Three_Lobe_5_Y, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Astigmatism_5_X, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Astigmatism_5_Y, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Spherical_Aberration_6, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Star_Aberration_6_X, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Star_Aberration_6_Y, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Rosette_Aberration_6_X, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Rosette_Aberration_6_Y, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Astigmatism_6_X, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.Astigmatism_6_Y, 'float');   % float 4-byte 
        fwrite(fid_mrc, Extended.SI_Units, 'float');   % float 4-byte 

    end

    fclose(fid_mrc);
    disp('Done :) !')
    disp('*********************************************************************')

    msgbox(['Tif frames are converted to a MRC file into the following path and name:' mrc_name],'Tif Frames -> MRC')
end