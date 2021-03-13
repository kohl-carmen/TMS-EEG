%% Sanitycheck all behavioural output and print performance
clear

partic = 4;
partic_str = sprintf('%02d', partic);
filedir = strcat('C:\Users\ckohl\Desktop\Data\Pilot\Beta',partic_str);
file=strcat(filedir, '\Beta',partic_str,'_results');

% set up output
out_dir =  strcat(filedir,'\Preproc\');
out_txt = fopen(strcat(out_dir,partic_str,'_behaviour'), 'a');

look_for_issues = 0;
%% load behavioural data
opts = delimitedTextImportOptions("NumVariables", 11);
opts.DataLines = [5, Inf];
opts.Delimiter = "\t";
opts.VariableNames = ["Trial", "CueCond", "TMSCond", "TapCond", "Accuracy", "YesResponse", "NoResponse", "TapTime", "TMSTime", "RT", "Threshold"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
tbl = readtable(file, opts);
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
RT = tbl.RT;
Threshold = tbl.Threshold;
clear opts tbl

%% test trial matrix 
disp ('------------------------------')
disp('check trial matrix')
disp ('------------------------------')
prob = 0;
if ~(sum(CueCond==0)==length(CueCond)/2) | ~(sum(CueCond==1)==length(CueCond)/2) | ~(sum(CueCond==1)==length(CueCond)/2) | ~(sum(CueCond==1)==length(CueCond)/2)
    fprintf('Incorrect CueCond split\n'); prob = 1;
end
if ~(sum(TapCond==2)*7==sum(TapCond==1)) | ~(sum(TapCond==2)*2==sum(TapCond==0))
    fprintf('Incorrect TapCond split\n'); prob = 1;
end
if ~(sum(TMSCond==0)==length(CueCond)/3) | ~(sum(TMSCond==1)==length(CueCond)/3) | ~(sum(TMSCond==2)==length(CueCond)/3)
    fprintf('Incorrect TMSCond split\n'); prob = 1;
end
if ~(sum(CueCond==0 & TapCond==0 & TMSCond==0) == length(CueCond)*.5*.2*1/3) | ~(sum(CueCond==0 & TapCond==0 & TMSCond==1) == length(CueCond)*.5*.2*1/3) |~(sum(CueCond==0 & TapCond==0 & TMSCond==2) == length(CueCond)*.5*.2*1/3)
% cue1, tapnull, tms1 => 1/2 .2 1/3
    fprintf('Incorrect split 1\n'); prob = 1;
end
if ~(sum(CueCond==0 & TapCond==1 & TMSCond==0) == round(length(CueCond)*.5*.7*1/3)) | ~(sum(CueCond==0 & TapCond==1 & TMSCond==1)== round(length(CueCond)*.5*.7*1/3)) | ~(sum(CueCond==0 & TapCond==1 & TMSCond==2)== round(length(CueCond)*.5*.7*1/3))
% cue1, tapthresh, tms1 => 1/2 .7 1/3
    fprintf('Incorrect split 2\n'); prob = 1;
end
if ~(sum(CueCond==0 & TapCond==2 & TMSCond==0)== length(CueCond)*.5*.1*1/3) | ~(sum(CueCond==0 & TapCond==2 & TMSCond==1)== length(CueCond)*.5*.1*1/3) | ~(sum(CueCond==0 & TapCond==2 & TMSCond==2)== length(CueCond)*.5*.1*1/3)
% cue1, tapsupra, tms1 => 1/2 .1 1/3
    fprintf('Incorrect split 3\n'); prob = 1;
end
if ~(sum(CueCond==1 & TapCond==0 & TMSCond==0)== length(CueCond)*.5*.2*1/3) | ~(sum(CueCond==1 & TapCond==0 & TMSCond==1)== length(CueCond)*.5*.2*1/3) | ~(sum(CueCond==1 & TapCond==0 & TMSCond==2)== length(CueCond)*.5*.2*1/3)
     fprintf('Incorrect split 4\n'); prob = 1;
end   
if ~(sum(CueCond==1 & TapCond==1 & TMSCond==0) == round(length(CueCond)*.5*.7*1/3)) | ~(sum(CueCond==1 & TapCond==1 & TMSCond==1) == round(length(CueCond)*.5*.7*1/3)) | ~(sum(CueCond==1 & TapCond==1 & TMSCond==2) == round(length(CueCond)*.5*.7*1/3))
    fprintf('Incorrect split 5\n'); prob = 1;
end
if ~(sum(CueCond==1 & TapCond==2 & TMSCond==0)==length(CueCond)*.5*.1*1/3) | ~(sum(CueCond==1 & TapCond==2 & TMSCond==1)==length(CueCond)*.5*.1*1/3) | ~(sum(CueCond==1 & TapCond==2 & TMSCond==2)==length(CueCond)*.5*.1*1/3)
    fprintf('Incorrect split 6\n'); prob = 1;
end   
if prob == 0 
    fprintf('Trial Distribution Correct\n')
end
look_for_issues = look_for_issues+prob;
%% check conditions
disp ('------------------------------')
disp('check conditions')
disp ('------------------------------')
if sum(TMSCond==0 & TMSTime>0)>0
    fprintf('TMS times found in non-TMS conditions\n')
    look_for_issues = look_for_issues+1;
end
if sum(TMSCond>0 & TMSTime==0)>0
    fprintf('Mo TMS times found in TMS conditions\n')
    look_for_issues = look_for_issues+1;
end
for cond = 0:2
    times = TMSTime(TMSCond==cond);
    fprintf('TMSCond%i - TMS time: %2.2f (%2.2f)\n',cond,mean(times),std(times))
    fprintf('TMSCond%i - TMS time: min:%2.2f max:%2.2f\n',cond,min(times),max(times))
end

%% check taptime
disp ('------------------------------')
disp('check taptime')
disp ('------------------------------')
fprintf('Tap time: %2.2f (%2.2f)\n',mean(TapTime),std(TapTime))
fprintf('Tap time: min:%2.2f max:%2.2f\n',min(TapTime),max(TapTime))

%% look at RT
disp ('------------------------------')
disp('check reaction times')
disp ('------------------------------')
%check that RT=0 only when no button was pressed 
if sum(RT(NoResponse==0 & YesResponse==0))>0
    fprintf('RT of zero found even though button was pressed\n')
    look_for_issues = look_for_issues+1;
end
if sum([YesResponse(RT==0); NoResponse(RT==0)])>0
    fprintf('RT of zero found even though button was pressed\n')
    look_for_issues = look_for_issues+1;
end
% check that only one response is given
if sum(YesResponse(NoResponse==1))>1
    fprintf('More than one response found\n')
    look_for_issues = look_for_issues+1;
end
fprintf(out_txt, '\n%s\n', '--Reaction Times--');
txt = sprintf('No response in %i out of %i trials',sum(RT==0),length(RT));
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt); 
rt = RT(RT>0);
txt = sprintf('Mean RT: %2.2f (%2.2f)',mean(rt),std(rt));
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Max RT: %2.2f, Min RT %2.2f',max(rt),min(rt));
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
% histogram(rt)

%% check Accuracy
disp ('------------------------------')
disp('check accuracy')
disp ('------------------------------')
%where cuecond=hand
problem = 0;
for trial = 1:length(RT)
    if Accuracy(trial)==1
        if RT(trial)==0 | (YesResponse(trial)==0 & NoResponse(trial)==0)
            fprintf('Accuracy problem 0\n'); problem =1;
        end
    end
    if CueCond(trial)==0 %Hand
        if TapCond(trial)>1 %supra or thresh
            if YesResponse(trial) & Accuracy(trial)==0
                fprintf('Accuracy problem 1\n'); problem =1;
            elseif NoResponse(trial) & Accuracy(trial)==1
                fprintf('Accuracy problem 2\n'); problem =1;
            elseif YesResponse(trial)==0 & NoResponse(trial)==0 & Accuracy(trial)==1
                fprintf('Accuracy problem 3\n'); problem =1;
            end
        elseif TapCond(trial)==0
            if YesResponse(trial) & Accuracy(trial)==1
                fprintf('Accuracy problem 4\n'); problem =1;
            elseif NoResponse(trial) & Accuracy(trial)==0
                fprintf('Accuracy problem 5\n'); problem =1;
            elseif YesResponse(trial)==0 & NoResponse(trial)==0 & Accuracy(trial)==1
                fprintf('Accuracy problem 6\n'); problem =1;
            end
        end
    elseif CueCond(trial)==1%Head
        if TMSCond(trial)>0
            if YesResponse(trial) & Accuracy(trial)==0
                fprintf('Accuracy problem 7\n'); problem =1;
            elseif NoResponse(trial) & Accuracy(trial)==1
                fprintf('Accuracy problem 8\n'); problem =1;
            elseif YesResponse(trial)==0 & NoResponse(trial)==0 & Accuracy(trial)==1
                fprintf('Accuracy problem 9\n'); problem =1;
            end
        elseif TMSCond(trial)==0
            if YesResponse(trial) & Accuracy(trial)==1
                fprintf('Accuracy problem 10\n'); problem =1;
            elseif NoResponse(trial) & Accuracy(trial)==0
                fprintf('Accuracy problem 11\n'); problem =1;
            elseif YesResponse(trial)==0 & NoResponse(trial)==0 & Accuracy(trial)==1
                fprintf('Accuracy problem 12\n'); problem =1;
            end
        end
    end
end
if problem==0
    fprintf('Accuracy check fine\n')
    fprintf('Mean Accuracy: %2.2f\n',mean(Accuracy))
end  
look_for_issues = look_for_issues+problem;

%% check threshold updating
% 2 correct or 3 inc
threshmin=0;
threshmax=8;
disp ('------------------------------')
disp('check threshold')
disp ('------------------------------')  
fprintf(out_txt, '\n%s\n', '--Threhold Updating--');
txt = sprintf('Mean Threshold: %2.2f (%2.2f)',mean(Threshold),std(Threshold));
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Max Threshold: %2.2f, Min Threshold %2.2f',max(Threshold),min(Threshold));
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
accuracy = Accuracy(TapCond==1 & CueCond==0);
threshold = Threshold(TapCond==1 & CueCond==0);
%find threshold changes
update_trials=[];
for trial = 2: length(accuracy)
    if threshold(trial) ~= threshold(trial-1)
        update_trials = [update_trials,trial];
    end
end
prob=0;
for trial =1:length( update_trials)
    if threshold(update_trials(trial))>threshold(update_trials(trial)-1)
        if any(accuracy(update_trials(trial)-3:update_trials(trial)-1))
            fprintf('updating error1\n');prob=1;
        end
    else
        if any(accuracy(update_trials(trial)-2:update_trials(trial)-1)==0)
            fprintf('updating error2\n');prob=1;
        end
    end
end

txt = sprintf('Threshold was updated on %i trials',length(update_trials));
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
ceilfloor=0;
accuracy_memory=[];
for trial = 1:length(accuracy)-1
    accuracy_memory=[accuracy_memory,accuracy(trial)];
    update=0;
    if length(accuracy_memory)>1
        if all(accuracy_memory(end-1:end)==1)
            update =1;
        end
    elseif length(accuracy_memory)>2
        if all(accuracy_memory(end-2:end)==0)
            update = 1;
        end
    end
    if update
        if threshold(trial+1) == threshold(trial)%failed to update
            if threshold(trial) == threshmin | threshold(trial)==threshmax
                ceilfloor = ceilfloor+1;
                accuracy_memory=[];
            else
                fprintf('Failed to update threshold\n');prob=1;
            end
        else
            accuracy_memory=[];
        end
    end
end
txt =sprintf('Failed to update because floor/ceiling on %i trials',ceilfloor);
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
if prob==0
    txt = sprintf('Threshold Updating fine')
    fprintf('%s\n',txt);
    fprintf(out_txt, '%s\n', txt);
end
look_for_issues = look_for_issues+prob;

%% check performance 
% thresh should be harder ad slower than supra
disp ('------------------------------')
disp('check performance')
disp ('------------------------------')    
disp(' ')
fprintf(out_txt, '\n%s\n', '--Performance--');
txt = sprintf('\nDetecting Taps -  overall\n');
fprintf('%s',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Null Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==0 & CueCond==0))*100), round(mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1))));
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Threshold Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==1 & CueCond==0))*100), round(mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1))));      
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Supra Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==2 & CueCond==0))*100), round(mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1))));      
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);

txt = sprintf('\nDetecting TMS -  overall\n');
fprintf('%s',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Null TMS:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TMSCond==0 & CueCond==1))*100), round(mean(RT(TMSCond==0 & CueCond==1 & Accuracy ==1)))) ;     
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('TMS100:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TMSCond==1 & CueCond==1))*100), round(mean(RT(TMSCond==1 & CueCond==1 & Accuracy ==1))));      
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('TMS25:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TMSCond==2 & CueCond==1))*100), round(mean(RT(TMSCond==2 & CueCond==1 & Accuracy ==1)))) ;
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);

txt = sprintf('\nDetecting Taps -  No TMS\n');
fprintf('%s',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Null Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==0))*100), round(mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==0))));      
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Threshold Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==0))*100), round(mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==0)))) ;     
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Supra Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==0))*100), round(mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==0))));      
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);

txt = sprintf('\nDetecting Taps -  100ms\n');
fprintf('%s',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Null Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==1))*100), round(mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==1)))) ;     
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Threshold Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==1))*100), round(mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==1))))  ;    
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Supra Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==1))*100), round(mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==0)))); 
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);

txt = sprintf('\nDetecting Taps -  25ms\n');
fprintf('%s',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Null Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==2))*100), round(mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==2))))  ;    
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Threshold Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==2))*100), round(mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==2)))) ;     
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Supra Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==2))*100), round(mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==2)))) ; 
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);

%%%%%%
%% check performance
varnames = {'Reported: Stim', 'Reorted: No Stim'};
rownames = {'Cond: Stim', 'Cond: No Stim'};
fprintf(out_txt, '\n%s\n', '--Performance Matrix--');

disp('-----------------------------------------')
disp('All Hand Trials--------------------------')
disp('-----------------------------------------')
txt = sprintf('\nAll Hand Trials\n');
fprintf(out_txt, '%s\n', txt);
true_pos = sum(CueCond==0 & TapCond>0 & Accuracy==1);
true_neg = sum(CueCond==0 & TapCond==0 & Accuracy==1);
false_pos = sum(CueCond==0 & TapCond==0 & Accuracy==0 & YesResponse==1);
false_neg = sum(CueCond==0 & TapCond>0 & Accuracy==0 & NoResponse==1);
no_resp = sum(CueCond==0 & YesResponse==0 & NoResponse==0);

tabvals1 = [true_pos; false_pos];
tabvals2 = [false_neg; true_neg];
tab = table(tabvals1, tabvals2, 'VariableNames',varnames, 'RowNames',rownames)

temp =table2array(tab);
txt = sprintf('%s\t%s\t%s\n','X', 'Yes','No');
fprintf(out_txt, '%s', txt);
txt = sprintf('%s\t%i\t%i\n','Yes', temp(1,1),temp(1,2));
fprintf(out_txt, '%s', txt);
txt = sprintf('%s\t%i\t%i\n','No', temp(2,1),temp(2,2));
fprintf(out_txt, '%s', txt);

txt = sprintf('\nNo Response: %i',no_resp)   ;
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Overall Accuracy: %i%%\n',round(mean(Accuracy(CueCond==0))*100));
fprintf('%s',txt);
fprintf(out_txt, '%s\n', txt);
    
disp(' ')
disp('-----------------------------------------')
disp('All Head Trials--------------------------')
disp('-----------------------------------------')
txt = sprintf('\nAll Head Trials\n');
fprintf(out_txt, '%s\n', txt);
true_pos = sum(CueCond==1 & TMSCond>0 & Accuracy==1);
true_neg = sum(CueCond==1 & TMSCond==0 & Accuracy==1);
false_pos = sum(CueCond==1 & TMSCond==0 & Accuracy==0 & YesResponse==1);
false_neg = sum(CueCond==1 & TMSCond>0 & Accuracy==0 & NoResponse==1);
no_resp = sum(CueCond==1 & YesResponse==0 & NoResponse==0);

tabvals1 = [true_pos; false_pos];
tabvals2 = [false_neg; true_neg];
tab = table(tabvals1, tabvals2, 'VariableNames',varnames, 'RowNames',rownames)

temp =table2array(tab);
txt = sprintf('%s\t%s\t%s\n','X', 'Yes','No');
fprintf(out_txt, '%s', txt);
txt = sprintf('%s\t%i\t%i\n','Yes', temp(1,1),temp(1,2));
fprintf(out_txt, '%s', txt);
txt = sprintf('%s\t%i\t%i\n','No', temp(2,1),temp(2,2));
fprintf(out_txt, '%s', txt);

txt = sprintf('\nNo Response: %i',no_resp)   ;
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Overall Accuracy: %i%%\n',round(mean(Accuracy(CueCond==1))*100));
fprintf('%s',txt);
fprintf(out_txt, '%s\n', txt);
    
disp('-----------------------------------------')
disp('Hand Trials - No TMS---------------------')
disp('-----------------------------------------')    
txt = sprintf('\nHand Trials - No TMS\n');
fprintf(out_txt, '%s\n', txt);
true_pos = sum(CueCond==0 & TapCond>0 & Accuracy==1 & TMSCond==0);
true_neg = sum(CueCond==0 & TapCond==0 & Accuracy==1 & TMSCond==0);
false_pos = sum(CueCond==0 & TapCond==0 & Accuracy==0 & YesResponse==1 & TMSCond==0);
false_neg = sum(CueCond==0 & TapCond>0 & Accuracy==0 & NoResponse==1 & TMSCond==0);
no_resp = sum(CueCond==0 & YesResponse==0 & NoResponse==0 & TMSCond==0);

tabvals1 = [true_pos; false_pos];
tabvals2 = [false_neg; true_neg];
tab = table(tabvals1, tabvals2, 'VariableNames',varnames, 'RowNames',rownames)

temp =table2array(tab);
txt = sprintf('%s\t%s\t%s\n','X', 'Yes','No');
fprintf(out_txt, '%s', txt);
txt = sprintf('%s\t%i\t%i\n','Yes', temp(1,1),temp(1,2));
fprintf(out_txt, '%s', txt);
txt = sprintf('%s\t%i\t%i\n','No', temp(2,1),temp(2,2));
fprintf(out_txt, '%s', txt);

txt = sprintf('\nNo Response: %i',no_resp)   ;
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Overall Accuracy: %i%%\n',round(mean(Accuracy(CueCond==0 & TMSCond==0))*100));
fprintf('%s',txt);
fprintf(out_txt, '%s\n', txt);
   
disp('-----------------------------------------')
disp('Hand Trials - TMS 100ms------------------')
disp('-----------------------------------------')  
txt = sprintf('\nHand Trials - TMS 100ms\n');
fprintf(out_txt, '%s\n', txt);
true_pos = sum(CueCond==0 & TapCond>0 & Accuracy==1 & TMSCond==1);
true_neg = sum(CueCond==0 & TapCond==0 & Accuracy==1 & TMSCond==1);
false_pos = sum(CueCond==0 & TapCond==0 & Accuracy==0 & YesResponse==1 & TMSCond==1);
false_neg = sum(CueCond==0 & TapCond>0 & Accuracy==0 & NoResponse==1 & TMSCond==1);
no_resp = sum(CueCond==0 & YesResponse==0 & NoResponse==0 & TMSCond==1);

tabvals1 = [true_pos; false_pos];
tabvals2 = [false_neg; true_neg];
tab = table(tabvals1, tabvals2, 'VariableNames',varnames, 'RowNames',rownames)

temp =table2array(tab);
txt = sprintf('%s\t%s\t%s\n','X', 'Yes','No');
fprintf(out_txt, '%s', txt);
txt = sprintf('%s\t%i\t%i\n','Yes', temp(1,1),temp(1,2));
fprintf(out_txt, '%s', txt);
txt = sprintf('%s\t%i\t%i\n','No', temp(2,1),temp(2,2));
fprintf(out_txt, '%s', txt);

txt = sprintf('\nNo Response: %i',no_resp)   ;
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Overall Accuracy: %i%%\n',round(mean(Accuracy(CueCond==0  & TMSCond==1))*100));
fprintf('%s',txt);
fprintf(out_txt, '%s\n', txt);

disp('-----------------------------------------')
disp('Hand Trials - TMS 25ms-------------------')
disp('-----------------------------------------')    
txt = sprintf('\nHand Trials - TMS 25ms\n');
fprintf(out_txt, '%s\n', txt);
true_pos = sum(CueCond==0 & TapCond>0 & Accuracy==1 & TMSCond==2);
true_neg = sum(CueCond==0 & TapCond==0 & Accuracy==1 & TMSCond==2);
false_pos = sum(CueCond==0 & TapCond==0 & Accuracy==0 & YesResponse==1 & TMSCond==2);
false_neg = sum(CueCond==0 & TapCond>0 & Accuracy==0 & NoResponse==1 & TMSCond==2);
no_resp = sum(CueCond==0 & YesResponse==0 & NoResponse==0 & TMSCond==2);

tabvals1 = [true_pos; false_pos];
tabvals2 = [false_neg; true_neg];
tab = table(tabvals1, tabvals2, 'VariableNames',varnames, 'RowNames',rownames)

temp =table2array(tab);
txt = sprintf('%s\t%s\t%s\n','X', 'Yes','No');
fprintf(out_txt, '%s', txt);
txt = sprintf('%s\t%i\t%i\n','Yes', temp(1,1),temp(1,2));
fprintf(out_txt, '%s', txt);
txt = sprintf('%s\t%i\t%i\n','No', temp(2,1),temp(2,2));
fprintf(out_txt, '%s', txt);

txt = sprintf('\nNo Response: %i',no_resp)   ;
fprintf('%s\n',txt);
fprintf(out_txt, '%s\n', txt);
txt = sprintf('Overall Accuracy: %i%%\n',round(mean(Accuracy(CueCond==0 & TMSCond==2))*100));
fprintf('%s',txt);
fprintf(out_txt, '%s\n', txt);


%% print issues
if look_for_issues > 0
    disp('---------------------')
    disp('Something went wrong')
    disp('---------------------')
    fprintf(out_txt, '%s', '----------------');
    fprintf(out_txt, '%s', '----------------');
    fprintf(out_txt, '%s', 'Something went wrong');
    fprintf(out_txt, '%s', '----------------');
    fprintf(out_txt, '%s', '----------------');
end

fclose all
clear
