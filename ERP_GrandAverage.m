


Partic = [7,9:12,14,18,20,22,23];

% load eeglab
eeglab_dir='C:\Users\ckohl\Documents\MATLAB\eeglab2020_0';
cd(eeglab_dir)
eeglab


%set up ppt
out_dir =  strcat('C:\Users\ckohl\Desktop\Data\');
cd(out_dir)
import mlreportgen.ppt.*
ppt = Presentation(strcat('Grand Averages'));
open(ppt);
titleSlide = add(ppt,'Title Slide');
replace(titleSlide,"Title",strcat('Grand Averages -  ERP_GrandAverage.m'));


% define events
tap_og = 'S  1';
tms_og = 'S  2';
cuehand_og = 'S  4';
cuehead_og = 'S  8';
respcue_og = 'S 16';
% new events: 'T/Z' - TapCond - TMSCond
tap = {'T_10','T_11','T_12','T_20','T_21','T_22'};
tms = {'Z_01','Z_11','Z_21','Z_02','Z_12','Z_22'};

electr_oi = 'C3';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = struct();
for partic = 1:length(Partic)
    partic_str = sprintf('%02d', Partic(partic));
    for session = [0,1]
        sess_dir = strcat(out_dir,'BETA',partic_str,'\Session',num2str(session));
        if exist(sess_dir,'dir')
            cd(sess_dir)
            %% --- Load S1Loc --     
            % LOAD PRE
            filename = strcat(partic_str,'_S1Loc_Pre_clean.set');
            EEG = pop_loadset('filename',filename,'filepath',sess_dir);
            EEG = eeg_checkset( EEG );
            %find electrode oi
            for chan= 1:length(EEG.chanlocs)
                if length(EEG.chanlocs(chan).labels)==length(electr_oi)
                    if EEG.chanlocs(chan).labels==electr_oi
                        electr_oi_i=chan;
                    end
                end
            end
            %PRE ERP
            EEG = pop_epoch(EEG, {tap_og}, [-.2 .3], 'epochinfo', 'yes');
            EEG = pop_rmbase(EEG, [-100   -0]);
            Data.(strcat('Session',num2str(session))).S1Loc_Pre(partic,:) = mean(EEG.data(electr_oi_i,:,:),3);
            % LOAD POST
            filename = strcat(partic_str,'_S1Loc_Post_clean.set');
            EEG = pop_loadset('filename',filename,'filepath',sess_dir);
            EEG = eeg_checkset( EEG );
            % POST ERP
            EEG = pop_epoch(EEG, {tap_og}, [-.2 .3], 'epochinfo', 'yes');
            EEG = pop_rmbase(EEG, [-100   -0]);
            Data.(strcat('Session',num2str(session))).S1Loc_Post(partic,:) = mean(EEG.data(electr_oi_i,:,:),3);
            %% --- Load Task --
            filename = strcat(partic_str,'_clean.set');
            EEGall = pop_loadset('filename',filename,'filepath',sess_dir);
            EEGall = eeg_checkset( EEGall );
            % ERP TAP THRESHOLD
            EEG = pop_epoch( EEGall, {tap{1}}, [-.2 .3], 'epochinfo', 'yes');
            EEG = pop_rmbase(EEG, [-200   0]);
            Data.(strcat('Session',num2str(session))).SEP_thr(partic,:) = mean(EEG.data(electr_oi_i,:,:),3);
            % ERP TAP SUPRA
            EEG = pop_epoch( EEGall, {tap{4}}, [-.2 .3], 'epochinfo', 'yes');
            EEG = pop_rmbase(EEG, [-200   0]);
            Data.(strcat('Session',num2str(session))).SEP_spr(partic,:) = mean(EEG.data(electr_oi_i,:,:),3);
            % ERP PURE TEP
            EEG = pop_epoch( EEGall, {tms{1}, tms{4}}, [-.2 .3], 'epochinfo', 'yes');
            EEG = pop_rmbase(EEG, [-200   -50]);
            Data.(strcat('Session',num2str(session))).TEP_pure(partic,:) = mean(EEG.data(electr_oi_i,:,:),3);
            % ERP 100 THRESHOLD
            EEG = pop_epoch( EEGall, {tap{2}}, [-.2 .3], 'epochinfo', 'yes');
            EEG = pop_rmbase(EEG, [-200   0]);
            Data.(strcat('Session',num2str(session))).TEP_100_thr(partic,:) = mean(EEG.data(electr_oi_i,:,:),3);
            % ERP 100 SUPRA
            EEG = pop_epoch( EEGall, {tap{5}}, [-.2 .3], 'epochinfo', 'yes');
            EEG = pop_rmbase(EEG, [-200   0]);
            Data.(strcat('Session',num2str(session))).TEP_100_spr(partic,:) = mean(EEG.data(electr_oi_i,:,:),3);
            % ERP 25 THRESHOLD
            EEG = pop_epoch( EEGall, {tap{3}}, [-.2 .3], 'epochinfo', 'yes');
            EEG = pop_rmbase(EEG, [-200   0]);
            Data.(strcat('Session',num2str(session))).TEP_25_thr(partic,:) = mean(EEG.data(electr_oi_i,:,:),3);
            % ERP 25 SUPRA
            EEG = pop_epoch( EEGall, {tap{6}}, [-.2 .3], 'epochinfo', 'yes');
            EEG = pop_rmbase(EEG, [-200   0]);
            Data.(strcat('Session',num2str(session))).TEP_25_spr(partic,:) = mean(EEG.data(electr_oi_i,:,:),3);
            plot_times = EEG.times;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot Grand Averages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% --- S1Loc ---
s1loc_colours = {[0 0 128]./255,[135,206,235]./255,[0 0 128]./255, [70,130,180]./255};
s1loc_lines = [':','-','--','-'];
s1loc_titles = {'Pre0','Post0','Pre1','Post1','tap'};

tempfig = figure;
hold on
title('S1 Localisation')
for dat = 1:4
    switch dat
        case 1
            data = Data.Session0.S1Loc_Pre;
        case 2
            data = Data.Session0.S1Loc_Post;
        case 3
            data = Data.Session1.S1Loc_Pre;
        case 4 
            data = Data.Session1.S1Loc_Post;
    end
    del = [];
    for row = 1:size(data,1)
        if all(data(row,:) == 0); del = [del, row]; end
    end
    data(del,:) = [];
    line(dat)=plot(plot_times, mean(data,1) ,'Color',s1loc_colours{dat},'Linewidth',2,'Linestyle',s1loc_lines(dat));
    %make standard error
    SE_upper=[];SE_lower=[];
    for i=1:length(plot_times)
        se = std(squeeze(data(:,i)))./sqrt(length(squeeze(data(:,i))));
        SE_upper(i) = mean(data(:,i))+se;
        SE_lower(i) = mean(data(:,i))-se;
    end
    tempx = [plot_times,fliplr(plot_times)];
    tempy = [SE_upper,fliplr(SE_lower)];
    A = fill(tempx,tempy,'k');
    A.EdgeColor = 'none';
    A.FaceColor = s1loc_colours{dat};
    A.FaceAlpha = .1;
end
y=ylim();
line(dat+1) = plot([0,0],[y],'-','Color',[.8 .8 .8]); 
legend(line,s1loc_titles,'Location','NorthWest')  
xlim([-50,300])
ylabel('Amplitude(μV)')
xlabel('Time(ms)')
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'S1Loc');
print(tempfig,"-dpng",'tempfig1');Imageslide = Picture('tempfig1.png');
replace(slide,"Content",Imageslide);

            
%% --- PURE SEPs ---
sep_colours = {[240,128,128]./255,[70,130,180]./255, [240,128,128]./255,[70,130,180]./255};
sep_lines = [':',':','-','-'];
sep_titles = {'supra0','threshold0','supra1','threshold1','tap'};

tempfig = figure;
hold on
title('SEPs')
line = [];
for dat = 1:4
    switch dat
        case 1
            data = Data.Session0.SEP_spr;
        case 2
            data = Data.Session0.SEP_thr;
        case 3
            data = Data.Session1.SEP_spr;
        case 4 
            data = Data.Session1.SEP_thr;
    end
    del = [];
    for row = 1:size(data,1)
        if all(data(row,:) == 0); del = [del, row]; end
    end
    data(del,:) = [];
    line(dat)=plot(plot_times, mean(data,1) ,'Color',sep_colours{dat},'Linewidth',2,'Linestyle',sep_lines(dat));
    %make standard error
    SE_upper=[];SE_lower=[];
    for i=1:length(plot_times)
        se = std(squeeze(data(:,i)))./sqrt(length(squeeze(data(:,i))));
        SE_upper(i) = mean(data(:,i))+se;
        SE_lower(i) = mean(data(:,i))-se;
    end
    tempx = [plot_times,fliplr(plot_times)];
    tempy = [SE_upper,fliplr(SE_lower)];
    A = fill(tempx,tempy,'k');
    A.EdgeColor = 'none';
    A.FaceColor = sep_colours{dat};
    A.FaceAlpha = .1;
end
y=ylim();
line(dat+1) = plot([0,0],[y],'-','Color',[.8 .8 .8]); 
legend(line,sep_titles,'Location','NorthWest')  
xlim([-50,300])
ylabel('Amplitude(μV)')
xlabel('Time(ms)')
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'SEP');
print(tempfig,"-dpng",'tempfig2');Imageslide = Picture('tempfig2.png');
replace(slide,"Content",Imageslide);

%% --- PURE TEPs ---
tep_colours = {'k','k'};
tep_lines = ['-',':'];
tep_titles = {'TEP1','TEP0','pulse'};

tempfig = figure;
hold on
title('TEPs')
line = [];
for dat = 1:2
    switch dat
        case 1
            data = Data.Session1.TEP_pure;
        case 2
            data = Data.Session0.TEP_pure;
    end
    del = [];
    for row = 1:size(data,1)
        if all(data(row,:) == 0); del = [del, row]; end
    end
    data(del,:) = [];
    line(dat)=plot(plot_times, mean(data,1) ,'Color',tep_colours{dat},'Linewidth',2,'Linestyle',tep_lines(dat));
    %make standard error
    SE_upper=[];SE_lower=[];
    for i=1:length(plot_times)
        se = std(squeeze(data(:,i)))./sqrt(length(squeeze(data(:,i))));
        SE_upper(i) = mean(data(:,i))+se;
        SE_lower(i) = mean(data(:,i))-se;
    end
    tempx = [plot_times,fliplr(plot_times)];
    tempy = [SE_upper,fliplr(SE_lower)];
    A = fill(tempx,tempy,'k');
    A.EdgeColor = 'none';
    A.FaceColor = tep_colours{dat};
    A.FaceAlpha = .1;
end
y=ylim();
line(dat+1) = plot([0,0],[y],'--','Color',[.8 .8 .8]); 
legend(line,tep_titles,'Location','NorthWest')  
xlim([-50,300])
ylabel('Amplitude(μV)')
xlabel('Time(ms)')
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'TEP');
print(tempfig,"-dpng",'tempfig3');Imageslide = Picture('tempfig3.png');
replace(slide,"Content",Imageslide);
            

%% --- 100 ---
tep100_colours = {[178,34,34]./255,[0,0,128]./255,[178,34,34]./255,[0,0,128]./255};
tep100_lines = [':',':','-','-'];
tep100_titles = {'tep100supra0','tep100threshold0','tep100supra1','tep100threshold1', 'tap','pulse'};

tempfig = figure;
hold on
title('TEP 100ms')
for dat = 1:4
    switch dat
        case 1
            data = Data.Session0.TEP_100_spr;
        case 2
            data = Data.Session0.TEP_100_thr;
        case 3
            data = Data.Session1.TEP_100_spr;
        case 4 
            data = Data.Session1.TEP_100_thr;
    end
    del = [];
    for row = 1:size(data,1)
        if all(data(row,:) == 0); del = [del, row]; end
    end
    data(del,:) = [];
    line(dat)=plot(plot_times, mean(data,1) ,'Color',tep100_colours{dat},'Linewidth',2,'Linestyle',tep100_lines(dat));
    %make standard error
    SE_upper=[];SE_lower=[];
    for i=1:length(plot_times)
        se = std(squeeze(data(:,i)))./sqrt(length(squeeze(data(:,i))));
        SE_upper(i) = mean(data(:,i))+se;
        SE_lower(i) = mean(data(:,i))-se;
    end
    tempx = [plot_times,fliplr(plot_times)];
    tempy = [SE_upper,fliplr(SE_lower)];
    A = fill(tempx,tempy,'k');
    A.EdgeColor = 'none';
    A.FaceColor = tep100_colours{dat};
    A.FaceAlpha = .1;
end
y=ylim();
line(dat+1) = plot([0,0],[y],'-','Color',[.8 .8 .8]);      
line(dat+2) = plot([-100,-100],[y],'--','Color',[.8 .8 .8]) ;   
legend(line,tep100_titles,'Location','SouthEast') 
xlim([-150,300])
ylabel('Amplitude(μV)')
xlabel('Time(ms)')
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'TEP 100');
print(tempfig,"-dpng",'tempfig4');Imageslide = Picture('tempfig4.png');
replace(slide,"Content",Imageslide);
            

%% --- 25 ---
tep25_colours = {[178,34,34]./255,[0,0,128]./255,[178,34,34]./255,[0,0,128]./255};
tep25_lines = [':',':','-','-'];
tep25_titles = {'tep25supra0','tep25threshold0','tep25supra1','tep25threshold1','tap','pulse'};


tempfig = figure;
hold on
title('TEP 25ms')
for dat = 1:4
    switch dat
        case 1
            data = Data.Session0.TEP_25_spr;
        case 2
            data = Data.Session0.TEP_25_thr;
        case 3
            data = Data.Session1.TEP_25_spr;
        case 4 
            data = Data.Session1.TEP_25_thr;
    end
    del = [];
    for row = 1:size(data,1)
        if all(data(row,:) == 0); del = [del, row]; end
    end
    data(del,:) = [];
    line(dat)=plot(plot_times, mean(data,1) ,'Color',tep25_colours{dat},'Linewidth',2,'Linestyle',tep25_lines(dat));
    %make standard error
    SE_upper=[];SE_lower=[];
    for i=1:length(plot_times)
        se = std(squeeze(data(:,i)))./sqrt(length(squeeze(data(:,i))));
        SE_upper(i) = mean(data(:,i))+se;
        SE_lower(i) = mean(data(:,i))-se;
    end
    tempx = [plot_times,fliplr(plot_times)];
    tempy = [SE_upper,fliplr(SE_lower)];
    A = fill(tempx,tempy,'k');
    A.EdgeColor = 'none';
    A.FaceColor = tep25_colours{dat};
    A.FaceAlpha = .1;
end
y=ylim();
line(dat+1) = plot([0,0],[y],'-','Color',[.8 .8 .8]);         
line(dat+2) = plot([25,25],[y],'--','Color',[.8 .8 .8]);    
legend(line,tep25_titles,'Location','SouthEast')  
xlim([-50,300])
ylabel('Amplitude(μV)')
xlabel('Time(ms)')
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'TEP 25');
print(tempfig,"-dpng",'tempfig5');Imageslide = Picture('tempfig5.png');
replace(slide,"Content",Imageslide);
            
close(ppt)
delete tempfig1.png tempfig2.png tempfig3.png tempfig4.png tempfig5.png          
close all           
            
            
    