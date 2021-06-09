
Partic = [7,9:12,14,18,20,22,23];

%set up ppt
out_dir =  strcat('C:\Users\ckohl\Desktop\Data\');
cd(out_dir)
import mlreportgen.ppt.*
ppt = Presentation(strcat('Behaviour Summary'));
open(ppt);
titleSlide = add(ppt,'Title Slide');
replace(titleSlide,"Title",strcat('Behaviour Summary -  BehaviourIII.m'));


Data = struct();
for partic = 1:length(Partic)
    partic_str = sprintf('%02d', Partic(partic));
    for session = [0,1]
        sess_dir = strcat(out_dir,'BETA',partic_str,'\Session',num2str(session));
        if exist(sess_dir,'dir')
            %% Load
            file=strcat(sess_dir, '\beta',partic_str,'_results');
            file2=strcat(sess_dir, '\beta_',partic_str,'_results');
            opts = delimitedTextImportOptions("NumVariables", 11);
            opts.DataLines = [6, Inf];
            opts.Delimiter = "\t";
            opts.VariableNames = ["Trial", "CueCond", "TMSCond", "TapCond", "Accuracy", "YesResponse", "NoResponse", "TapTime", "TMSTime", "RT", "Threshold"];
            opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            try
                tbl = readtable(file, opts);
            catch
                tbl = readtable(file2, opts);
            end
            % Convert to output type
            Trial = tbl.Trial;
            CueCond = tbl.CueCond;
            TMSCond = tbl.TMSCond;
            TapCond = tbl.TapCond;
            Accuracy = tbl.Accuracy;
            YesResponse = tbl.YesResponse;
            NoResponse = tbl.NoResponse;
            TapTime = tbl.TapTime;
            TMSTime = tbl.TMSTime;
            RT = tbl.RT;
            Threshold = tbl.Threshold;
            clear opts tbl
            
            % CueCond: 0=Hand, 1=Head
            % TapCond: 0=Null, 1=Threshold, 2=Supra
            % TMSCond: 0=Null, 1=100, 2=25
            try 
                pcount = size(Data.(strcat('Session',num2str(session))).Tap_pure_null,1)+1;
            catch
                pcount = 1;
            end
            %% Tap Detection   
            % ACCURACY
            % tap only
            Data.(strcat('Session',num2str(session))).Tap_pure_null(pcount,:) = mean(Accuracy(CueCond==0 & TapCond==0 & TMSCond==0));
            Data.(strcat('Session',num2str(session))).Tap_pure_thr(pcount,:) = mean(Accuracy(CueCond==0 & TapCond==1 & TMSCond==0));
            Data.(strcat('Session',num2str(session))).Tap_pure_spr(pcount,:) = mean(Accuracy(CueCond==0 & TapCond==2 & TMSCond==0));
            % tap with tms100
            Data.(strcat('Session',num2str(session))).Tap_tms100_null(pcount,:) = mean(Accuracy(CueCond==0 & TapCond==0 & TMSCond==1));
            Data.(strcat('Session',num2str(session))).Tap_tms100_thr(pcount,:) = mean(Accuracy(CueCond==0 & TapCond==1 & TMSCond==1));
            Data.(strcat('Session',num2str(session))).Tap_tms100_spr(pcount,:) = mean(Accuracy(CueCond==0 & TapCond==2 & TMSCond==1));
            % tap with tms25
            Data.(strcat('Session',num2str(session))).Tap_tms25_null(pcount,:) = mean(Accuracy(CueCond==0 & TapCond==0 & TMSCond==2));
            Data.(strcat('Session',num2str(session))).Tap_tms25_thr(pcount,:) = mean(Accuracy(CueCond==0 & TapCond==1 & TMSCond==2));
            Data.(strcat('Session',num2str(session))).Tap_tms25_spr(pcount,:) = mean(Accuracy(CueCond==0 & TapCond==2 & TMSCond==2));
            
            % RT
            % tap only
            Data.(strcat('Session',num2str(session))).RT_Tap_pure_null(pcount,:) = mean(RT(CueCond==0 & TapCond==0 & TMSCond==0 & Accuracy==1))./1000;
            Data.(strcat('Session',num2str(session))).RT_Tap_pure_thr(pcount,:) = mean(RT(CueCond==0 & TapCond==1 & TMSCond==0 & Accuracy==1))./1000;
            Data.(strcat('Session',num2str(session))).RT_Tap_pure_spr(pcount,:) = mean(RT(CueCond==0 & TapCond==2 & TMSCond==0 & Accuracy==1))./1000;
            % tap with tms100
            Data.(strcat('Session',num2str(session))).RT_Tap_tms100_null(pcount,:) = mean(RT(CueCond==0 & TapCond==0 & TMSCond==1 & Accuracy==1))./1000;
            Data.(strcat('Session',num2str(session))).RT_Tap_tms100_thr(pcount,:) = mean(RT(CueCond==0 & TapCond==1 & TMSCond==1 & Accuracy==1))./1000;
            Data.(strcat('Session',num2str(session))).RT_Tap_tms100_spr(pcount,:) = mean(RT(CueCond==0 & TapCond==2 & TMSCond==1 & Accuracy==1))./1000;
            % tap with tms25
            Data.(strcat('Session',num2str(session))).RT_Tap_tms25_null(pcount,:) = mean(RT(CueCond==0 & TapCond==0 & TMSCond==2 & Accuracy==1))./1000;
            Data.(strcat('Session',num2str(session))).RT_Tap_tms25_thr(pcount,:) = mean(RT(CueCond==0 & TapCond==1 & TMSCond==2 & Accuracy==1))./1000;
            Data.(strcat('Session',num2str(session))).RT_Tap_tms25_spr(pcount,:) = mean(RT(CueCond==0 & TapCond==2 & TMSCond==2 & Accuracy==1))./1000;
          
            
            %% TMS Detection
            % ACCURACY
            % no tms
            Data.(strcat('Session',num2str(session))).Tms_null_null(pcount,:) = mean(Accuracy(CueCond==1 & TapCond==0 & TMSCond==0));
            Data.(strcat('Session',num2str(session))).Tms_null_thr(pcount,:) = mean(Accuracy(CueCond==1 & TapCond==1 & TMSCond==0));
            Data.(strcat('Session',num2str(session))).Tms_null_spr(pcount,:) = mean(Accuracy(CueCond==1 & TapCond==2 & TMSCond==0));
            % tms with tap (100)
            Data.(strcat('Session',num2str(session))).Tms_tms100_null(pcount,:) = mean(Accuracy(CueCond==1 & TapCond==0 & TMSCond==1));
            Data.(strcat('Session',num2str(session))).Tms_tms100_thr(pcount,:) = mean(Accuracy(CueCond==1 & TapCond==1 & TMSCond==1));
            Data.(strcat('Session',num2str(session))).Tms_tms100_spr(pcount,:) = mean(Accuracy(CueCond==1 & TapCond==2 & TMSCond==1));
            % tms with tap (25)
            Data.(strcat('Session',num2str(session))).Tms_tms25_null(pcount,:) = mean(Accuracy(CueCond==1 & TapCond==0 & TMSCond==2));
            Data.(strcat('Session',num2str(session))).Tms_tms25_thr(pcount,:) = mean(Accuracy(CueCond==1 & TapCond==1 & TMSCond==2));
            Data.(strcat('Session',num2str(session))).Tms_tms25_spr(pcount,:) = mean(Accuracy(CueCond==1 & TapCond==2 & TMSCond==2));
            
            %RT
            % no tms
            Data.(strcat('Session',num2str(session))).RT_Tms_null_null(pcount,:) = mean(RT(CueCond==1 & TapCond==0 & TMSCond==0 & Accuracy==1))./1000;
            Data.(strcat('Session',num2str(session))).RT_Tms_null_thr(pcount,:) = mean(RT(CueCond==1 & TapCond==1 & TMSCond==0 & Accuracy==1))./1000;
            Data.(strcat('Session',num2str(session))).RT_Tms_null_spr(pcount,:) = mean(RT(CueCond==1 & TapCond==2 & TMSCond==0 & Accuracy==1))./1000;
            % tms with tap (100)
            Data.(strcat('Session',num2str(session))).RT_Tms_tms100_null(pcount,:) = mean(RT(CueCond==1 & TapCond==0 & TMSCond==1 & Accuracy==1))./1000;
            Data.(strcat('Session',num2str(session))).RT_Tms_tms100_thr(pcount,:) = mean(RT(CueCond==1 & TapCond==1 & TMSCond==1 & Accuracy==1))./1000;
            Data.(strcat('Session',num2str(session))).RT_Tms_tms100_spr(pcount,:) = mean(RT(CueCond==1 & TapCond==2 & TMSCond==1 & Accuracy==1))./1000;
            % tms with tap (25)
            Data.(strcat('Session',num2str(session))).RT_Tms_tms25_null(pcount,:) = mean(RT(CueCond==1 & TapCond==0 & TMSCond==2 & Accuracy==1))./1000;
            Data.(strcat('Session',num2str(session))).RT_Tms_tms25_thr(pcount,:) = mean(RT(CueCond==1 & TapCond==1 & TMSCond==2 & Accuracy==1))./1000;
            Data.(strcat('Session',num2str(session))).RT_Tms_tms25_spr(pcount,:) = mean(RT(CueCond==1 & TapCond==2 & TMSCond==2 & Accuracy==1))./1000;
        end
    end
end
             
%% Tap Detection Accuracy             
tempfig = figure;
hold on
for session = [0,1]
    if session == 0
        data = Data.Session0;
    else
        data = Data.Session1;
    end
    subplot(1,2,session+1)
    hold on
    title(strcat('Accuracy Tap Detection - Session',num2str(session)))
    toplot =[mean(data.Tap_pure_null),mean(data.Tap_tms100_null),mean(data.Tap_tms25_null);...
             mean(data.Tap_pure_spr),mean(data.Tap_tms100_spr),mean(data.Tap_tms25_spr);...
             mean(data.Tap_pure_thr),mean(data.Tap_tms100_thr),mean(data.Tap_tms25_thr)];
    
    b = bar(toplot);
    b(1).FaceColor = [255,160,122]./255;
    b(2).FaceColor = [205,92,92]./255;
    b(3).FaceColor = [139,0,0]./255;
    
    % errors
    sq = sqrt(length(data.Tap_pure_null));
    error_toplot =[std(data.Tap_pure_null)/sq,std(data.Tap_tms100_null)/sq,std(data.Tap_tms25_null)/sq;...
                   std(data.Tap_pure_spr)/sq,std(data.Tap_tms100_spr)/sq,std(data.Tap_tms25_spr)/sq;...
                   std(data.Tap_pure_thr)/sq,std(data.Tap_tms100_thr)/sq,std(data.Tap_tms25_thr)/sq];
    tick = 0.225;
    err=errorbar([1-tick,1,1+tick;2-tick,2,2+tick;3-tick,3,3+tick],toplot,error_toplot);
    err(1).Color = [0 0 0]; err(2).Color = [0 0 0]; err(3).Color = [0 0 0];                            
    err(1).LineStyle = 'none';err(2).LineStyle = 'none'; err(3).LineStyle = 'none'; 

    set(gca,'XTick',[1,2,3])
    set(gca,'xticklabel',{['Null Tap'],['Supra Tap'],['Threshold Tap']})
    ylabel('Accuracy (proportion correct)')
    ylim([0 1])             
end
legend('NoTMS','TMS100','TMS25','Location','SouthEast')     
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'Accuracy - Tap Detection');
print(tempfig,"-dpng",'tempfig1');Imageslide = Picture('tempfig1.png');
replace(slide,"Content",Imageslide);

%% Tap Detection RT             
tempfig = figure;
hold on
for session = [0,1]
    if session == 0
        data = Data.Session0;
    else
        data = Data.Session1;
    end
    subplot(1,2,session+1)
    hold on
    title(strcat('RT Tap Detection - Session',num2str(session)))
    toplot =[mean(data.RT_Tap_pure_null),mean(data.RT_Tap_tms100_null),mean(data.RT_Tap_tms25_null);...
             mean(data.RT_Tap_pure_spr),mean(data.RT_Tap_tms100_spr),mean(data.RT_Tap_tms25_spr);...
             mean(data.RT_Tap_pure_thr),mean(data.RT_Tap_tms100_thr),mean(data.RT_Tap_tms25_thr)];
    
    b = bar(toplot);
    b(1).FaceColor = [255,160,122]./255;
    b(2).FaceColor = [205,92,92]./255;
    b(3).FaceColor = [139,0,0]./255;
    
    % errors
    sq = sqrt(length(data.RT_Tap_pure_null));
    error_toplot =[std(data.RT_Tap_pure_null)/sq,std(data.RT_Tap_tms100_null)/sq,std(data.RT_Tap_tms25_null)/sq;...
                   std(data.RT_Tap_pure_spr)/sq,std(data.RT_Tap_tms100_spr)/sq,std(data.RT_Tap_tms25_spr)/sq;...
                   std(data.RT_Tap_pure_thr)/sq,std(data.RT_Tap_tms100_thr)/sq,std(data.RT_Tap_tms25_thr)/sq];
    tick = 0.225;
    err=errorbar([1-tick,1,1+tick;2-tick,2,2+tick;3-tick,3,3+tick],toplot,error_toplot);
    err(1).Color = [0 0 0]; err(2).Color = [0 0 0]; err(3).Color = [0 0 0];                            
    err(1).LineStyle = 'none';err(2).LineStyle = 'none'; err(3).LineStyle = 'none'; 

    set(gca,'XTick',[1,2,3])
    set(gca,'xticklabel',{['Null Tap'],['Supra Tap'],['Threshold Tap']})
    ylabel('RT (s)')
    ylim([0 1])             
end
legend('NoTMS','TMS100','TMS25','Location','SouthEast')     
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'RT - Tap Detection');
print(tempfig,"-dpng",'tempfig2');Imageslide = Picture('tempfig2.png');
replace(slide,"Content",Imageslide);

%% TMS Detection Accuracy             
tempfig = figure;
hold on
for session = [0,1]
    if session == 0
        data = Data.Session0;
    else
        data = Data.Session1;
    end
    subplot(1,2,session+1)
    hold on
    title(strcat('Accuracy TMS Detection - Session',num2str(session)))
    toplot =[mean(data.Tms_null_null),mean(data.Tms_null_thr),mean(data.Tms_null_spr);...
             mean(data.Tms_tms100_null),mean(data.Tms_tms100_thr),mean(data.Tms_tms100_spr);...
             mean(data.Tms_tms25_null),mean(data.Tms_tms25_thr),mean(data.Tms_tms25_spr)];
    b = bar(toplot);
    b(1).FaceColor = [.9 .9 .9];
    b(2).FaceColor = [.5 .5 .5];
    b(3).FaceColor = [.3 .3 .3];
    
     % errors
    sq = sqrt(length(data.Tms_null_null));
    error_toplot =[std(data.Tms_null_null)/sq,std(data.Tms_null_thr)/sq,std(data.Tms_null_spr)/sq;...
                   std(data.Tms_tms100_null)/sq,std(data.Tms_tms100_thr)/sq,std(data.Tms_tms100_spr)/sq;...
                   std(data.Tms_tms25_null)/sq,std(data.Tms_tms25_thr)/sq,std(data.Tms_tms25_spr)/sq];
    tick = 0.225;
    err=errorbar([1-tick,1,1+tick;2-tick,2,2+tick;3-tick,3,3+tick],toplot,error_toplot);
    err(1).Color = [0 0 0]; err(2).Color = [0 0 0]; err(3).Color = [0 0 0];                            
    err(1).LineStyle = 'none';err(2).LineStyle = 'none'; err(3).LineStyle = 'none'; 
    
    set(gca,'XTick',[1,2,3])
    set(gca,'xticklabel',{['Null TMS'],['TMS100'],['TMS25']})
    ylabel('Accuracy (proportion correct)')
    ylim([0 1])             
end             
legend('NullTap','ThrTap','SprTap','Location','SouthEast')            
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'Accuracy - TMS Detection');
print(tempfig,"-dpng",'tempfig3');Imageslide = Picture('tempfig3.png');
replace(slide,"Content",Imageslide);            
             
         

%% TMS Detection RT         
tempfig = figure;
hold on
for session = [0,1]
    if session == 0
        data = Data.Session0;
    else
        data = Data.Session1;
    end
    subplot(1,2,session+1)
    hold on
    title(strcat('RT TMS Detection - Session',num2str(session)))
    toplot =[mean(data.RT_Tms_null_null),mean(data.RT_Tms_null_thr),mean(data.RT_Tms_null_spr);...
             mean(data.RT_Tms_tms100_null),mean(data.RT_Tms_tms100_thr),mean(data.RT_Tms_tms100_spr);...
             mean(data.RT_Tms_tms25_null),mean(data.RT_Tms_tms25_thr),mean(data.RT_Tms_tms25_spr)];
    b = bar(toplot);
    b(1).FaceColor = [.9 .9 .9];
    b(2).FaceColor = [.5 .5 .5];
    b(3).FaceColor = [.3 .3 .3];
    
     % errors
    sq = sqrt(length(data.RT_Tms_null_null));
    error_toplot =[std(data.RT_Tms_null_null)/sq,std(data.RT_Tms_null_thr)/sq,std(data.RT_Tms_null_spr)/sq;...
                   std(data.RT_Tms_tms100_null)/sq,std(data.RT_Tms_tms100_thr)/sq,std(data.RT_Tms_tms100_spr)/sq;...
                   std(data.RT_Tms_tms25_null)/sq,std(data.RT_Tms_tms25_thr)/sq,std(data.RT_Tms_tms25_spr)/sq];
    tick = 0.225;
    err=errorbar([1-tick,1,1+tick;2-tick,2,2+tick;3-tick,3,3+tick],toplot,error_toplot);
    err(1).Color = [0 0 0]; err(2).Color = [0 0 0]; err(3).Color = [0 0 0];                            
    err(1).LineStyle = 'none';err(2).LineStyle = 'none'; err(3).LineStyle = 'none'; 
    
    set(gca,'XTick',[1,2,3])
    set(gca,'xticklabel',{['Null TMS'],['TMS100'],['TMS25']})
    ylabel('RT (s)')
    ylim([0 1])             
end             
legend('NullTap','ThrTap','SprTap','Location','SouthEast')            
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'RT - TMS Detection');
print(tempfig,"-dpng",'tempfig4');Imageslide = Picture('tempfig4.png');
replace(slide,"Content",Imageslide);     
            

close(ppt)
delete tempfig1.png tempfig2.png tempfig3.png tempfig4.png      
% close all           