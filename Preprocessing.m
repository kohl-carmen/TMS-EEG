function [rej, common_trial_counter] = Preprocessing(partic, session, bad_trials)
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
% Recharge 
delay = 500;
recharge_zero_time = [-3 3];%artifact itself is short, but a bit variable, so cut out chunk - don't really care anyway

% load eeglab
eeglab_dir='C:\Users\ckohl\Documents\MATLAB\eeglab2020_0';
cd(eeglab_dir)
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%load data
partic_str = sprintf('%02d', partic);
filedir = strcat('C:\Users\ckohl\Desktop\Data\BETA',partic_str,'\Session',num2str(session),'\');
cd(filedir)
filename = dir('*.vhdr');
if length(filename) >1
    for i = 1:length(filename)
        if filename(i).name(end-8:end-5)=='Task'
            filename = filename(i)
            break
        end
    end
end
EEG = pop_loadbv(filedir, filename.name, [], []);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
EEG = eeg_checkset( EEG );
eeglab redraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define Conditions
%%%%%%%
% get data properties
dt=EEG.srate/1000;
channels = EEG.chanlocs;
EOG = [64,65];

% set up output
mkdir Preproc
out_dir =  strcat(filedir,'\Preproc\');
out_txt = fopen(strcat(out_dir,partic_str,'_preproc'), 'a');
fprintf(out_txt, '\r\n \r\n %s \n', datestr(now)); 

%set up ppt
cd(out_dir)
import mlreportgen.ppt.*
ppt = Presentation(strcat('Beta',partic_str,'-Preprocessing'));
open(ppt);
titleSlide = add(ppt,'Title Slide');
replace(titleSlide,"Title",strcat('Beta',partic_str,'- Preprocessing.m'));

if session==1
    electr_oi='C3';
else
    %find electr_oi
    pulse = pop_epoch( EEG, {  'S  2'  }, [-0.003       0.002], 'epochinfo', 'yes');
    pulse = max(mean(pulse.data,3)');
    [temp, maxi] = max(pulse);
    electr_oi = EEG.chanlocs(maxi).labels;
    txt = sprintf(' Electrode of interest: %s.\n',electr_oi);
    fprintf(out_txt, '%s\n ', txt); 
    fprintf('%s',txt)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EVENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% define events
tap = 'S  1';
tms = 'S  2';
cue1 = 'S  4';
cue2 = 'S  8';
respcue = 'S 16';

% delete boundaries
list=[];
for event = 1:length(EEG.event)
    if isnan(EEG.event(event).duration)
        list = [ list, event];
    end
end
EEG.event(list)=[];
txt = sprintf(' %i boundary events deleted.\n',length(list));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)

% check for random pulses (whenthe TMS is armed, we get a pulse - it's set
% to zero but we still get an event - delete those)
list = [];
for event = 1:length(EEG.event)-1
    if length(EEG.event(event).type) == length(tms)
        if EEG.event(event).type == tms
            lonely=0;
            if EEG.event(event+1).latency > EEG.event(event).latency +2000*dt
                if event == 1 
                    lonely = 1;
                elseif EEG.event(event-1).latency < ...
                       EEG.event(event).latency-2000*dt
                    lonely = 1;
                end
            end
            if lonely
                list = [list, event];
            end
        end
    end
end
EEG.event(list)=[];
txt = sprintf('%i lonely tms events deleted\n',length(list));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
txt = sprintf('\t%s\n',num2str(list));
fprintf(out_txt, '%s\n ', txt); 

% list what's left
count_triggers=[];
trigger_types={};
for event = 1:length(EEG.event)-1
    if ~any(ismember(EEG.event(event).type ,trigger_types))
        trigger_types{end+1}=EEG.event(event).type;
        count_triggers(end+1)=1;
    else
        for trig=1:length(trigger_types)
            if EEG.event(event).type(1:4) == trigger_types{trig}(1:4)
                count_triggers(trig)=count_triggers(trig)+1;
            end
        end
    end
end

txt = sprintf('Found a total of %i remaining events and %i types: \n',...
               length(EEG.event),length(trigger_types));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
for trig=1:length(trigger_types)
    txt = sprintf('\t %s (%i) \n', trigger_types{trig},...
                  count_triggers(trig));
    fprintf(out_txt, '%s\n ', txt); 
    fprintf('%s',txt)
end
    
%find electrode oi
for chan= 1:length(EEG.chanlocs)
    if length(EEG.chanlocs(chan).labels)==length(electr_oi)
        if EEG.chanlocs(chan).labels==electr_oi
            electr_oi_i=chan;
        end
    end
end

EEG = eeg_checkset( EEG );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% add events so that we can tell the condition by the event:
% T10 -> Tap event in condition: tap threshold, noTMS
% T11 -> Tap event in condition: tap threshold, TMS 100ms
% T12 -> Tap event in condition: tap threshold, TMS 25ms
% 
% T20 -> Tap event in condition: tap supra, noTMS
% T21 -> Tap event in condition: tap supra, TMS 100ms
% T22 -> Tap event in condition: tap supra, TMS 25ms 
% 
% Z01 -> TMS event in condition: tap null, TMS 100ms
% Z11 -> TMS event in condition: tap threshold, TMS 100ms
% Z21 -> TMS event in condition: tap supra, TMS 100ms
% 
% Z02 -> TMS event in condition: tap null, TMS 25ms 
% Z12 -> TMS event in condition: tap threshold, TMS 25ms 
% Z22 -> TMS event in condition: tap supra, TMS 25ms 


% also: % add trial numbers in events so we can alwys match back

% load beh
opts = delimitedTextImportOptions("NumVariables", 11);
opts.DataLines = [6, Inf];
opts.Delimiter = "\t";
opts.VariableNames = ["Trial", "CueCond", "TMSCond", "TapCond", "Accuracy", "YesResponse", "NoResponse", "TapTime", "TMSTime", "RT", "Threshold"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
try
    tbl = readtable(strcat(filedir,'\BETA',partic_str,'_results'), opts);
catch
    tbl = readtable(strcat(filedir,'\BETA_',partic_str,'_results'), opts);
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
Threshold = tbl.Threshold;
clear opts tbl

% find nr of trials  in EEG
count=0;
for event = 1:length(EEG.event)
    if length(EEG.event(event).type) == length(cue1)
        if EEG.event(event).type == cue1 | EEG.event(event).type == cue2
            count=count+1;
        end
    end
end       
% match trials
if length(Trial)~=count
    fprintf('Trials don''t match\n')
end
new_event = EEG.event; %new structure;
trial = 0;
for event = 1:length(EEG.event)
    if EEG.event(event).type == cue1 | EEG.event(event).type == cue2
        trial = trial +1;
        new_event(end+1) = EEG.event(event);
        new_event(end).type = strcat('Trial',num2str(trial));
        new_event(end).urevent=[];
        new_event(end).bvmknum=[];
        if TMSCond(trial)==1 %tms100
            if EEG.event(event+1).type==tms
                new_event(end+1) = EEG.event(event+1);
                new_event(end).type =strcat('Z_',num2str(TapCond(trial)),num2str(TMSCond(trial)));  
                new_event(end).urevent=[];
                new_event(end).bvmknum=[];
            else
                fprintf('ISSUE -1\n')
            end
            if TapCond(trial)>0 
                if EEG.event(event+2).type==tap
                    new_event(end+1) = EEG.event(event+2);
                    new_event(end).type =strcat('T_',num2str(TapCond(trial)),num2str(TMSCond(trial)));
                    new_event(end).urevent=[];
                    new_event(end).bvmknum=[];
                else
                    fprintf('ISSUE -2\n')
                end   
            end
        elseif TMSCond(trial)==2
            step=1;
            if TapCond(trial)>0
                if EEG.event(event+step).type==tap
                    new_event(end+1) = EEG.event(event+step);
                    new_event(end).type =strcat('T_',num2str(TapCond(trial)),num2str(TMSCond(trial)));   
                    new_event(end).urevent=[];
                    new_event(end).bvmknum=[];
                    step=step+1;
                else
                    fprintf('ISSUE -3\n')
                end
            end
            if EEG.event(event+step).type==tms
                new_event(end+1) = EEG.event(event+step);
                new_event(end).type =strcat('Z_',num2str(TapCond(trial)),num2str(TMSCond(trial))); 
                new_event(end).urevent=[];
                new_event(end).bvmknum=[];
            else
                fprintf('ISSUE -4\n')
            end
        elseif TMSCond(trial)==0
            if TapCond(trial)>0
                if EEG.event(event+1).type==tap
                    new_event(end+1) = EEG.event(event+1);
                    new_event(end).type =strcat('T_',num2str(TapCond(trial)),num2str(TMSCond(trial)));
                    new_event(end).urevent=[];
                    new_event(end).bvmknum=[];
                else
                    fprintf('ISSUE -5\n')
                end
            end
        end
    end
end
keep = EEG.event;
EEG.event = new_event ;     
EEG = eeg_checkset( EEG , 'eventconsistency');
           

% list all events after changes
count_triggers=[0];
trigger_types={'Trial'};
for event = 1:length(EEG.event)-1
    if EEG.event(event).type(1:3)=='Tri'
        count_triggers(1)=count_triggers(1)+1;
    else
        if ~any(ismember(EEG.event(event).type ,trigger_types))
            trigger_types{end+1}=EEG.event(event).type;
            count_triggers(end+1)=1;
        else
            for trig=1:length(trigger_types)
                if EEG.event(event).type(1:4) == trigger_types{trig}(1:4)
                    count_triggers(trig)=count_triggers(trig)+1;
                end
            end
        end
    end
end

txt = sprintf('After event manipulation, there are a total of %i remaining events and %i types: \n',...
               length(EEG.event),length(trigger_types));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
for trig=1:length(trigger_types)
    txt = sprintf('\t %s (%i) \n', trigger_types{trig},...
                  count_triggers(trig));
    fprintf(out_txt, '%s\n ', txt); 
    fprintf('%s',txt)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TMS ARTIFACT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EEG.data=EEG.data-EEG.data(:,1);
% epoch and plot pulse
pulse = pop_epoch( EEG, {tms}, [-.01 .01], 'epochinfo', 'yes');
pulse = pop_rmbase(pulse, [-10   0]);
pop_eegplot( pulse, 1, 1, 1);
tempfig = figure; 
pop_erpimage(pulse,1, [electr_oi_i],[[]],electr_oi,0,0,{},[],...
            '' ,'yerplabel','\muV','erp','on','limits',[-5 9.9] ,...
            'cbar','on','topo', { [5] EEG.chanlocs EEG.chaninfo } );
slide = add(ppt,"Title and Content"); replace(slide,"Title",'Pulse');
print(tempfig,"-dpng",'tempfig1');Imageslide = Picture('tempfig1.png');
replace(slide,"Content",Imageslide);%close(tempfig);
tempfig = figure; 
pop_timtopo(pulse, [-5 5], [-.3  0  1],'ERP data and scalp maps');
slide = add(ppt,"Title and Content");replace(slide,"Title",'Pulse');
print(tempfig,"-dpng",'tempfig2');Imageslide = Picture('tempfig2.png');
replace(slide,"Content",Imageslide);%close(tempfig);

%re-epoch 
pulse = pop_epoch( EEG, {tms}, [-.01 .6], 'epochinfo', 'yes');
pulse = pop_rmbase(pulse, [-10   0]);
%plot pulse
tempfig=figure;
t = -2:1/dt:2;
[temp, i(1)] = min(abs(pulse.times-t(1)));
[temp, i(2)] = min(abs(pulse.times-t(end)));
subplot(2,1,1)
hold on
for trial = 1:size(pulse.data,3)
    plot(pulse.times(i(1):i(2)),pulse.data(electr_oi_i,i(1):i(2),trial))
end
title('Pulse - All Trials')
subplot(2,1,2)
plot(pulse.times(i(1):i(2)),pulse.data(electr_oi_i,i(1):i(2),trial))
title('Pulse - Example Trial')
xlabel('Time (ms)')
slide = add(ppt,"Title and Content");replace(slide,"Title",'Pulse');
print(tempfig,"-dpng",'tempfig3');Imageslide = Picture('tempfig3.png');
replace(slide,"Content",Imageslide);%close(tempfig);

%plot ringing
tempfig = figure;
t = -5:1/dt:10;
[temp, i(1)] = min(abs(pulse.times-t(1)));
[temp, i(2)] = min(abs(pulse.times-t(end)));
subplot(2,1,1)
hold on
for trial = 1:size(pulse.data,3)
    detrended = detrend(pulse.data(electr_oi_i,i(1):i(2),trial));
    detrended = detrended-detrended(1);
    plot(pulse.times(i(1):i(2)),detrended)
end
title('Ringing - All Trials')
ylim([-500 15000])
xlim([t(1) t(end)])
subplot(2,1,2)
detrended = detrend(pulse.data(electr_oi_i,i(1):i(2),trial));
detrended = detrended-detrended(1);
plot(pulse.times(i(1):i(2)),detrended)
title('Ringing -  Example Trial')
xlabel('Time (ms)')
xlim([t(1) t(end)])
ylim([-500 15000])
slide = add(ppt,"Title and Content");replace(slide,"Title",'Ringing');
print(tempfig,"-dpng",'tempfig4');Imageslide = Picture('tempfig4.png');
replace(slide,"Content",Imageslide);

%plot recharge
tempfig = figure;
t = -2:1/dt:600;
[temp, i(1)] = min(abs(pulse.times-t(1)));
[temp, i(2)] = min(abs(pulse.times-t(end)));
subplot(2,1,1)
hold on
for trial = 1:size(pulse.data,3)
    detrended = detrend(pulse.data(electr_oi_i,i(1):i(2),trial));
    plot(pulse.times(i(1):i(2)),detrended)
end
title('Recharge - All Trials')
xlim([t(1) t(end)])
ylim([-500 500])
subplot(2,1,2)
detrended = detrend(pulse.data(electr_oi_i,i(1):i(2),trial));
plot(pulse.times(i(1):i(2)),detrended)
title('Recharge -  Example Trial')
xlabel('Time (ms)')
xlim([t(1) t(end)])
ylim([-500 500])
slide = add(ppt,"Title and Content");replace(slide,"Title",'Recharge');
print(tempfig,"-dpng",'tempfig5');Imageslide = Picture('tempfig5.png');
replace(slide,"Content",Imageslide);
clear pulse

% plot decay
%%%%%%%%%%%%%%%
pulse = pop_epoch( EEG, {tms}, [-.05 .2], 'epochinfo', 'yes');
pulse = pop_rmbase(pulse, [-40   -10]);
tempfig = figure;
hold on
plot(pulse.times, mean(pulse.data(5,:,:),3))
ylim([-10 6])
title('Decay')
slide = add(ppt,"Title and Content");replace(slide,"Title",'Decay');
print(tempfig,"-dpng",'tempfig6');Imageslide = Picture('tempfig6.png');
replace(slide,"Content",Imageslide)
clear pulse
% what I could do is interpolate decay and then (still not recovered to 0)
% rebase the data from the point after tms?

%% Pulse
disp('----------------------')
disp('----------------------')
disp('Manual Input Required')
disp('----------------------')
disp('----------------------')
pulse_zero_time=input('Set pulse time window upper limit (lower limit = -4):');%[-4,22]; 
pulse_zero_time = [-4,pulse_zero_time];
txt = sprintf('Pulse cut: %i %i\n',pulse_zero_time);
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
%%%%%%%%%%%%

%% Remove pulse from continuous data   
% I'm no longer looking for pulses, I just go by the pulse events
% (they coe directly from the stimulator and should be accurate - for code
% to search for pulses: find_pulse_cont.m and then any other preproc pipe
recharge_period = 16;
% find pulse times
pulse_times = [];
for event = 1:length(EEG.event)
    if length(EEG.event(event).type)==length(tms)
        if EEG.event(event).type == tms
            pulse_times = [pulse_times, EEG.event(event).latency];
            %these are alredy in is not units
        end
    end
end
txt = sprintf('%i pulse times found (%i expected).\n',...
              length(pulse_times), 720/3*2) ;
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)

%loop through and get rid
pulse=[];
for p = 1:length(pulse_times)
    pulse = pulse_times(p)+pulse_zero_time(1)*dt : pulse_times(p)+...
            pulse_zero_time(2)*dt;
        % since I'm not doing trials, I can giv the interpolation the whole
        % data at each step, but that takes forever (works though), so I'm
        % cutting around it first
            %         tic
            %         for electr=1:size(EEG.data,1)
            %                 y=EEG.data(electr,:);
            %                 x=EEG.times;
            %                 x(pulse)=[]; y(pulse)=[];
            %                 xx=EEG.times(pulse);   
            %                 yy=interp1(x,y,xx,'pchip');%pchip is cubic
            %                 EEG.data(electr,pulse)=yy;
            %         end
            %         toc
        cut=1000;
        x = EEG.times(pulse(1)-cut:pulse(end)+cut);
        xx = x(1+cut:cut+length(pulse)); 
        x(1+cut:cut+length(pulse))=[];
        for elec=1:size(EEG.data,1)          
             y = EEG.data(elec,pulse(1)-cut:pulse(end)+cut);
             y(1+cut:cut+length(pulse))=[]; 
             yy=interp1(x,y,xx,'linear');
             EEG.data(elec,[pulse])=yy;
        end
%     % to zero out instead
%     EEG.data(:,pulse)=0;
end

% inspect
%if we need to look properly, loop through all elecs
tempfig = figure;
count=0;
plot_time = [pulse_zero_time(1)-5, pulse_zero_time(2)+10];
rnd_elecs = randi(size(EEG.data,1)-length(EOG),1,12);
for elec=1:length(rnd_elecs)
%     if elec/12==round(elec/12)
%         figure
%         hold on
%         count = 0;
%     end
    count = count+1;
    subplot(4,3,count)
    hold on
    title(strcat('Electrode ',EEG.chanlocs(rnd_elecs(elec)).labels))
    for p = 1:length(pulse_times)
        pulse = pulse_times(p)+plot_time(1)*dt : pulse_times(p)+...
                plot_time(2)*dt;
        data = EEG.data(rnd_elecs(elec),pulse) - ...
               EEG.data(rnd_elecs(elec),pulse(1));
        plot(plot_time(1):1/dt:plot_time(2),data)
    end
end


slide = add(ppt,"Title and Content");replace(slide,"Title",'Interpolated Pulse');
print(tempfig,"-dpng",'tempfig7');Imageslide = Picture('tempfig7.png');
replace(slide,"Content",Imageslide);close(tempfig);
    

%% now replot pulse figures
%re-epoch 
pulse = pop_epoch( EEG, {tms}, [-.01 .6], 'epochinfo', 'yes');
pulse = pop_rmbase(pulse, [-10   0]);
%plot pulse
tempfig=figure;
t = [pulse_zero_time(1)-5:1/dt: pulse_zero_time(2)+10];
[temp, i(1)] = min(abs(pulse.times-t(1)));
[temp, i(2)] = min(abs(pulse.times-t(end)));
subplot(3,1,1)
hold on
for trial = 1:size(pulse.data,3)
    plot(pulse.times(i(1):i(2)),pulse.data(electr_oi_i,i(1):i(2),trial))
end
title('Pulse - All Trials')
subplot(3,1,2)
plot(pulse.times(i(1):i(2)),pulse.data(electr_oi_i,i(1):i(2),trial))
title('Pulse - Example Trial')
subplot(3,1,3)
plot(pulse.times(i(1):i(2)),mean(pulse.data(electr_oi_i,i(1):i(2),:),3))
title('Pulse - Avg')
xlabel('Time (ms)')
clear pulse
slide = add(ppt,"Title and Content");replace(slide,"Title",'Pulse (after interpolation)');
print(tempfig,"-dpng",'tempfig8');Imageslide = Picture('tempfig8.png');
replace(slide,"Content",Imageslide);close(tempfig);

 EEG = eeg_checkset( EEG );   
%% median filter recharges 
%(don't intend to look there, but let's be thorough)
% there are two components to the recharge artifact, one at the daly (here
% 500) and one a period after, depnding on intesnity (here 13)
for p = 1:length(pulse_times)
    % initial bump
    recharge1 = pulse_times(p)+delay*dt + ...
                recharge_zero_time(1)*dt : pulse_times(p)+delay*dt + ...
                recharge_zero_time(2)*dt;
    for elec=1:size(EEG.data,1)
        filt_ord =length(recharge1);%number of datapoints considered left and right
        EEG.data(elec,[recharge1])= medfilt1(EEG.data(elec,...
                              [recharge1]),filt_ord,'truncate');
    end
    %second bump
    recharge2 = pulse_times(p)+(delay+recharge_period)*dt + ...
                recharge_zero_time(1)*dt : pulse_times(p)+...
                (delay+recharge_period)*dt + recharge_zero_time(2)*dt;  
    for elec=1:size(EEG.data,1)
        filt_ord =length(recharge2);%number of datapoints considered left and right
        EEG.data(elec,[recharge2])= medfilt1(EEG.data(elec,...
                              [recharge2]),filt_ord,'truncate');
    end
end
txt = sprintf('Recharge period used: %ims.\n',recharge_period);
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
EEG = eeg_checkset( EEG );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PREPROC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% downsample
EEG= pop_resample(EEG,1000);
dt=1;
% filter
EEG=tesa_filtbutter(EEG,1,100,4,'bandpass');

%% remove bad channels
figure; pop_spectopo(EEG, 1, [], 'EEG' , 'percent',15,'freq',...
        [10 20 30],'freqrange',[2 80],'electrodes','off');
disp('----------------------')
disp('----------------------')
disp('Manual Input Required')
disp('----------------------')
disp('----------------------')
bad = input('Select bad channels:');

EEG=pop_select(EEG, 'nochannel',bad);
bad_labls=[];
for i = 1 :length(bad)
    bad_labls=[bad_labls, channels(bad(i)).labels,', '];
end
txt = sprintf('Bad Channels: %s\n',bad_labls(1:end-2));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)

%in case it changed:
%find electrode oi
rej = [];
for chan= 1:length(EEG.chanlocs)
    if length(EEG.chanlocs(chan).labels)==length(electr_oi)
        if EEG.chanlocs(chan).labels==electr_oi
            electr_oi_i=chan;
        end
    end
end

%% automatic break rejecction
break_trials =[120:120:720-120];
rej = [];
%delete beginning & end
for event = 1:length(EEG.event)
    if length(EEG.event(event).type)==length('Trial1')
        if EEG.event(event).type=='Trial1'
            rej = [rej; 2 EEG.event(event).latency - 1000*dt];
        end
    elseif length(EEG.event(event).type)==length('Trial720')
        if EEG.event(event).type=='Trial720'
            for step = 1:length(EEG.event)-event
                if length(EEG.event(event+step).type) == length(respcue)
                    if EEG.event(event+step).type == respcue
                        rej = [rej; EEG.event(event+step).latency + 1000*dt size(EEG.data,2)];
                    end
                end
            end
        end
    end
end
%delete breaks
for brk = 1:length(break_trials)
    for event = 1:length(EEG.event)
        if length(EEG.event(event).type)==length(strcat('Trial',num2str(break_trials(brk))))
            if EEG.event(event).type==strcat('Trial',num2str(break_trials(brk)))
                lat_start =[];
                lat_end =[];
                for step = 1:10
                    if length(EEG.event(event+step).type) == length(respcue)
                        if EEG.event(event+step).type == respcue & isempty(lat_start)
                            lat_start =  EEG.event(event+step).latency + 1000*dt;
                        end
                    elseif length(EEG.event(event+step).type)==length(strcat('Trial',num2str(break_trials(brk)+1)))
                        if EEG.event(event+step).type==strcat('Trial',num2str(break_trials(brk)+1)) & isempty(lat_end)
                            lat_end = EEG.event(event+step).latency - 1000*dt;
                        end
                    end
                end
                if lat_end > lat_start
                    rej = [rej; lat_start lat_end];
                end
            end
        end
    end
end

EEG = eeg_eegrej( EEG, rej);
txt = sprintf('Break Rejection: %s\n',mat2str(rej));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
EEG = eeg_checkset( EEG );

%% ICA
% since we recrod all the time, we definitely get a lot of lbinks which
% aren't locked to TMS - so hopeffuly this is fine
EEG=pop_runica(EEG, 'icatype', 'runica');

%Identify Blink Component
figure; pop_selectcomps(EEG, [1:35] );
disp('----------------------')
disp('----------------------')
disp('Manual Input Required')
disp('----------------------')
disp('----------------------')
blink_component = input('Select blink component:');%1;

txt = sprintf('Blink Component: %s\n',num2str(blink_component));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
%% check blinks
Comps=EEG.icaweights*EEG.data;% sources = unmixing matrix * data
Blinks = Comps(blink_component,:);
Blinks = abs(Blinks);
%find blinks
Blink_i = find(Blinks > mean(Blinks)+std(Blinks)*5);
%delete continuous
rid=[];
for i = 2:length(Blink_i)
    if Blink_i(i-1) == Blink_i(i)-1
        rid = [rid, i];
    end
end
Blink_i(rid)=[];   
Blink_t = EEG.times(Blink_i);
%go through pulses and see if blink is close
closest_blink=[];
for event = 1:length(EEG.event)
    if length(EEG.event(event).type) == length(tms)
        if EEG.event(event).type==tms
            tmslat = EEG.event(event).latency;
            closest = min(abs(Blink_t - tmslat));
            closest_blink=[closest_blink,closest];
        end
    end
end
tempfig = figure; histogram(closest_blink)
title('Closest Blinks per Pulse')
slide = add(ppt,"Title and Content");replace(slide,"Title",'Blink - Pulse');
print(tempfig,"-dpng",'tempfig9');Imageslide = Picture('tempfig9.png');
replace(slide,"Content",Imageslide);close(tempfig);

blk_cnds=[.1,.5,1];
for blk = 1:length(blk_cnds)
    txt = sprintf('%i pulses are within %1.1fs of blink.\n',...
             sum(closest_blink<=blk_cnds(blk)*1000),blk_cnds(blk));
	fprintf(out_txt, '%s\n ', txt); 
    fprintf('%s',txt)
end
txt=sprintf('%i pulses are at least 1s away from a blink.\n',sum(closest_blink>1000));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)

EEG = pop_subcomp( EEG, blink_component, 0);

%interpolate
EEG=pop_interp(EEG,channels,'spherical');

%reref
EEG = pop_reref( EEG, [],'exclude',[64 65] );

%% epoching
% from now on, we'll reject from epochs, not continuous data - this lead to
% more data overall, but it allows us to match removed trials across data
% sets
EEG = pop_epoch( EEG, {cue1, cue2}, [-.2 2.8], 'epochinfo', 'yes');

%% manual rejecction
%eeglab redraw
pop_eegplot( EEG, 1, 1, 1);
disp('----------------------')
disp('----------------------')
disp('Manual Input Required')
disp('----------------------')
disp('----------------------')
input('Press enter when rejection is complete.');
eegh
disp('----------------------')
disp('----------------------')
disp('Manual Input Required')
disp('----------------------')
disp('----------------------')
rej = input('Provide rejection matrix:');

% EEG = eeg_eegrej( EEG, rej);
txt = sprintf('Manual Artifact Rejection: %s\n',mat2str(rej));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)

%% delete bad neuronavigation trials
neurnav_rej = [];
common_trial_counter = 0;
if ~isempty(bad_trials)
    for bad_trial = bad_trials
        found = 0;
        for epoch = 1:length(EEG.epoch)
            if length(EEG.epoch(epoch).eventtype{2}) == length(strcat('Trial ',num2str(bad_trial)))
                if EEG.epoch(epoch).eventtype{2} == strcat('Trial ',num2str(bad_trial))
                    neurnav_rej = [neurnav_rej, epoch];
                    found = 1;
                end
            end
        end
        if found ==0 
            common_trial_counter = common_trial_counter+1;
        end
    end
end
EEG = pop_rejepoch( EEG, neurnav_rej,0);
EEG = eeg_checkset( EEG );
txt = sprintf('%i further trials rejection based on Neuronav: %s\n',length(neurnav_rej));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)     
txt = sprintf('%i trials bad in both EEG and Neuronav: %s\n',common_trial_counter);
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt) 
        
    
% save continuous but epoch to see whats left

txt = sprintf('%i clean whole trials left .\n', EEG.trials);
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
TEP = pop_epoch( EEG, {tms}, [-.1 .4], 'epochinfo', 'yes');
txt = sprintf('%i clean TEPs left (-100 400, tms).\n', size(TEP.data,3));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
SEP = pop_epoch( EEG, {tap}, [-.1 .4], 'epochinfo', 'yes');
txt = sprintf('%i clean SEPs left (-100 400, tap).\n', size(SEP.data,3));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)

% save
EEG = eeg_checkset( EEG );
EEG = pop_saveset( EEG, 'filename',strcat(partic_str,'_clean.set'),'filepath',filedir);

%done
fclose('all');
close(ppt);
close all
delete tempfig1.png tempfig2.png tempfig3.png tempfig4.png tempfig5.png
delete tempfig6.png tempfig7.png tempfig8.png tempfig9.png
