%% Sanitycheck all behavioural output and print performance
clear


session = 1;
Partics = [7, 9,10,11,12]
% 
% session = 0;
% Partics = [9,10,11,14,22]

KEEP_ACC = struct();
KEEP_RT = struct();
pcount=0;
for partic = Partics
    pcount=pcount+1;

partic_str = sprintf('%02d', partic);
filedir = strcat('C:\Users\ckohl\Desktop\Data\Beta',partic_str,'\Session',num2str(session));
file=strcat(filedir, '\beta',partic_str,'_results');
file2=strcat(filedir, '\beta_',partic_str,'_results');

% set up output
look_for_issues = 0;
%% load behavioural data
opts = delimitedTextImportOptions("NumVariables", 11);
opts.DataLines = [6, Inf];
opts.Delimiter = "\t";
opts.VariableNames = ["Trial", "CueCond", "TMSCond", "TapCond", "Accuracy", "YesResponse", "NoResponse", "TapTime", "TMSTime", "RT", "Threshold"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
try
    tbl = readtable(file, opts);
catch
    tbl = readtable(file2, opts);
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
RT = tbl.RT;
Threshold = tbl.Threshold;
clear opts tbl

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

txt = sprintf('No response in %i out of %i trials',sum(RT==0),length(RT));
fprintf('%s\n',txt);

rt = RT(RT>0);
txt = sprintf('Mean RT: %2.2f (%2.2f)',mean(rt),std(rt));
fprintf('%s\n',txt);

txt = sprintf('Max RT: %2.2f, Min RT %2.2f',max(rt),min(rt));
fprintf('%s\n',txt);

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

txt = sprintf('Mean Threshold: %2.2f (%2.2f)',mean(Threshold),std(Threshold));
fprintf('%s\n',txt);

txt = sprintf('Max Threshold: %2.2f, Min Threshold %2.2f',max(Threshold),min(Threshold));
fprintf('%s\n',txt);

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

if prob==0
    txt = sprintf('Threshold Updating fine');
    fprintf('%s\n',txt);

end
look_for_issues = look_for_issues+prob;

%% check performance 
% thresh should be harder ad slower than supra

disp ('------------------------------')
disp('check performance')
disp ('------------------------------')    
disp(' ')

txt = sprintf('\nDetecting Taps -  overall\n');
fprintf('%s',txt);

txt = sprintf('Null Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==0 & CueCond==0))*100), round(mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1))));
fprintf('%s\n',txt);

txt = sprintf('Threshold Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==1 & CueCond==0))*100), round(mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1))));      
fprintf('%s\n',txt);

txt = sprintf('Supra Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==2 & CueCond==0))*100), round(mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1))));      
fprintf('%s\n',txt);


txt = sprintf('\nDetecting TMS -  overall\n');
fprintf('%s',txt);

txt = sprintf('Null TMS:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TMSCond==0 & CueCond==1))*100), round(mean(RT(TMSCond==0 & CueCond==1 & Accuracy ==1)))) ;     
fprintf('%s\n',txt);

txt = sprintf('TMS100:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TMSCond==1 & CueCond==1))*100), round(mean(RT(TMSCond==1 & CueCond==1 & Accuracy ==1))));      
fprintf('%s\n',txt);

txt = sprintf('TMS25:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TMSCond==2 & CueCond==1))*100), round(mean(RT(TMSCond==2 & CueCond==1 & Accuracy ==1)))) ;
fprintf('%s\n',txt);


txt = sprintf('\nDetecting Taps -  No TMS\n');
fprintf('%s',txt);

txt = sprintf('Null Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==0))*100), round(mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==0))));      
fprintf('%s\n',txt);
KEEP_ACC.NoTMS.Null(pcount) = mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==0));
KEEP_RT.NoTMS.Null(pcount)  = mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==0))./1000;

txt = sprintf('Threshold Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==0))*100), round(mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==0)))) ;     
fprintf('%s\n',txt);
KEEP_ACC.NoTMS.Thresh(pcount)  = mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==0));
KEEP_RT.NoTMS.Thresh(pcount)  = mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==0))./1000;

txt = sprintf('Supra Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==0))*100), round(mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==0))));      
fprintf('%s\n',txt);
KEEP_ACC.NoTMS.Supra(pcount)  = mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==0));
KEEP_RT.NoTMS.Supra(pcount)  = mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==0))./1000;



txt = sprintf('\nDetecting Taps -  100ms\n');
fprintf('%s',txt);

txt = sprintf('Null Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==1))*100), round(mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==1)))) ;     
fprintf('%s\n',txt);
KEEP_ACC.TMS100.Null(pcount)  = mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==1));
KEEP_RT.TMS100.Null(pcount)  = mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==1))./1000;

txt = sprintf('Threshold Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==1))*100), round(mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==1))))  ;    
fprintf('%s\n',txt);
KEEP_ACC.TMS100.Thresh(pcount)  = mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==1));
KEEP_RT.TMS100.Thresh(pcount)  = mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==1))./1000;

txt = sprintf('Supra Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==1))*100), round(mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==0)))); 
fprintf('%s\n',txt);
KEEP_ACC.TMS100.Supra(pcount)  = mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==1));
KEEP_RT.TMS100.Supra(pcount)  = mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==1))./1000;


txt = sprintf('\nDetecting Taps -  25ms\n');
fprintf('%s',txt);

txt = sprintf('Null Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==2))*100), round(mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==2))))  ;    
fprintf('%s\n',txt);
KEEP_ACC.TMS25.Null(pcount)  = mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==2));
KEEP_RT.TMS25.Null(pcount)  = mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==2))./1000;

txt = sprintf('Threshold Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==2))*100), round(mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==2)))) ;     
fprintf('%s\n',txt);
KEEP_ACC.TMS25.Thresh(pcount)  = mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==2));
KEEP_RT.TMS25.Thresh(pcount)  = mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==2))./1000;

txt = sprintf('Supra Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==2))*100), round(mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==2)))) ; 
fprintf('%s\n',txt);
KEEP_ACC.TMS25.Supra(pcount)  = mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==2));
KEEP_RT.TMS25.Supra(pcount)  = mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==2))./1000;



figure
hold on
subplot(1,2,1)
hold on
title('Accuracy')
toplot = [KEEP_ACC.NoTMS.Null(pcount) ,KEEP_ACC.TMS100.Null(pcount) ,KEEP_ACC.TMS25.Null(pcount) ;...
    KEEP_ACC.NoTMS.Supra(pcount) , KEEP_ACC.TMS100.Supra(pcount) ,KEEP_ACC.TMS25.Supra(pcount) ;...
    KEEP_ACC.NoTMS.Thresh(pcount) ,KEEP_ACC.TMS100.Thresh(pcount) ,KEEP_ACC.TMS25.Thresh(pcount) ];
bar(toplot)
set(gca,'XTick',[1,2,3])
set(gca,'xticklabel',{['No Tap'],['Supra Tap'],['Threshold Tap']})
ylabel('Accuracy (proportion correct)')
ylim([0 1])

subplot(1,2,2)
hold on
title('RT')
toplot = [KEEP_RT.NoTMS.Null(pcount) ,KEEP_RT.TMS100.Null(pcount) ,KEEP_RT.TMS25.Null(pcount) ;...
    KEEP_RT.NoTMS.Supra(pcount) , KEEP_RT.TMS100.Supra(pcount) ,KEEP_RT.TMS25.Supra(pcount) ;...
    KEEP_RT.NoTMS.Thresh(pcount) ,KEEP_RT.TMS100.Thresh(pcount) ,KEEP_RT.TMS25.Thresh(pcount) ];
bar(toplot)
ylim([0 1])
legend('NoTMS','TMS100','TMS25')
set(gca,'XTick',[1,2,3])
set(gca,'xticklabel',{['No Tap'],['Supra Tap'],['Threshold Tap']})
ylabel('RT (s)')

cd('C:\Users\ckohl\Desktop\Data\')
print("-dpng",strcat('Partic',num2str(partic),'Sess',num2str(session)))



end



figure
hold on
subplot(1,2,1)
hold on
title('Accuracy')
toplot = [mean(KEEP_ACC.NoTMS.Null) ,mean(KEEP_ACC.TMS100.Null) ,mean(KEEP_ACC.TMS25.Null) ;...
    mean(KEEP_ACC.NoTMS.Supra) , mean(KEEP_ACC.TMS100.Supra) ,mean(KEEP_ACC.TMS25.Supra) ;...
    mean(KEEP_ACC.NoTMS.Thresh) ,mean(KEEP_ACC.TMS100.Thresh) ,mean(KEEP_ACC.TMS25.Thresh) ];
bar(toplot)
set(gca,'XTick',[1,2,3])
set(gca,'xticklabel',{['No Tap'],['Supra Tap'],['Threshold Tap']})
ylabel('Accuracy (proportion correct)')
ylim([0 1])

subplot(1,2,2)
hold on
title('RT')
toplot = [mean(KEEP_RT.NoTMS.Null) ,mean(KEEP_RT.TMS100.Null) ,mean(KEEP_RT.TMS25.Null) ;...
    mean(KEEP_RT.NoTMS.Supra) ,mean(KEEP_RT.TMS100.Supra) ,mean(KEEP_RT.TMS25.Supra) ;...
    mean(KEEP_RT.NoTMS.Thresh) ,mean(KEEP_RT.TMS100.Thresh) ,mean(KEEP_RT.TMS25.Thresh) ];
bar(toplot)
ylim([0 1])
legend('NoTMS','TMS100','TMS25')
set(gca,'XTick',[1,2,3])
set(gca,'xticklabel',{['No Tap'],['Supra Tap'],['Threshold Tap']})
ylabel('RT (s)')




