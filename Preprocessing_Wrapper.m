

partic = 20,
session = 1;

cd('C:\Users\ckohl\Desktop\Current\TMS\TMS-EEG-AnalysisCode')
%% Check Behaviour
disp('========================')
disp ('== Analysing Behaviour ==')
disp('========================')
BehaviourI(partic,session);

input(' Behaviour check done. Press Enter to continue.');
close all

%% NeuroNavigation
disp('========================')
disp ('== NeuroNavigation ==')
disp('========================')
[bad_trials_mep, bad_trials_target] = Neuronavigation(partic, session);

input(' NeuroNavigation check done. Press Enter to continue.');

%% S1Loc
disp('========================')
disp ('== S1Loc ==')
disp('========================')
Preprocessing_S1Loc(partic,session);

input(' S1Loc preprocessing done. Press Enter to continue.');

%% Task EEG
disp('========================')
disp ('== Task EEG ==')
disp('========================')
Preprocessing(partic, session, [bad_trials_mep;bad_trials_target]);