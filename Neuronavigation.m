%% Neuronavigation
% Runs through Brainsight output and does the following:
%    - extracts electrode layout and saves it in preproc dir
%    - identifies MEPs (for each MEP it detects, it generates a plot for
%      manual review)
%   - indentifies trials in which the target was missed (3mm)
%   - saves bad trials (MEP or target)in preproc dir

clear
partic = 10;
session = 1;

partic_str = sprintf('%02d', partic);
filedir = strcat('C:\Users\ckohl\Desktop\Data\BETA',partic_str,'\Session',num2str(session),'\');
file_name = strcat('Exported Brainsight Data Session',num2str(session),'.txt');

out_dir =  strcat(filedir,'\Preproc\');
out_txt_overall = fopen(strcat(out_dir,partic_str,'_neuronav_preproc'), 'a');

% SampleName:         Sample Name
% Index:              Index
% AssocTarget:        Target active during this sample
% CrosshairDriver:    Tool tracked during sample (coil)
% LocX/Y/Z:           Coil position at sample
% m0n0/1/2:           Orientation (direction cosine)of the x axis of the coil
% m1n0/1/2:           Orientation (direction cosine)of the y axis of the coil
% m2n0/1/2:           Orientation (direction cosine)of the z axis of the coil
% DisttoTarget:       Straight line distance between coil and target
% TargetError:        The shortest distance from the line projecting into the head along the coil’s path
% AngularError:       The tilt error of the coil 
% Date:               Date
% Time:               Time
% EMGStart:           Time (ms) of EMG sampling before sample (pulse)
% EMGEnd:             Time (ms) of EMG end (trial duration)
% EMGRes:             Time (ms) between EMG samples
% EMGChannels:        Number of active EMG channels
% EMGPeaktopeak1:     Peak-to-peak max value?
% EMGData1:           EMG samples

%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% Get Data
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
fprintf('\n-----------------\n')
fprintf('Load Data')
fprintf('\n-----------------\n')
%First, we'll import the first column to see how many samples there are
opts = delimitedTextImportOptions("NumVariables", 33);
opts.DataLines = [1, Inf];
opts.Delimiter = "\t";
opts.VariableNames = ["SampleName", "Var2", "Var3", "Var4", "Var5", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29", "Var30", "Var31", "Var32", "Var33"];
opts.SelectedVariableNames = "SampleName";
opts.VariableTypes = ["string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string"];
opts = setvaropts(opts, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33], "WhitespaceRule", "preserve");
opts = setvaropts(opts, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33], "EmptyFieldRule", "auto");
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
ExportedBrainsightData = readtable(strcat(filedir,file_name), opts);
firstcolumn_str = table2array(ExportedBrainsightData);

samples_start_row=[];
samples_end_row=[];
targets_start_row=[];
targets_end_row=[];
target_names = {};
elecs_start_row=[];
elecs_end_row = [];
% target_count=struct();
for row=1:size(firstcolumn_str,1)
    if ~isempty(targets_start_row) & isempty(targets_end_row)
        if firstcolumn_str{row}(1) ~='#'
            target_names{end+1}=firstcolumn_str{row};
        end
    end
    if length(firstcolumn_str{row})> 7
        if firstcolumn_str{row}(1:8)=='# Target'
            targets_start_row=row+1;
        end
        if all(firstcolumn_str{row}(1:8)=='# Sample') & all(firstcolumn_str{row+1}(1:7)=='Sample ')
            samples_start_row=row+1;
            targets_end_row=row-1;
        end
        if firstcolumn_str{row}(1:8)=='# Electr'
            samples_end_row = row-1;
            elecs_start_row =  row+1;
        end
        if ~isempty(elecs_start_row) & row>elecs_start_row & firstcolumn_str{row}(1)=='#' & isempty(elecs_end_row)
            elecs_end_row =row-1;
        end
   end
end
fprintf('Sample Detection successful \n')
txt = sprintf('%i Samples detected \n',samples_end_row-samples_start_row+1);
fprintf(txt)
fprintf(out_txt_overall, '%s \n', txt); 
fprintf('Electrode Detection successful \n')
txt = sprintf('%i Electrodes detected \n',elecs_end_row-elecs_start_row+1);
fprintf(txt)
fprintf(out_txt_overall, '%s \n', txt); 

% get column headers
opts = delimitedTextImportOptions("NumVariables", 33);
opts.DataLines = [samples_start_row-1, samples_start_row-1];
opts.Delimiter = "\t";
ExportedBrainsightData = readtable(strcat(filedir,file_name), opts);
column_headers = table2array(ExportedBrainsightData);
%chnage names so they can be valid variable names
for header=1:length(column_headers)
    column_headers{header}(column_headers{header}==' ')=[];
    column_headers{header}(column_headers{header}=='.')=[];
    column_headers{header}(column_headers{header}=='#')=[];
    column_headers{header}(column_headers{header}=='-')=[];    
end

% get data (loop through columns)
opts.VariableNames = column_headers;
for columns=1:length(column_headers)
    if columns>1 & columns <14
        opts.DataLines = [targets_start_row, targets_end_row];
        opts.SelectedVariableNames=column_headers{columns};
        tbls = readtable(strcat(filedir,file_name), opts); 
        tbls = table2array(tbls);
        try
            eval(strcat('Target_',column_headers{columns+3}, ' =  double(tbls);'))
        catch
            for i=1:length(tbls)
                mat(i,1)=str2num(tbls{i});
            end
            eval(strcat('Target_',column_headers{columns+3}, ' =  mat;'))
        end
    end
    opts.DataLines = [samples_start_row, samples_end_row];
    opts.SelectedVariableNames=column_headers{columns};
    tbls = readtable(strcat(filedir,file_name), opts); 
    tbls = table2array(tbls);
    if any(columns==[ 3,5:20,28:32])
        try
         eval(strcat(column_headers{columns}, ' =  double(tbls);'))
        catch
            for i=1:length(tbls)
                if isempty(str2num(tbls{i}))
                   mat(i,1)=nan;
                else
                    mat(i,1)=str2num(tbls{i});
                end
            end
            eval(strcat(column_headers{columns}, ' =  mat;'))
        end
    else
        eval(strcat(column_headers{columns}, ' =  tbls;'))
    end      
end

%% make this data a bit more agreeable
LocStruct =struct();
LocStruct.Mat = [LocX,LocY,LocZ,m0n0,m0n1,m0n2,m1n0,m1n1,m1n2,m2n0,m2n1,m2n2];
LocStruct.Label={'LocX','LocY','LocZ','m0n0','m0n1','m0n2','m1n0','m1n1','m1n2','m2n0','m2n1','m2n2'};

ErrStruct = struct();
ErrStruct.Mat=[DisttoTarget,TargetError,AngularError,TwistError];
ErrStruct.Label={'DisttoTarget','TargetError','AngularError','TwistError'};

TimeStruct=struct();
TimeStruct.Mat=[Date,Time];
TimeStruct.label={'Date','Time'};

EMGStruct=struct();
EMGStruct.Mat = [EMGPeaktopeak1,EMGData1];
EMGStruct.Meta = [EMGStart(1) EMGEnd(1) EMGRes(1)];
EMGStruct.Label = {'Peaktopeak','Data'};

%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% Get Electrodes
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
Electrode_Layout = struct();
opts = delimitedTextImportOptions("NumVariables", 37);
opts.DataLines = [elecs_start_row, elecs_end_row];
opts.Delimiter = "\t";
ElectrodeLabels = readmatrix(strcat(filedir,file_name), opts);
ElectrodeLabs = {};
for elec = 1:length(ElectrodeLabels)
    ElectrodeLabs{elec} = ElectrodeLabels{elec,1};
end
Electrode_Layout.Labels = ElectrodeLabs;
opts.VariableNames = ["Var1", "Var2", "Var3", "AssocTarget", "LocX", "LocY", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29", "Var30", "Var31", "Var32", "Var33", "Var34", "Var35", "Var36", "Var37"];
opts.SelectedVariableNames = ["AssocTarget", "LocX", "LocY"];
opts.VariableTypes = ["char", "char", "char", "double", "double", "double", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char", "char"];
opts = setvaropts(opts, ["Var1", "Var2", "Var3", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29", "Var30", "Var31", "Var32", "Var33", "Var34", "Var35", "Var36", "Var37"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var1", "Var2", "Var3", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19", "Var20", "Var21", "Var22", "Var23", "Var24", "Var25", "Var26", "Var27", "Var28", "Var29", "Var30", "Var31", "Var32", "Var33", "Var34", "Var35", "Var36", "Var37"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "AssocTarget", "TrimNonNumeric", true);
opts = setvaropts(opts, "AssocTarget", "ThousandsSeparator", ",");
ElectrodeLocs = readtable(strcat(filedir,file_name), opts);
ElectrodeLocs = table2array(ElectrodeLocs);
clear opts
Electrode_Layout.Locations = ElectrodeLocs;
cd(strcat(filedir,'\Preproc\'))
save('Electrode_Layout','Electrode_Layout')
fprintf('\nElectrode Layout saved.\n')
    
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% Match Trials
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
Trial =[];
Expected_pulses = 480;
if length(Time) == Expected_pulses
    fprintf('Expected number of pulses detected (%i)\n',Expected_pulses)
else
    fprintf('Unexpected Nr of Samples (%i/%i)\n',length(Time),...
    Expected_pulses)
    % see how many pulses we recorded in EEG (this works only after preproc)
    cd(filedir)
    txt = fopen(strcat('Preproc\',partic_str,'_preproc'));
    txt = textscan(txt,'%s');
    txt = string(txt{:});
    tms_deleted_in_eeg = 0;
    for t = 1:length(txt)
        if txt(t) == 'lonely'
            tms_deleted_in_eeg = str2double(txt(t-1));
            look= 1;
            step=3;
            list = [];
            while look & step < 50
                step = step+1;
                if ~isempty(str2num(txt(t+step)))
                    list = [list, str2num(txt(t+step))];
                else
                    look=0;
                end
            end
        end
        if txt(t)=='pulse'
            tms_in_eeg = str2double(txt(t-1));
        end
    end
    
    if length(Time) ~= tms_in_eeg+tms_deleted_in_eeg
        fprintf('-- Cannot Match Trials --')
        fprintf('\n\tEEG: %i\n\tBrainsight: %i\n\tExpected: %i\n',...
                tms_in_eeg+tms_deleted_in_eeg,...
                length(Time),Expected_pulses)
                brk
    else
        fprintf('EEG and Brainsight samples matched \n')
        fprintf('Deleted %i Brainsight samples ...\n', tms_deleted_in_eeg)
        
        LocStruct.Mat(list,:)=[];
        ErrStruct.Mat(list,:)=[];
        TimeStruct.Mat(list,:)=[];
        EMGStruct.Mat(list,:)=[];
    end
end
            

% now we've matched the number of trials - but don't know what trils they
% are
opts = delimitedTextImportOptions("NumVariables", 11);
opts.DataLines = [6, Inf]; opts.Delimiter = "\t";
opts.VariableNames = ["Trial", "CueCond", "TMSCond", "Var4", "Var5", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11"];
opts.SelectedVariableNames = ["Trial", "CueCond", "TMSCond"];
opts.VariableTypes = ["double", "double", "double", "char", "char", "char", "char", "char", "char", "char", "char"];
opts.ExtraColumnsRule = "ignore";opts.EmptyLineRule = "read";
opts = setvaropts(opts, ["Var4", "Var5", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var4", "Var5", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11"], "EmptyFieldRule", "auto");
beh_results = readtable(strcat(filedir,'BETA',partic_str,'_results'), opts);
beh_results = table2array(beh_results);
beh_results = beh_results(:,[1,3]);%gives only trial nr and tms cond
trial_nrs = beh_results(beh_results(:,2)>0); %trial nrs of pulse trial
if length(trial_nrs) ~= Expected_pulses
    fprintf('Unexpected Nr of Samples found in Behavioural Output\n')
    brk
end

EMGData1=EMGStruct.Mat(:,2);
EMGPeaktopeak1=EMGStruct.Mat(:,1);
% Get cont EMG in usable format
EMGData=[];
for trial=1:length(EMGData1)
    if EMGData1{trial}(1:6)~='(null)'
        EMGData(:,trial)=eval(strcat('[',EMGData1{trial},']'));
    end
end
EMGData=EMGData';
cont=input('Press any key to continue');

%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
%% DETECT MEPs
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------

MEP_cutoff = 100;
fprintf('\n-----------------\n')
fprintf('Detect MEPs')
fprintf('\n-----------------\n')
show_only_MEP_trials=1;
figure('units','normalized','outerposition',[0 0 1 1])
look_for_MEP=[20 40];
trial=0;
Goodness_MEP=ones(length((EMGData1)),1);
shown_trial=[];
if iscell(EMGPeaktopeak1)
    EMGPeaktopeak=nan(size(EMGPeaktopeak1));
    for i=1:length(EMGPeaktopeak1)
        if ~isempty(str2num(EMGPeaktopeak1{i}))
            EMGPeaktopeak(i)= str2num(EMGPeaktopeak1{i});
        end
    end
end
EMGPeaktopeak1=EMGPeaktopeak;
while trial<length((EMGData1))
    trial=trial+1;
    MEP_detected=0;
    EMG_detected=0;
    time=EMGStruct.Meta(1):EMGStruct.Meta(3):EMGStruct.Meta(2);
    clf
    hold on
    plot(time,EMGData(trial,:),'k','Linewidth',2)
    ylabel('Amplitude') 
    xlabel('Time (ms)')
    y=ylim;
    if sum(EMGData(trial,:))==0
        dim=[.4 .2 .5 .5];
        b=annotation('textbox',dim,'String','No EMG detected');
        b.FontSize=20;
        b.Color='r';
        b.EdgeColor='None';
        input_str_temp=' BAD ';
    else    
        EMG_detected=1;
        plot([0 0], ylim,'Linewidth',2','Color',[.5 .5 .5], 'LineStyle','--')

        % find peaks overall
        [all_min all_min_i]= min(EMGData(trial, :));
        [all_max all_max_i]= max(EMGData(trial, :));
        plot(time(all_min_i),all_min,'bo','Linewidth',2,'MarkerSize',10)
        plot(time(all_max_i),all_max,'bo','Linewidth',2,'MarkerSize',10)  
        % find peaks in MEP time window
        MEP_time_i=find(round(time)==look_for_MEP(1),1) : find(round(time)==look_for_MEP(2),1);
        [MEP_min MEP_min_i]= min(EMGData(trial, MEP_time_i));
        [MEP_max MEP_max_i]= max(EMGData(trial, MEP_time_i));
        if MEP_max-MEP_min>MEP_cutoff
            col='r';
        else
            col='g';
        end
        plot(time(MEP_time_i(1)-1+MEP_min_i),MEP_min,'o','Linewidth',2,'MarkerSize',10,'Color',col)
        plot(time(MEP_time_i(1)-1+MEP_max_i),MEP_max,'o','Linewidth',2,'MarkerSize',10,'Color',col)
        %textbox
        p2p_text=sprintf('PeaktoPeak:\n\n MEP window: \t %3.2f \n Overall: \t %3.2f \n Recorded: \t %3.2f',MEP_max-MEP_min,all_max-all_min, EMGPeaktopeak1(trial));
        dim=[.6 .6 .15 .2];
        b=annotation('textbox',dim,'String',p2p_text);
        b.FontSize=14;
        b.BackgroundColor=[1 1 1];
        if any([MEP_max-MEP_min EMGPeaktopeak1(trial)]>MEP_cutoff)
            MEP_detected=1;
            b.Color='r';
            input_str_temp=' MEP ';
        else
            input_str_temp=' OK ';
        end
    end
    title(strcat('Sample ',num2str(Index(trial))))
    in=[];
    if show_only_MEP_trials==0 | (show_only_MEP_trials==1 & MEP_detected==1)
        h=area(look_for_MEP(1):look_for_MEP(2), ones(1,length(look_for_MEP(1):look_for_MEP(2))).*y(2),y(1));
        h.FaceColor=[0.6 0.6 0.6];
        h.EdgeColor='none';
        drawnow; pause(0.05);
        h.Face.ColorType = 'truecoloralpha';
        h.Face.ColorData(4) = 255 * 0.3;
        plot(time,EMGData(trial,:),'k','Linewidth',2)
        drawnow()
        shown_trial=[shown_trial,trial];
        input_str=sprintf('Classification: %s \nConfirm: Enter \nChange: 0/1 \nBack to last sample: 5 \n\nInput:',input_str_temp);
        in=input(input_str);
    end
    if (isempty(in)& MEP_detected) |   (isempty(in)& EMG_detected==0)
        Goodness_MEP(trial)=0;
    elseif in==0
        Goodness_MEP(trial)=0;
        fprintf('Classification changed to ''MEP''(0)\n')
    elseif in==1
        Goodness_MEP(trial)=1;
        fprintf('Classification changed to ''OK''(0)\n')
    elseif  in==5
        if show_only_MEP_trials==0
            trial=trial-2;
        else
            trial=shown_trial(end-1)-1;
        end
    end
end

close all
fprintf('MEP Review done. \n')
txt = sprintf('%d MEPs detected.\n',sum(Goodness_MEP==0 ));
fprintf(txt)
fprintf(out_txt_overall, '%s \n', txt); 
txt = sprintf('Percentage of bad TMS trials (MEP): %2.2f \n',(1-mean(Goodness_MEP))*100);
fprintf(txt)
fprintf(out_txt_overall, '%s \n', txt); 
txt = sprintf('Percentage of bad TMS trials overall (MEP): %2.2f\n',(sum(Goodness_MEP==0 )/720)*100);
fprintf(txt)
fprintf(out_txt_overall, '%s \n', txt); 

%save list of trial with MEPs
bad_trials_mep = trial_nrs(Goodness_MEP==0);
out_dir =  strcat(filedir,'\Preproc\');
out_txt = fopen(strcat(out_dir,partic_str,'_MEP_trials'), 'a');
fprintf(out_txt_overall, '\nTrials: \n');
for trial = 1:length(bad_trials_mep)
    fprintf(out_txt, '%i \n', bad_trials_mep(trial));
    fprintf(out_txt_overall, '%i \n', bad_trials_mep(trial)); 
end
fclose(out_txt);

cont=input('Press any key to continue');

    
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------    
%% Find missed pulses
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
fprintf('\n-----------------\n')
fprintf('Find pulses which did not hit the target')
fprintf('\n-----------------\n')

Target_cutoff = 3;
% hist(TargetError)
bad_trials_target = trial_nrs(TargetError>Target_cutoff);
txt = sprintf('\n%d trials in which target was missed detected.\n',length(bad_trials_target));
fprintf(txt)
fprintf(out_txt_overall, '%s \n', txt); 
txt = sprintf('Percentage of bad TMS trials (Target): %2.2f\n',(length(bad_trials_target)/Expected_pulses)*100);
fprintf(txt)
fprintf(out_txt_overall, '%s \n', txt); 
txt = sprintf('Percentage of bad TMS trials overall (MEP): %2.2f\n',(length(bad_trials_target)/720)*100);
fprintf(txt)
fprintf(out_txt_overall, '%s \n', txt); 

%save list of trial with missed targets
out_dir =  strcat(filedir,'\Preproc\');
out_txt = fopen(strcat(out_dir,partic_str,'_missed_target_trials'), 'a');
fprintf(out_txt_overall, '\nTrials: \n'); 
for trial = 1:length(bad_trials_target)
    fprintf(out_txt, '%i \n', bad_trials_target(trial)); 
    fprintf(out_txt_overall, '%i \n', bad_trials_target(trial)); 
end
fclose(out_txt);
fclose(out_txt_overall);


fprintf('\nAll done\n')
