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
%     - **break reject**
%     - **ICA (blinks only)**
%     - **art reject**
%     - interpolate
%     - rereference
%                         **manual steps

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
close all

%% set per person
partic = 2;
% Recharge 
delay = 500;
recharge_period = 13;
recharge_zero_time = [-3 3];%artifact itself is short, but a bit variable, so cut out chunk - don't really care anyway

% load eeglab
eeglab_dir='C:\Users\ckohl\Documents\MATLAB\eeglab2020_0';
cd(eeglab_dir)
eeglab

%load data
partic_str = sprintf('%02d', partic);
filedir = strcat('C:\Users\ckohl\Desktop\Data\Pilot\Beta',partic_str);
cd(filedir)
filename = dir('*.vhdr');
EEG = pop_loadbv(filedir, filename.name, [], []);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
EEG = eeg_checkset( EEG );
eeglab redraw

% get data properties
dt=EEG.srate/1000;
electr_oi='C3';
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
for event = 1:length(EEG.event)
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
    if length(EEG.chanlocs(chan).labels)==2
        if EEG.chanlocs(chan).labels==electr_oi
            electr_oi_i=chan;
        end
    end
end

EEG = eeg_checkset( EEG );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define Conditions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
opts.DataLines = [5, Inf];
opts.Delimiter = "\t";
opts.VariableNames = ["Trial", "CueCond", "TMSCond", "TapCond", "Accuracy", "YesResponse", "NoResponse", "TapTime", "TMSTime", "RT", "Threshold"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
tbl = readtable(strcat(filedir,'\BETA',partic_str,'_results.txt'), opts);
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
replace(slide,"Content",Imageslide);close(tempfig);
tempfig = figure; 
pop_timtopo(pulse, [-5 5], [-.3  0  1],'ERP data and scalp maps');
slide = add(ppt,"Title and Content");replace(slide,"Title",'Pulse');
print(tempfig,"-dpng",'tempfig2');Imageslide = Picture('tempfig2.png');
replace(slide,"Content",Imageslide);close(tempfig);

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
replace(slide,"Content",Imageslide);close(tempfig);

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
replace(slide,"Content",Imageslide);close(tempfig);

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
replace(slide,"Content",Imageslide);close(tempfig)
clear pulse

% plot decay
%%%%%%%%%%%%%%%
pulse = pop_epoch( EEG, {tms}, [-.05 .2], 'epochinfo', 'yes');
pulse = pop_rmbase(pulse, [-40   -10]);
figure
clf
hold on
plot(pulse.times, mean(pulse.data(5,:,:),3))
ylim([-10 6])
title('Decay')
slide = add(ppt,"Title and Content");replace(slide,"Title",'Decay');
print(tempfig,"-dpng",'tempfig6');Imageslide = Picture('tempfig6.png');
replace(slide,"Content",Imageslide);close(tempfig)
clear pulse
% what I could do is interpolate decay and then (still not recovered to 0)
% rebase the data from the point after tms?

%% Pulse
pulse_zero_time=[-4,22]; 
txt = sprintf('Pulse cut: %i %i\n',pulse_zero_time);
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
%%%%%%%%%%%%

%% Remove pulse from continuous data   
% I'm no longer looking for pulses, I just go by the pulse events
% (they coe directly from the stimulator and should be accurate - for code
% to search for pulses: find_pulse_cont.m and then any other preproc pipe

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
plot_time = [-10 20];
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
    title(strcat('Electrode ',EEG.chanlocs(rnd_elecs(elec)).labels,...
          ' - Pulse: ', num2str(p)))
    for p = 1:length(pulse_times)
        pulse = pulse_times(p)+plot_time(1)*dt : pulse_times(p)+...
                plot_time(2)*dt;
        data = EEG.data(rnd_elecs(elec),pulse) - ...
               EEG.data(rnd_elecs(elec),pulse(1));
        plot(plot_time(1):1/dt:plot_time(2),data)
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clf
for elec=5%:length(rnd_elecs)
%     if elec/12==round(elec/12)
%         figure
%         hold on
%         count = 0;
%     end
    hold on
    title(strcat('Electrode ',EEG.chanlocs((elec)).labels,...
          ' - Pulse: ', num2str(p)))
    for p = 1:length(pulse_times)
        pulse = pulse_times(p)+plot_time(1)*dt : pulse_times(p)+...
                plot_time(2)*dt;
        data = EEG.data(elec,pulse) - ...
               EEG.data((elec),pulse(1));
        plot(plot_time(1):1/dt:plot_time(2),data)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


slide = add(ppt,"Title and Content");replace(slide,"Title",'Interpolated Pulse');
print(tempfig,"-dpng",'tempfig7');Imageslide = Picture('tempfig7.png');
replace(slide,"Content",Imageslide);close(tempfig);
    

%% now replot pulse figures
%re-epoch 
pulse = pop_epoch( EEG, {tms}, [-.01 .6], 'epochinfo', 'yes');
pulse = pop_rmbase(pulse, [-10   0]);
%plot pulse
tempfig=figure;
t = -10:1/dt:20;
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
bad= [29];
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
for chan= 1:length(EEG.chanlocs)
    if length(EEG.chanlocs(chan).labels)==2
        if EEG.chanlocs(chan).labels==electr_oi
            electr_oi_i=chan;
        end
    end
end

%% break manual rejecction
%eeglab redraw
%pop_eegplot( EEG, 1, 1, 1);

rej= [12 97910;402549 536063;843000 870484;1178498 1206415;1517472 1545562;1852190 1880373;2186315 2214274;2523272 2551683;2614478 2634100];
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

blink_component = 1;

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

%% manual rejecction
%eeglab redraw
pop_eegplot( EEG, 1, 1, 1);

rej=[7584 8036;9325 10429;11718 13988;47064 47517;57176 57582;70883 71873;74322 75049;109479 110120;121109 122483;187708 190138;194510 196530;219179 220769;251059 251159;253431 254335;269266 271437;278781 279514;304584 309597;314866 316808;329266 330778;385395 385877;417182 418101;481161 484588;535289 536687;602105 603673;794826 795451;830852 832065;918604 926888;937683 941560;950778 951863;961254 962158;1012157 1014437;1017392 1019229;1022336 1025516;1061310 1061984;1063474 1064826;1092621 1093549;1108796 1111369;1126468 1130228;1139588 1140120;1176356 1177498;1199337 1199817;1230608 1235970;1237955 1241112;1243048 1243258;1247689 1247894;1253901 1254659;1310555 1311891;1312046 1312560;1517423 1519171;1529516 1530315;1537185 1539829;1547591 1548440;1568314 1568497;1574346 1575682;1583784 1584783;1628128 1629826;1640085 1640951;1658508 1659171;1661127 1661375;1675330 1675679;1684247 1685556;1723555 1724563;1729866 1730577;1734053 1734693;1738737 1740157;1767265 1768030;1843140 1846446;1847111 1850828;1854377 1856752;1950583 1951211;2057578 2058695;2152182 2154576;2160466 2161261;2202098 2202501;2205707 2206873];
EEG = eeg_eegrej( EEG, rej);
txt = sprintf('Manual Artifact Rejection: %s\n',mat2str(rej));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
    
%interpolate
EEG=pop_interp(EEG,channels,'spherical');

%reref
EEG = pop_reref( EEG, []);

% save continuous but epoch to see whats left
Trial = pop_epoch( EEG, {cue1, cue2}, [-.1 2], 'epochinfo', 'yes');
txt = sprintf('%i clean whole trials left (-100 2000, cue).\n', size(Trial.data,3));
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
delete tempfig1.png tempfig2.png tempfig3.png tempfig4.png tempfig5.png
delete tempfig6.png tempfig7.png tempfig8.png tempfig9.png
