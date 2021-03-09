%% Get ERPs
clear
close all

partic = 2;

% load eeglab
eeglab_dir='C:\Users\ckohl\Documents\MATLAB\eeglab2020_0';
cd(eeglab_dir)
eeglab

%load data (cleaned  continuous from Preprocessing.m)
partic_str = sprintf('%02d', partic);
filedir = strcat('C:\Users\ckohl\Desktop\Data\Pilot\Beta',partic_str);
cd(filedir)
filename = strcat(partic_str,'_clean.set');
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename',filename,'filepath',filedir);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
EEG = eeg_checkset( EEG );
eeglab redraw

%set up ppt
out_dir =  strcat(filedir,'\Preproc\');
cd(out_dir)
import mlreportgen.ppt.*
ppt = Presentation(strcat('Beta',partic_str,'-ERPs'));
open(ppt);
titleSlide = add(ppt,'Title Slide');
replace(titleSlide,"Title",strcat('Beta',partic_str,'-  Individual ERPs.m'));

% get data properties
dt=EEG.srate/1000;
electr_oi='C3';
channels = EEG.chanlocs;
EOG = [64,65];

%find electrode oi
for chan= 1:length(EEG.chanlocs)
    if length(EEG.chanlocs(chan).labels)==2
        if EEG.chanlocs(chan).labels==electr_oi
            electr_oi_i=chan;
        end
    end
end

% define events
tap_og = 'S  1';
tms_og = 'S  2';
cuehand_og = 'S  4';
cuehead_og = 'S  8';
respcue_og = 'S 16';
% new events: 'T/Z' - TapCond - TMSCond
tap = {'T_10','T_11','T_12','T_20','T_21','T_22'};
tms = {'Z_01','Z_11','Z_21','Z_02','Z_12','Z_22'};
%also: Trials
colours ={[240,128,128]./255,[70,130,180]./255,[.2 .2 .2],[178,34,34]./255,[0,0,128]./255};
colours_lbl = {'supra','threshold','tep','tepsupra','tepthresh'};
yl = [-8 4];










%% - pure SEPs -
%threshold
SEP1 = pop_epoch( EEG, {tap{1}}, [-.2 .3], 'epochinfo', 'yes');
SEP1 = pop_rmbase(SEP1, [-200   0]);
%supra
SEP2 = pop_epoch( EEG, {tap{4}}, [-.2 .3], 'epochinfo', 'yes');
SEP2 = pop_rmbase(SEP2, [-200   0]);

tempfig = figure;
line=[];
hold on
title('Pure SEP')
ylim(yl)
time = SEP1.times;
data = SEP1.data(electr_oi_i,:,:);
line(1)=plot(time, mean(data,3) ,'Color',colours{2},'Linewidth',2);
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
    A.FaceAlpha=.2;

time = SEP2.times;
data = SEP2.data(electr_oi_i,:,:);
line(2)=plot(time, mean(data,3) ,'Color',colours{1},'Linewidth',2);
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
    A.FaceAlpha=.2;
y=ylim();
line(3)=plot([0,0],[y],'-','Color',[.8 .8 .8]) ;
legend(line,strcat('threshold (', num2str(size(SEP1.data,3)),')'),...
       strcat('supra (', num2str(size(SEP2.data,3)),')'), 'tap time');
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'SEP');
print(tempfig,"-dpng",'tempfig1');Imageslide = Picture('tempfig1.png');
replace(slide,"Content",Imageslide);close(tempfig);
     
%% - pure TEPs -
%25 and 100 combined
TEP1 = pop_epoch( EEG, {tms{1}, tms{4}}, [-.2 .3], 'epochinfo', 'yes');
TEP1 = pop_rmbase(TEP1, [-200   -50]);

tempfig=figure;
hold on
line=[];
ylim(yl)
title('Pure TEP')
time = TEP1.times;
data = TEP1.data(electr_oi_i,:,:);
line(1)=plot(time, mean(data,3) ,'Color',colours{3},'Linewidth',2);
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
    A.FaceColor=colours{3};
    A.FaceAlpha=.2;
y=ylim();
line(2)=plot([0,0],[y],'--','Color',[.8 .8 .8]) ;    
legend(line, strcat('TEP (', num2str(size(TEP1.data,3)),')'),'tms time');   
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'TEP');
print(tempfig,"-dpng",'tempfig2');Imageslide = Picture('tempfig2.png');
replace(slide,"Content",Imageslide);close(tempfig);




%% - SEPs 100ms after pulse -
%threshold
SEP1 = pop_epoch( EEG, {tap{2}}, [-.2 .3], 'epochinfo', 'yes');
SEP1 = pop_rmbase(SEP1, [-200   0]);
%supra
SEP2 = pop_epoch( EEG, {tap{5}}, [-.2 .3], 'epochinfo', 'yes');
SEP2 = pop_rmbase(SEP2, [-200   0]);

tempfig=figure;
ylim(yl)
line=[];
hold on
title('SEP 100ms after Pulse')
time = SEP1.times;
data = SEP1.data(electr_oi_i,:,:);
line(1)=plot(time, mean(data,3) ,'Color',colours{5},'Linewidth',2);
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
    A.FaceColor=colours{5};
    A.FaceAlpha=.2;
    
time = SEP2.times;
data = SEP2.data(electr_oi_i,:,:);
line(2)=plot(time, mean(data,3) ,'Color',colours{4},'Linewidth',2);
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
    A.FaceColor=colours{4};
    A.FaceAlpha=.2;    
y=ylim();
line(3)=plot([0,0],[y],'-','Color',[.8 .8 .8])  ;      
line(4)=plot([-100,-100],[y],'--','Color',[.8 .8 .8]) ;   
legend(line,strcat('threshold (', num2str(size(SEP1.data,3)),')'),...
       strcat('supra (', num2str(size(SEP2.data,3)),')'),'tap time','tms time');
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'TEP-SEP');
print(tempfig,"-dpng",'tempfig3');Imageslide = Picture('tempfig3.png');
replace(slide,"Content",Imageslide);close(tempfig);


%% 25ms complex
%locked to tap, but locked to TEP would be no different (only diff in time)
%threshtap
SEP1 = pop_epoch( EEG, {tap{3}}, [-.2 .3], 'epochinfo', 'yes');
SEP1 = pop_rmbase(SEP1, [-200   0]);
%supra
SEP2 = pop_epoch( EEG, {tap{6}}, [-.2 .3], 'epochinfo', 'yes');
SEP2 = pop_rmbase(SEP2, [-200   0]);

tempfig = figure;
line=[];
ylim(yl)
hold on
title('SEP-TEP (25ms)')

time = SEP1.times;
data = SEP1.data(electr_oi_i,:,:);
line(1)=plot(time, mean(data,3) ,'Color',colours{5},'Linewidth',2);
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
    A.FaceColor=colours{5};
    A.FaceAlpha=.2;

time = SEP2.times;
data = SEP2.data(electr_oi_i,:,:);
line(2)=plot(time, mean(data,3) ,'Color',colours{4},'Linewidth',2);
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
    A.FaceColor=colours{4};
    A.FaceAlpha=.2;
y=ylim();
line(3)=plot([0,0],[y],'-','Color',[.8 .8 .8]) ;         
line(4)=plot([25,25],[y],'--','Color',[.8 .8 .8])   ;     
legend(line,strcat('threshold (', num2str(size(SEP1.data,3)),')'),...
       strcat('supra (', num2str(size(SEP2.data,3)),')'),'tap time','tms time');
%ppt
slide = add(ppt,"Title and Content");replace(slide,"Title",'SEP-TEP');
print(tempfig,"-dpng",'tempfig4');Imageslide = Picture('tempfig4.png');
replace(slide,"Content",Imageslide);close(tempfig);

close(ppt)
delete tempfig1.png tempfig2.png tempfig3.png tempfig4.png