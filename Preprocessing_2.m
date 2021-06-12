function [common_trial_counter] = Preprocessing_2(partic, session, EEG, out_dir, ppt, rej, bad_trials)
init_dir = cd;
partic_str = sprintf('%02d', partic);
filedir = strcat('C:\Users\ckohl\Desktop\Data\BETA',partic_str,'\Session',num2str(session),'\');
out_txt = fopen(strcat(out_dir,partic_str,'_preproc'), 'a');
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
tap = 'S  1';
tms = 'S  2';
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
cd(out_dir)
fclose('all');
close(ppt);
close all
delete tempfig1.png tempfig2.png tempfig3.png tempfig4.png tempfig5.png
delete tempfig6.png tempfig7.png tempfig8.png tempfig9.png
cd(init_dir)
