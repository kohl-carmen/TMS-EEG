function EEG = Preprocessing_S1Loc_Post_1(partic,session,out_dir)
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
% load eeglab
eeglab_dir='C:\Users\ckohl\Documents\MATLAB\eeglab2020_0';
cd(eeglab_dir)
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% set up output
partic_str = sprintf('%02d', partic);
filedir = strcat('C:\Users\ckohl\Desktop\Data\BETA',partic_str,'\Session',num2str(session),'\');
out_txt = fopen(strcat(out_dir,partic_str,'_s1loc'), 'a');

EOG = [64,65];
electr_oi='C3';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% POST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
fprintf(out_txt,'\n - POST -\n');

%load data
partic_str = sprintf('%02d', partic);
filedir = strcat('C:\Users\ckohl\Desktop\Data\BETA',partic_str,'\Session',num2str(session),'\');
cd(filedir)
filename = dir('*.vhdr');
if length(filename) >1
    for i = 1:length(filename)
        if contains(filename(i).name,'Loc')
            if contains(filename(i).name,'Post')
                filename = filename(i);
                break
            end
        end
    end
end
EEG = pop_loadbv(filedir, filename.name, [], []);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
EEG = eeg_checkset( EEG );
eeglab redraw
% get data properties
dt=EEG.srate/1000;
channels = EEG.chanlocs;
EOG = [64,65];

%% EVENTS
% define events
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

txt = sprintf('Found a total of %i events and %i types: \n',...
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

%% PREPROC
% downsample
EEG= pop_resample(EEG,1000);
dt=1;
% filter
EEG=tesa_filtbutter(EEG,1,45,4,'bandpass');

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
for chan= 1:length(EEG.chanlocs)
    if length(EEG.chanlocs(chan).labels)==length(electr_oi)
        if EEG.chanlocs(chan).labels==electr_oi
            electr_oi_i=chan;
        end
    end
end


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

EEG = pop_subcomp( EEG, blink_component, 0);

%interpolate
EEG=pop_interp(EEG,channels,'spherical');

%reref
EEG = pop_reref( EEG, [],'exclude',[64 65] );

cd(init_dir)
