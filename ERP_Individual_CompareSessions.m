%% Get ERPs
clear
close all

partic = 9;
partic_str = sprintf('%02d', partic);
% load eeglab
eeglab_dir='C:\Users\ckohl\Documents\MATLAB\eeglab2020_0';
cd(eeglab_dir)
eeglab


%set up ppt
out_dir =  strcat('C:\Users\ckohl\Desktop\Data\BETA',partic_str);
cd(out_dir)
import mlreportgen.ppt.*
ppt = Presentation(strcat('Beta',partic_str,'-ERPs across Sessions'));
open(ppt);
titleSlide = add(ppt,'Title Slide');
replace(titleSlide,"Title",strcat('Beta',partic_str,'-  Individual ERPs.m'));


% define events
tap_og = 'S  1';
tms_og = 'S  2';
cuehand_og = 'S  4';
cuehead_og = 'S  8';
respcue_og = 'S 16';
% new events: 'T/Z' - TapCond - TMSCond
tap = {'T_10','T_11','T_12','T_20','T_21','T_22'};
tms = {'Z_01','Z_11','Z_21','Z_02','Z_12','Z_22'};


%load S1Loc data (cleaned  continuous from Preporcessing_S1Loc.m)
filedir = strcat('C:\Users\ckohl\Desktop\Data\Beta',partic_str,'\Session1');
cd(filedir)
filename = strcat(partic_str,'_S1Loc_Pre_clean.set');
EEG = pop_loadset('filename',filename,'filepath',filedir);
EEG = eeg_checkset( EEG );
Session1_Pre = EEG;

filename = strcat(partic_str,'_S1Loc_Post_clean.set');
EEG = pop_loadset('filename',filename,'filepath',filedir);
EEG = eeg_checkset( EEG );
Session1_Post = EEG;

filedir = strcat('C:\Users\ckohl\Desktop\Data\Beta',partic_str,'\Session0');
cd(filedir)
filename = strcat(partic_str,'_S1Loc_Pre_clean.set');
EEG = pop_loadset('filename',filename,'filepath',filedir);
EEG = eeg_checkset( EEG );
Session0_Pre = EEG;

filename = strcat(partic_str,'_S1Loc_Post_clean.set');
EEG = pop_loadset('filename',filename,'filepath',filedir);
EEG = eeg_checkset( EEG );
Session0_Post = EEG;


colours = {[0 0 128]./255,[135,206,235]./255, [70,130,180]./255};
tempfig = figure; 
hold on

PRE0 = pop_epoch( Session0_Pre, {tap_og}, [-.1 .25], 'epochinfo', 'yes');
PRE0 = pop_rmbase(PRE0, [-100   -0]);
PRE1 = pop_epoch( Session1_Pre, {tap_og}, [-.1 .25], 'epochinfo', 'yes');
PRE1 = pop_rmbase(PRE1, [-100   -0]);
PRE = pop_mergeset(PRE0,PRE1);

% get data properties
dt=EEG.srate/1000;
electr_oi='C3';
    
channels = EEG.chanlocs;
EOG = [64,65];

%find electrode oi
for chan= 1:length(EEG.chanlocs)
    if length(EEG.chanlocs(chan).labels)==length(electr_oi)
        if EEG.chanlocs(chan).labels==electr_oi
            electr_oi_i=chan;
        end
    end
end

line=[];

title('S1 Loc')
time = PRE.times;
data = PRE.data(electr_oi_i,:,:);
line(1)=plot(time, mean(data,3) ,'Color',colours{1},'Linewidth',2);
%make standard error
    SE_upper=[];SE_lower=[];
    for i=1:length(time)
        se=std(squeeze(data(:,i,:)))./sqrt(length(squeeze(data(:,i,:))));
        SE_upper(i)=mean(data(:,i,:))+se;
        SE_lower(i)=mean(data(:,i,:))-se;
    end
    tempx=[time,fliplr(time)];
    tempy=[SE_upper,fliplr(SE_lower)];
    A=fill(tempx,tempy,'k');
    A.EdgeColor='none';
    A.FaceColor=colours{1};
    A.FaceAlpha=.1;
    
POST0 = pop_epoch( Session0_Pre, {tap_og}, [-.1 .25], 'epochinfo', 'yes');
POST0 = pop_rmbase(POST0, [-100   -0]);
title('S1 Loc')
time = POST0.times;
data = POST0.data(electr_oi_i,:,:);
line(2)=plot(time, mean(data,3) ,'Color',colours{2},'Linewidth',2);
%make standard error
    SE_upper=[];SE_lower=[];
    for i=1:length(time)
        se=std(squeeze(data(:,i,:)))./sqrt(length(squeeze(data(:,i,:))));
        SE_upper(i)=mean(data(:,i,:))+se;
        SE_lower(i)=mean(data(:,i,:))-se;
    end
    tempx=[time,fliplr(time)];
    tempy=[SE_upper,fliplr(SE_lower)];
    A=fill(tempx,tempy,'k');
    A.EdgeColor='none';
    A.FaceColor=colours{2};
    A.FaceAlpha=.1;

    
POST1 = pop_epoch( Session1_Pre, {tap_og}, [-.1 .25], 'epochinfo', 'yes');
POST1 = pop_rmbase(POST1, [-100   -0]);
title('S1 Loc')
time = POST1.times;
data = POST1.data(electr_oi_i,:,:);
line(3)=plot(time, mean(data,3) ,'Color',colours{3},'Linewidth',2);
%make standard error
    SE_upper=[];SE_lower=[];
    for i=1:length(time)
        se=std(squeeze(data(:,i,:)))./sqrt(length(squeeze(data(:,i,:))));
        SE_upper(i)=mean(data(:,i,:))+se;
        SE_lower(i)=mean(data(:,i,:))-se;
    end
    tempx=[time,fliplr(time)];
    tempy=[SE_upper,fliplr(SE_lower)];
    A=fill(tempx,tempy,'k');
    A.EdgeColor='none';
    A.FaceColor=colours{2};
    A.FaceAlpha=.1;
    
y=ylim();
plot([0,0],[y],':','Color',[.8 .8 .8]) ;    
legend(line, {strcat('PRE (',num2str(size(PRE.data,3)),')'),...
            strcat('POST0 (',num2str(size(POST0.data,3)),')'),...
            strcat('POST1 (',num2str(size(POST1.data,3)),')')});
      
ylabel('Amplitude')
xlabel('Time')

%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'SEP');
print(tempfig,"-dpng",'tempfig1');Imageslide = Picture('tempfig1.png');
replace(slide,"Content",Imageslide);

% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %load data (cleaned  continuous from Preprocessing.m)
% partic_str = sprintf('%02d', partic);
% filedir = strcat('C:\Users\ckohl\Desktop\Data\Beta',partic_str,'\Session1');
% cd(filedir)
% filename = strcat(partic_str,'_clean.set');
% [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
% EEG = pop_loadset('filename',filename,'filepath',filedir);
% [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
% EEG = eeg_checkset( EEG );
% Session1 = EEG;
% filedir = strcat('C:\Users\ckohl\Desktop\Data\Beta',partic_str,'\Session0');
% cd(filedir)
% filename = strcat(partic_str,'_clean.set');
% [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
% EEG = pop_loadset('filename',filename,'filepath',filedir);
% [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
% EEG = eeg_checkset( EEG );
% Session0 = EEG;
% 
% % get data properties
% dt=EEG.srate/1000;
% electr_oi='C3';
%     
% channels = EEG.chanlocs;
% EOG = [64,65];
% 
% %find electrode oi
% for chan= 1:length(EEG.chanlocs)
%     if length(EEG.chanlocs(chan).labels)==length(electr_oi)
%         if EEG.chanlocs(chan).labels==electr_oi
%             electr_oi_i=chan;
%         end
%     end
% end
% 
% %also: Trials
% colours ={[240,128,128]./255,[70,130,180]./255,[.2 .2 .2],[178,34,34]./255,[0,0,128]./255};
% colours_lbl = {'supra','threshold','tep','tepsupra','tepthresh'};
% yl = [-8 4];
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% %% - pure SEPs -
% %threshold
% SEP1 = pop_epoch( EEG, {tap{1}}, [-.2 .3], 'epochinfo', 'yes');
% SEP1 = pop_rmbase(SEP1, [-200   0]);
% %supra
% SEP2 = pop_epoch( EEG, {tap{4}}, [-.2 .3], 'epochinfo', 'yes');
% SEP2 = pop_rmbase(SEP2, [-200   0]);
% 
% tempfig = figure;
% line=[];
% hold on
% title('Pure SEP')
% ylim(yl)
% time = SEP2.times;
% data = SEP2.data(electr_oi_i,:,:);
% line(2)=plot(time, mean(data,3) ,'Color',colours{1},'Linewidth',2);
% %make standard error
%     SE_upper=[];SE_lower=[];
%     for i=1:length(time)
%         se=std(squeeze(data(:,i,:)))./sqrt(length(squeeze(data(:,i,:))));
%         SE_upper(i)=mean(data(:,i,:))+se;
%         SE_lower(i)=mean(data(:,i,:))-se;
%     end
%     tempx=[time,fliplr(time)];
%     tempy=[SE_upper,fliplr(SE_lower)];
%     A=fill(tempx,tempy,'k');
%     A.EdgeColor='none';
%     A.FaceColor=colours{1};
%     A.FaceAlpha=.2;
% y=ylim();
% time = SEP1.times;
% data = SEP1.data(electr_oi_i,:,:);
% line(1)=plot(time, mean(data,3) ,'Color',colours{2},'Linewidth',2);
% %make standard error
%     SE_upper=[];SE_lower=[];
%     for i=1:length(time)
%         se=std(squeeze(data(:,i,:)))./sqrt(length(squeeze(data(:,i,:))));
%         SE_upper(i)=mean(data(:,i,:))+se;
%         SE_lower(i)=mean(data(:,i,:))-se;
%     end
%     tempx=[time,fliplr(time)];
%     tempy=[SE_upper,fliplr(SE_lower)];
%     A=fill(tempx,tempy,'k');
%     A.EdgeColor='none';
%     A.FaceColor=colours{2};
%     A.FaceAlpha=.2;
% line(3)=plot([0,0],[y],'-','Color',[.8 .8 .8]) ;
% legend(line,strcat('threshold (', num2str(size(SEP1.data,3)),')'),...
%        strcat('supra (', num2str(size(SEP2.data,3)),')'), 'tap time');
% %ppt
% slide = add(ppt,"Title and Content");replace(slide,"Title",'SEP');
% print(tempfig,"-dpng",'tempfig1');Imageslide = Picture('tempfig1.png');
% replace(slide,"Content",Imageslide);
% xlim([-10 200])
% slide = add(ppt,"Title and Content");replace(slide,"Title",'SEP');
% print(tempfig,"-dpng",'tempfig2');Imageslide = Picture('tempfig2.png');
% replace(slide,"Content",Imageslide);
%      
% %% - pure TEPs -
% %25 and 100 combined
% TEP1 = pop_epoch( EEG, {tms{1}, tms{4}}, [-.2 .3], 'epochinfo', 'yes');
% TEP1 = pop_rmbase(TEP1, [-200   -50]);
% 
% tempfig=figure;
% hold on
% line=[];
% ylim(yl)
% title('Pure TEP')
% time = TEP1.times;
% data = TEP1.data(electr_oi_i,:,:);
% line(1)=plot(time, mean(data,3) ,'Color',colours{3},'Linewidth',2);
% %make standard error
%     SE_upper=[];SE_lower=[];
%     for i=1:length(time)
%         se=std(squeeze(data(:,i,:)))./sqrt(length(squeeze(data(:,i,:))));
%         SE_upper(i)=mean(data(:,i,:))+se;
%         SE_lower(i)=mean(data(:,i,:))-se;
%     end
%     tempx=[time,fliplr(time)];
%     tempy=[SE_upper,fliplr(SE_lower)];
%     A=fill(tempx,tempy,'k');
%     A.EdgeColor='none';
%     A.FaceColor=colours{3};
%     A.FaceAlpha=.2;
% y=ylim();
% line(2)=plot([0,0],[y],'--','Color',[.8 .8 .8]) ;    
% legend(line, strcat('TEP (', num2str(size(TEP1.data,3)),')'),'tms time');   
% %ppt
% slide = add(ppt,"Title and Content");replace(slide,"Title",'TEP');
% print(tempfig,"-dpng",'tempfig3');Imageslide = Picture('tempfig3.png');
% replace(slide,"Content",Imageslide);
% 
% 
% 
% 
% %% - SEPs 100ms after pulse -
% %threshold
% SEP1 = pop_epoch( EEG, {tap{2}}, [-.2 .3], 'epochinfo', 'yes');
% SEP1 = pop_rmbase(SEP1, [-200   0]);
% %supra
% SEP2 = pop_epoch( EEG, {tap{5}}, [-.2 .3], 'epochinfo', 'yes');
% SEP2 = pop_rmbase(SEP2, [-200   0]);
% 
% tempfig=figure;
% ylim(yl)
% line=[];
% hold on
% title('SEP 100ms after Pulse')
% time = SEP1.times;
% data = SEP1.data(electr_oi_i,:,:);
% line(1)=plot(time, mean(data,3) ,'Color',colours{5},'Linewidth',2);
% %make standard error
%     SE_upper=[];SE_lower=[];
%     for i=1:length(time)
%         se=std(squeeze(data(:,i,:)))./sqrt(length(squeeze(data(:,i,:))));
%         SE_upper(i)=mean(data(:,i,:))+se;
%         SE_lower(i)=mean(data(:,i,:))-se;
%     end
%     tempx=[time,fliplr(time)];
%     tempy=[SE_upper,fliplr(SE_lower)];
%     A=fill(tempx,tempy,'k');
%     A.EdgeColor='none';
%     A.FaceColor=colours{5};
%     A.FaceAlpha=.2;
%     
% time = SEP2.times;
% data = SEP2.data(electr_oi_i,:,:);
% line(2)=plot(time, mean(data,3) ,'Color',colours{4},'Linewidth',2);
% %make standard error
%     SE_upper=[];SE_lower=[];
%     for i=1:length(time)
%         se=std(squeeze(data(:,i,:)))./sqrt(length(squeeze(data(:,i,:))));
%         SE_upper(i)=mean(data(:,i,:))+se;
%         SE_lower(i)=mean(data(:,i,:))-se;
%     end
%     tempx=[time,fliplr(time)];
%     tempy=[SE_upper,fliplr(SE_lower)];
%     A=fill(tempx,tempy,'k');
%     A.EdgeColor='none';
%     A.FaceColor=colours{4};
%     A.FaceAlpha=.2;    
% y=ylim();
% line(3)=plot([0,0],[y],'-','Color',[.8 .8 .8])  ;      
% line(4)=plot([-100,-100],[y],'--','Color',[.8 .8 .8]) ;   
% legend(line,strcat('threshold (', num2str(size(SEP1.data,3)),')'),...
%        strcat('supra (', num2str(size(SEP2.data,3)),')'),'tap time','tms time');
% %ppt
% slide = add(ppt,"Title and Content");replace(slide,"Title",'TEP-SEP');
% print(tempfig,"-dpng",'tempfig4');Imageslide = Picture('tempfig4.png');
% replace(slide,"Content",Imageslide);
% 
% 
% %% 25ms complex
% %locked to tap, but locked to TEP would be no different (only diff in time)
% %threshtap
% SEP1 = pop_epoch( EEG, {tap{3}}, [-.2 .3], 'epochinfo', 'yes');
% SEP1 = pop_rmbase(SEP1, [-200   0]);
% %supra
% SEP2 = pop_epoch( EEG, {tap{6}}, [-.2 .3], 'epochinfo', 'yes');
% SEP2 = pop_rmbase(SEP2, [-200   0]);
% 
% tempfig = figure;
% line=[];
% ylim(yl)
% hold on
% title('SEP-TEP (25ms)')
% 
% time = SEP1.times;
% data = SEP1.data(electr_oi_i,:,:);
% line(1)=plot(time, mean(data,3) ,'Color',colours{5},'Linewidth',2);
% %make standard error
%     SE_upper=[];SE_lower=[];
%     for i=1:length(time)
%         se=std(squeeze(data(:,i,:)))./sqrt(length(squeeze(data(:,i,:))));
%         SE_upper(i)=mean(data(:,i,:))+se;
%         SE_lower(i)=mean(data(:,i,:))-se;
%     end
%     tempx=[time,fliplr(time)];
%     tempy=[SE_upper,fliplr(SE_lower)];
%     A=fill(tempx,tempy,'k');
%     A.EdgeColor='none';
%     A.FaceColor=colours{5};
%     A.FaceAlpha=.2;
% 
% time = SEP2.times;
% data = SEP2.data(electr_oi_i,:,:);
% line(2)=plot(time, mean(data,3) ,'Color',colours{4},'Linewidth',2);
% %make standard error
%     SE_upper=[];SE_lower=[];
%     for i=1:length(time)
%         se=std(squeeze(data(:,i,:)))./sqrt(length(squeeze(data(:,i,:))));
%         SE_upper(i)=mean(data(:,i,:))+se;
%         SE_lower(i)=mean(data(:,i,:))-se;
%     end
%     tempx=[time,fliplr(time)];
%     tempy=[SE_upper,fliplr(SE_lower)];
%     A=fill(tempx,tempy,'k');
%     A.EdgeColor='none';
%     A.FaceColor=colours{4};
%     A.FaceAlpha=.2;
% y=ylim();
% line(3)=plot([0,0],[y],'-','Color',[.8 .8 .8]) ;         
% line(4)=plot([25,25],[y],'--','Color',[.8 .8 .8])   ;     
% legend(line,strcat('threshold (', num2str(size(SEP1.data,3)),')'),...
%        strcat('supra (', num2str(size(SEP2.data,3)),')'),'tap time','tms time');
% %ppt
% slide = add(ppt,"Title and Content");replace(slide,"Title",'SEP-TEP');
% print(tempfig,"-dpng",'tempfig5');Imageslide = Picture('tempfig5.png');
% replace(slide,"Content",Imageslide);
% 
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if session ==0%, also plot TMS electrode
% 
% 
%     %% - pure TEPs -
%     %25 and 100 combined
%     TEP1 = pop_epoch( EEG, {tms{1}, tms{4}}, [-.2 .3], 'epochinfo', 'yes');
%     TEP1 = pop_rmbase(TEP1, [-200   -50]);
% 
%     tempfig=figure;
%     hold on
%     line=[];
%     ylim(yl)
%     title('Pure TEP')
%     time = TEP1.times;
%     data = TEP1.data(electr_oi_i2,:,:);
%     line(1)=plot(time, mean(data,3) ,'Color',colours{3},'Linewidth',2);
%     %make standard error
%         SE_upper=[];SE_lower=[];
%         for i=1:length(time)
%             se=std(squeeze(data(:,i,:)))./sqrt(length(squeeze(data(:,i,:))));
%             SE_upper(i)=mean(data(:,i,:))+se;
%             SE_lower(i)=mean(data(:,i,:))-se;
%         end
%         tempx=[time,fliplr(time)];
%         tempy=[SE_upper,fliplr(SE_lower)];
%         A=fill(tempx,tempy,'k');
%         A.EdgeColor='none';
%         A.FaceColor=colours{3};
%         A.FaceAlpha=.2;
%     y=ylim();
%     line(2)=plot([0,0],[y],'--','Color',[.8 .8 .8]) ;    
%     legend(line, strcat('TEP (', num2str(size(TEP1.data,3)),')'),'tms time');   
%     %ppt
%     slide = add(ppt,"Title and Content");replace(slide,"Title",'TEP - TMS Electrode');
%     print(tempfig,"-dpng",'tempfig6');Imageslide = Picture('tempfig6.png');
%     replace(slide,"Content",Imageslide);
% end

close(ppt)
delete tempfig1.png %tempfig2.png tempfig3.png tempfig4.png tempfig5.png tempfig6.png
