

partic = 22,
session = 1;



%% Check Behaviour
cd('C:\Users\ckohl\Desktop\Current\TMS\TMS-EEG-AnalysisCode')
disp('========================')
disp ('== Analysing Behaviour ==')
disp('========================')
BehaviourI(partic,session);

input(' Behaviour check done. Press Enter to continue.');
close all

%% NeuroNavigation
cd('C:\Users\ckohl\Desktop\Current\TMS\TMS-EEG-AnalysisCode')
disp('========================')
disp ('== NeuroNavigation ==')
disp('========================')
[bad_trials_mep, bad_trials_target] = Neuronavigation(partic, session);

input(' NeuroNavigation check done. Press Enter to continue.');

%% S1Loc
cd('C:\Users\ckohl\Desktop\Current\TMS\TMS-EEG-AnalysisCode')
disp('========================')
disp ('== S1Loc ==')
disp('========================')
Preprocessing_S1Loc(partic,session);

input(' S1Loc preprocessing done. Press Enter to continue.');

%% Task EEG
cd('C:\Users\ckohl\Desktop\Current\TMS\TMS-EEG-AnalysisCode')
disp('========================')
disp ('== Task EEG ==')
disp('========================')
[rej, common_trial_counter] = Preprocessing(partic, session, [bad_trials_mep;bad_trials_target]);

%% Summary
cd('C:\Users\ckohl\Desktop\Current\TMS\TMS-EEG-AnalysisCode')
Trials = 720;
partic_str = sprintf('%02d', partic);
filedir = strcat('C:\Users\ckohl\Desktop\Data\BETA',partic_str,'\Session',num2str(session),'\');
out_dir =  strcat(filedir,'\Preproc\');
out_txt = fopen(strcat(out_dir,partic_str,'_preproc'), 'a');

txt = sprintf('Trials deleted due to MEPs: %i (%2.2f%%)\n',length(bad_trials_mep), length(bad_trials_mep)/Trials*100);
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
txt = sprintf('bad_trials_mep: %s\n',mat2str(bad_trials_mep));
fprintf(out_txt, '%s\n ', txt); 

txt = sprintf('Trials deleted due to failed Navigation: %i (%2.2f%%)\n',length(bad_trials_target), length(bad_trials_target)/Trials*100);
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
txt = sprintf('bad_trials_target: %s\n',mat2str(bad_trials_target));
fprintf(out_txt, '%s\n ', txt); 

txt = sprintf('Trials deleted due to bad EEG data: %i (%2.2f%%)\n',length(rej), length(rej)/Trials*100);
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
txt = sprintf('rej: %s\n',mat2str(rej));
fprintf(out_txt, '%s\n ', txt); 

txt = sprintf('Rejection overlap: %i trial(s)\n',common_trial_counter);
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)
all = length(bad_trials_mep) + length(bad_trials_target) +  length(rej) - common_trial_counter;
txt = sprintf('Total trial loss: %i (%2.2f%%) - %i Trials remaining.\n',all, all/Trials*100, Trials-all);
fprintf(out_txt, '%s\n ', txt); 
fprintf('%s',txt)

%delete from behavioural file
Rejected = [bad_trials_mep,bad_trials_target,rej];
Rejected = unique(Rejected);

fid =fopen(strcat(filedir,'BETA',partic_str,'_results'));
TXT = textscan(fid,'%s','delimiter','\n');
fclose(fid);
delete = [];
for reject = Rejected
    for row = 5:numel(TXT{1,1})
        if TXT{1,1}{row,1}(1:numel(num2str(reject))) == num2str(reject)
            break
        end
    end
    delete = [delete, row];
end
% print new file
fid =fopen(strcat(filedir,'BETA',partic_str,'_results_clean'),'w');
for row=1:numel(C{1,1}) 
    if any(row == delete)
        %skip
    else
        fprintf(fid,'%s\r\n',C{1,1}{row,1}); 
    end
end
fclose(fid);
cd(out_dir)
save('Rejected','Rejected')

fclose all
close all
clear



