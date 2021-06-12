function PRE = Preprocessing_S1Loc_Pre_2(partic,session, EEG, rej, out_dir)
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

% set up output
partic_str = sprintf('%02d', partic);
out_txt = fopen(strcat(out_dir,partic_str,'_s1loc'), 'a');

EOG = [64,65];
electr_oi='C3';

% get data properties
dt=EEG.srate/1000;
channels = EEG.chanlocs;

% define events
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

txt = sprintf('Manual Artifact Rejection: %s\n',mat2str(rej));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)

% save continuous but epoch to see whats left
SEP = pop_epoch( EEG, {tap}, [-.1 .4], 'epochinfo', 'yes');
txt = sprintf('%i clean SEPs left (-100 400, tap).\n', size(SEP.data,3));
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)

% save
partic_str = sprintf('%02d', partic);
filedir = strcat('C:\Users\ckohl\Desktop\Data\BETA',partic_str,'\Session',num2str(session),'\');
EEG = eeg_checkset( EEG );
EEG = pop_saveset( EEG, 'filename',strcat(partic_str,'_S1Loc_Pre_clean.set'),'filepath',filedir);

PRE = EEG;
clear EEG
clear SEP
cd(init_dir)
