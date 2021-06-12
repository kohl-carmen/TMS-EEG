function EEG = Preprocessing_S1Loc_Post_2(partic,session,EEG,rej,out_dir, PRE)
%% TMS-EEG Preprocessing - March 2021
% based on TEP_preproc.m  & TEP_preproc_single.m
% keeps data continuous

% SETUP
% EVENTS
% TMS ARTIFACT 
%     - **interpolate pulse** (linear) - had issues with cubic
%     - median filter recharge
% PREPROC 
%     - downsample (10 -> 1kHz)
%     - filter (4,100)
%     - break reject
%     - **ICA (blinks only)**
%     - **art reject**
%     - interpolate
%     - rereference
%                         **manual steps

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_dir = cd;
partic_str = sprintf('%02d', partic);
out_txt = fopen(strcat(out_dir,partic_str,'_s1loc'), 'a');
%set up ppt
cd(out_dir)
import mlreportgen.ppt.*
ppt = Presentation(strcat('Beta',partic_str,'-S1Loc'));
open(ppt);
titleSlide = add(ppt,'Title Slide');
replace(titleSlide,"Title",strcat('Beta',partic_str,'- S1Loc.m'));

EOG = [64,65];
electr_oi='C3';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% POST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get data properties
dt=EEG.srate/1000;
channels = EEG.chanlocs;
EOG = [64,65];
tap = 'S  1';

%find electrode oi
for chan= 1:length(EEG.chanlocs)
    if length(EEG.chanlocs(chan).labels)==length(electr_oi)
        if EEG.chanlocs(chan).labels==electr_oi
            electr_oi_i=chan;
        end
    end
end

EEG = eeg_checkset( EEG );

% save rejection
txt = sprintf('Manual Artifact Rejection: %s\n',mat2str(rej));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
    
% save continuous but epoch to see whats left
SEP = pop_epoch( EEG, {tap}, [-.1 .4], 'epochinfo', 'yes');
txt = sprintf('%i clean SEPs left (-100 400, tap).\n', size(SEP.data,3));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)

% save
filedir = strcat('C:\Users\ckohl\Desktop\Data\BETA',partic_str,'\Session',num2str(session),'\');
EEG = eeg_checkset( EEG );
EEG = pop_saveset( EEG, 'filename',strcat(partic_str,'_S1Loc_Post_clean.set'),'filepath',filedir);

POST = EEG;
clear EEG

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
colours = {[0 0 128]./255,[0 128 128]./255, [70,130,180]./255};
tempfig = figure; 
hold on

PRE = pop_epoch( PRE, {tap}, [-.1 .25], 'epochinfo', 'yes');
PRE = pop_rmbase(PRE, [-100   -0]);
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
    A.FaceAlpha=.2;
    
POST = pop_epoch( POST, {tap}, [-.1 .25], 'epochinfo', 'yes');
POST = pop_rmbase(POST, [-100   -0]);
title('S1 Loc')
time = POST.times;
data = POST.data(electr_oi_i,:,:);
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
    A.FaceAlpha=.2;

% line(2)=plot([0,0],[y],'--','Color',[.8 .8 .8]) ;    
legend(line, {'PRE','POST'});

slide = add(ppt,"Title and Content"); replace(slide,"Title",'S1Loc - Pre v Post');
print(tempfig,"-dpng",'tempfig1');Imageslide = Picture('tempfig1.png');
replace(slide,"Content",Imageslide);%close(tempfig);


clf
hold on
COMB = pop_mergeset(PRE,POST);
COMB = pop_epoch( COMB, {tap}, [-.1 .25], 'epochinfo', 'yes');
COMB = pop_rmbase(COMB, [-100   -0]);
line=[];
title('S1 Loc')
time = COMB.times;
data = COMB.data(electr_oi_i,:,:);
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
    A.FaceAlpha=.2;
slide = add(ppt,"Title and Content");replace(slide,"Title",'S1Loc - Combined');
print(tempfig,"-dpng",'tempfig2');Imageslide = Picture('tempfig2.png');
replace(slide,"Content",Imageslide);%close(tempfig);





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%done
fclose('all');
close(ppt);
close all
delete tempfig1.png tempfig2.png
cd(init_dir)
