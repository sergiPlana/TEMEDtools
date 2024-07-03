function hkl_filter_YasarVersion()
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 1 is on 0 is off %%%%%%%%%%%%%%%%%%%
    ADT3D = 0;
    %%%%%%%%%%%%%%%%%%%%%%%%
    plotting = 0;
    writeout = 1;
    % Max Iterations of Fit
    MaxIter = 3;
    % single hkl fit
    single = 0;
    hkl = [16 -1 -7];
    % hkl edge filter
    edge = 1;
    m3 = 0;
    %%%% noch nicht fertig
    % overALL fit
    % all = 0;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% file read parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fname_in = 0;
    path_in = 'Y:\Sergi\';
    textscan_options1 = 'HeaderLines';
    multi = 'off';

    if ADT3D == 1
        filetyp = '*.ehkl';
        formatSpec = '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %*[^\n]';
        textscan_options1v = 4;
        textscan_options2 = 'Delimiter';
        textscan_options2v = '';
    else
        filetyp = '*.xhkl';
        formatSpec = '%4s %4s %4s %8s %8s %8s %5s %7s %9s %10s %8*s %*[^\n]';
        textscan_options1v = 1;
        textscan_options2 = 'whitespace';
        textscan_options2v = '';
    end;

    if fname_in == 0
    [filename, pathname] = uigetfile({filetyp;'*.*'}, 'Read in', path_in, 'MultiSelect', multi);
        if isequal(filename,0) || isequal(pathname,0) 
            disp('No data loaded.'); return; 
        end;
        fname_in = [pathname filename];
    else
        pathname = '';
        filename = '';
    end;

    fid_in = fopen(fname_in,'r');
    rawdata = textscan(fid_in,formatSpec,textscan_options1,textscan_options1v,textscan_options2,textscan_options2v);
    fclose(fid_in);
    
    % cell to double
    if ADT3D == 1
        t = [rawdata{:}];
        bla = [t(:,1:5),t(:,8:9),t(:,15),t(:,14),t(:,4)];
        tempor = bla(1,1:4);
        rows_bla = size(bla,1);
        ttt = 1;
        nnn = 4;
        for xxx = 1:rows_bla-1
            [r,c,v] = find(bla(xxx,1)==bla(xxx+1,1) & bla(xxx,2)==bla(xxx+1,2) & bla(xxx,3)==bla(xxx+1,3));
            if v == 1
                nnn = nnn + 1;
                tempor(ttt,nnn) = bla(xxx+1,4); 
            else
                nnn = 4;
                ttt = ttt + 1;
                tempor(ttt,1:4) = bla(xxx+1,1:4);
            end;
        end     
        size_tempor = size(tempor);
        xhkl = bla;
        for yyy = 1:rows_bla
            [r,c,v] = find(tempor(:,1)==xhkl(yyy,1) & tempor(:,2)==xhkl(yyy,2) & tempor(:,3)==xhkl(yyy,3));
            max_tempor = max(tempor(r,4:size_tempor(2)));
            xhkl(yyy,4) = max_tempor;
        end
    else
        xhkl = str2double([rawdata{:}]);
    end;
    rows_xhkl = size(xhkl,1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%% max hkl %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tic
    temp = [1 2 3 4 5];
    index1 = 1;
    index2 = 1;
    while index1 <= rows_xhkl-1;
        if isequal(xhkl(index1,1:3), xhkl(index1+1,1:3))
            temp(index2,1:5) = xhkl(index1,1:5);
            index1 = index1 + 1;
        else
            temp(index2,1:5) = xhkl(index1,1:5);
            index1 = index1 + 1;
            index2 = index2 + 1;
        end;       
    end
    toc
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%% single hkl fit %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if single == 1
        % hkl search
        xy = [0 0];
        ind2 = 1;
        for ind = 1:rows_xhkl
            [r,c,v] = find(xhkl(ind,1)==hkl(1,1) & xhkl(ind,2)==hkl(1,2) & xhkl(ind,3)==hkl(1,3));
            if v==1
                xy(ind2,1) = [xhkl(ind,9)];
                xy(ind2,2) = [xhkl(ind,10)];
                ind2 = ind2 + 1;
            else
                ind2 = 1;
            end;
        end
        % FIT and MAX
        [s_res,s_idx]=sortrows(xy,[1]);
        xy = xy(s_idx,:);
        [f,gof,output] = fit(xy(:,1),xy(:,2),'gauss1','MaxIter',MaxIter);
        coeff = coeffvalues(f);
        a1 = coeff(1,1);
        b1 = coeff(1,2);
        c1 = coeff(1,3);
        Max1 = a1*exp(-((b1-b1)/c1));
        disp(Max1);
        disp(gof.rsquare);
        % PLOT 
        if plotting==1
            figure
            plot(xy(:,1),xy(:,2),...
                'LineStyle','none',...
                'LineWidth',2,...
                'Marker','o',...
                'MarkerSize',10,...
                'MarkerFaceColor','r',...
                'MarkerEdgeColor','k');
            hold on
            gauss = plot(f,'r--');
            set(gauss,'LineWidth',4)
            lg = gca;
            legend(lg,'off');
            title(['(' num2str(hkl) ')']);
            hold off
        end;

    end;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%%%% hkl filter edges %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if edge == 1

        % max and min tilt
        max_tilt = max(xhkl(:,9));
        min_tilt = min(xhkl(:,9));
        % sucht randHKL
        ind5 = 1;
        ind6 = 1;
        ind7 = 1;
        ind7x1 = 1;
        for ind3 = 1:rows_xhkl
            nr = 0;
            [r,c,v] = find(xhkl(ind3,9)==max_tilt || xhkl(ind3,9)==min_tilt);
            if v==1
                hkl_edge = [xhkl(ind3,1),xhkl(ind3,2),xhkl(ind3,3)];
                edge_data(ind5,:) = xhkl(ind3,:);
                ind5 = ind5 + 1;
                for ind4 = 1:rows_xhkl
                    [r,c,v] = find(xhkl(ind4,1)==hkl_edge(1,1) & xhkl(ind4,2)==hkl_edge(1,2) & xhkl(ind4,3)==hkl_edge(1,3));
                    if v==1
                        nr = nr+1;
                    end;
                end
                if nr<3
                    edge_less3(ind6,:) = [hkl_edge(1,:)];
                    ind6 = ind6+1;
                end;
                if nr==3
                    edge_equal3(ind7,:) = [hkl_edge(1,:)];
                    ind7 = ind7+1;
                end;
                if nr>3 && nr<10
                    edge_more3(ind7x1,:) = [hkl_edge(1,:)];
                    ind7x1 = ind7x1+1;
                end;        
            end;
        end

        % löscht randHKL weniger als 3 gem INT
        temp_L3 = temp;
        rows_edge_less3 = size(edge_less3,1);
        for ind8 = 1:rows_edge_less3
            [r,c,v] = find(edge_less3(ind8,1) == temp_L3(:,1) & edge_less3(ind8,2) == temp_L3(:,2) & edge_less3(ind8,3) == temp_L3(:,3));
            if v==1
                temp_L3(r,:) = [];
            end
        end

        % fit of randHKL gleich 3 gem INT
        xy = [0 0];
        ind11 = 1;
        rows_edge_equal3 = size(edge_equal3,1);
        for ind9 = 1:rows_edge_equal3
            hkl = edge_equal3(ind9,1:3);
            for ind10 = 1:rows_xhkl
                [r,c,v] = find(xhkl(ind10,1)==hkl(1,1) & xhkl(ind10,2)==hkl(1,2) & xhkl(ind10,3)==hkl(1,3));
                if v==1
                    edge_fit_E3(ind9,1:3) = hkl;
                    edge_fit_E3(ind9,4) = xhkl(ind10,4);
                    xy(ind11,1) = [xhkl(ind10,9)];
                    xy(ind11,2) = [xhkl(ind10,10)];
                    edge_fit_E3(ind9,8) = max(xy(:,1));
                    edge_fit_E3(ind9,9) = min(xy(:,1));
                    ind11 = ind11 + 1;
                else
                    ind11 = 1;
                end;  
            end
            % FIT
            [s_res,s_idx]=sortrows(xy,[1]);
            xy = xy(s_idx,:);
            try 
                [f,gof,output] = fit(xy(:,1),xy(:,2),'gauss1','MaxIter',MaxIter);
                coeff = coeffvalues(f);
                a1 = coeff(1,1);
                b1 = coeff(1,2);
                c1 = coeff(1,3);
                Max1 = a1*exp(-((b1-b1)/c1));
                disp(Max1);
                % PLOT
                if plotting==1
                    figure
                    plot(xy(:,1),xy(:,2),...
                        'LineStyle','none',...
                        'LineWidth',2,...
                        'Marker','o',...
                        'MarkerSize',10,...
                        'MarkerFaceColor','r',...
                        'MarkerEdgeColor','k');
                    hold on
                    gauss = plot(f,'r--');
                    set(gauss,'LineWidth',4)
                    lg = gca;
                    legend(lg,'off');
                    title(['(' num2str(hkl) ')']);
                    hold off
                end;
                edge_fit_E3(ind9,5) = Max1;
                edge_fit_E3(ind9,6) = gof.rsquare;
                edge_fit_E3(ind9,7) = b1;
            catch
                disp('Something is fucking wrong with this reflection. Fitting is not working and the reflection is not added :)')
                disp(' ')
            end
        end
        % filter bad edge hkl
        for ind12 = 1:rows_edge_equal3
            if (edge_fit_E3(ind12,8) < edge_fit_E3(ind12,7) || edge_fit_E3(ind12,9) > edge_fit_E3(ind12,7) || edge_fit_E3(ind12,6) < 0.8)
                edge_fit_E3(ind12,10) = 1;
            end;
        end
        temp_L3_E3 = temp_L3;
        for ind13 = 1:rows_edge_equal3
            if edge_fit_E3(ind13,10)==1
                [r,c,v] = find(edge_fit_E3(ind13,1) == temp_L3_E3(:,1) & edge_fit_E3(ind13,2) == temp_L3_E3(:,2) & edge_fit_E3(ind13,3) == temp_L3_E3(:,3));
                temp_L3_E3(r,:) = [];
            end;
        end
        %%%%%
        if m3 == 1
            % fit of randHKL mehr 3 gem INT
            xy = [0 0];
            ind11 = 1;
            rows_edge_more3 = size(edge_more3,1);
            for ind9 = 1:rows_edge_more3
                xy = [0 0];
                hkl = edge_more3(ind9,1:3);
                for ind10 = 1:rows_xhkl
                    [r,c,v] = find(xhkl(ind10,1)==hkl(1,1) & xhkl(ind10,2)==hkl(1,2) & xhkl(ind10,3)==hkl(1,3));
                    if v==1
                        edge_fit_M3(ind9,1:3) = hkl;
                        edge_fit_M3(ind9,4) = xhkl(ind10,4);
                        xy(ind11,1) = [xhkl(ind10,9)];
                        xy(ind11,2) = [xhkl(ind10,10)];
                        edge_fit_M3(ind9,8) = max(xy(:,1));
                        edge_fit_M3(ind9,9) = min(xy(:,1));
                        ind11 = ind11 + 1;
                    else
                        ind11 = 1;
                    end;  
                end
                % FIT
                [s_res,s_idx]=sortrows(xy,[1]);
                xy = xy(s_idx,:);
                [f,gof,output] = fit(xy(:,1),xy(:,2),'gauss1','MaxIter',MaxIter);
                coeff = coeffvalues(f);
                a1 = coeff(1,1);
                b1 = coeff(1,2);
                c1 = coeff(1,3);
                Max1 = a1*exp(-((b1-b1)/c1));
                disp(Max1);
                % PLOT
                if plotting==1
                    figure
                    plot(xy(:,1),xy(:,2),...
                        'LineStyle','none',...
                        'LineWidth',2,...
                        'Marker','o',...
                        'MarkerSize',10,...
                        'MarkerFaceColor','r',...
                        'MarkerEdgeColor','k');
                    hold on
                    gauss = plot(f,'r--');
                    set(gauss,'LineWidth',4)
                    lg = gca;
                    legend(lg,'off');
                    title(['(' num2str(hkl) ')']);
                    hold off
                end;
                edge_fit_M3(ind9,5) = Max1;
                edge_fit_M3(ind9,6) = gof.rsquare;
                edge_fit_M3(ind9,7) = b1;
            end
            % filter bad edge hkl
            for ind12 = 1:rows_edge_more3
                if (edge_fit_M3(ind12,8) < edge_fit_M3(ind12,7) || edge_fit_M3(ind12,9) > edge_fit_M3(ind12,7) || edge_fit_M3(ind12,6) < 0.8)
                    edge_fit_M3(ind12,10) = 1;
                end;
            end
            temp_L3_E3_M3 = temp_L3_E3;
            for ind13 = 1:rows_edge_more3
                if edge_fit_M3(ind13,10)==1
                    [r,c,v] = find(edge_fit_M3(ind13,1) == temp_L3_E3_M3(:,1) & edge_fit_M3(ind13,2) == temp_L3_E3_M3(:,2) & edge_fit_M3(ind13,3) == temp_L3_E3_M3(:,3));
                    temp_L3_E3_M3(r,:) = [];
                end;
            end

        else
            temp_L3_E3_M3 = temp_L3_E3;
        end

    end;

    % find max Int
    max_I = max(temp_L3_E3_M3(:,4));
    % scale Int 
    s = 99999.99/max_I;
    S = 10^floor(log10(s));
    hkl_sorted_scaled = [temp_L3_E3_M3(:,1:3),temp_L3_E3_M3(:,4:5)*S];

    if writeout==1;
        fname_out = 0;
        path_out = pathname;
        filetyp = '*.hkl';
        formatSpec = '%4.0f%4.0f%4.0f%8.2f%8.2f\n';
        matrix_to_write = hkl_sorted_scaled;

        if fname_out == 0
        [filename, pathname_out] = uiputfile({filetyp;'*.*'}, 'Write out', path_out);
        if isequal(filename,0) || isequal(pathname_out,0) 
            disp('No data wrote.'); return; 
        end;
        fname_out =[pathname_out filename];
        end;

        fid_out = fopen(fname_out,'wt');
            fprintf(fid_out,formatSpec,matrix_to_write');
        fclose(fid_out);
    end;
    
    msgbox({'HKL file has been filtered.'},'HKL Filter')
end