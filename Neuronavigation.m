%based on Import_BrainSight.m (alo BrainSight_get_stimlocs.m?)
% BrainSight spits out a text file - let's see what we can do with it
clear

partic = 2;
partic_str = sprintf('%02d', partic);
filedir = strcat('C:\Users\ckohl\Desktop\Data\Pilot\Beta',partic_str);
file_name = '\Exported Brainsight Data run3.txt'


% write_to_file=1;
% output_dir=filedir;

% 
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

% t=1;
%  temp=[Target_m0n0(t),Target_m1n0(t),Target_m2n0(t),Target_LocX(t);...
%     Target_m0n1(t),Target_m1n1(t),Target_m2n1(t),Target_LocY(t);...
%     Target_m0n2(t),Target_m1n2(t),Target_m2n2(t),Target_LocZ(t);0 0 0 1]
% 
% 
%  temp=[ m0n0(t), m1n0(t), m2n0(t), LocX(t);...
%      m0n1(t), m1n1(t), m2n1(t), LocY(t);...
%      m0n2(t), m1n2(t), m2n2(t), LocZ(t);0 0 0 1]
% temp*

% 
% %Output file:
% if write_to_file
%     output_file=fopen(strcat(output_dir,'\BETA',num2str(partic),'_BrainSight_output.txt'),'a');
%     fprintf(output_file, 'BrainSight data processed by ''Import_Brainsight.m''\r\n \r\n%s ', datestr(now));
% end
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
        elseif ~isempty(elecs_start_row) & firstcolumn_str{row}(1)=='#'
            elecs_end_row =row-1;
        end
   end
end
fprintf('Sample Detection successful \n')
fprintf('%i Samples detected \n',samples_end_row-samples_start_row+1)
fprintf('Electrode Detection successful \n')
fprintf('%i Electrodes detected \n',elecs_end_row-elecs_start_row+1)

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

%% make this data a bit more agrreable
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
% Match Trials
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
                error out
    else
        fprintf('EEG and Brainsight samples matched \n')
        fprintf('Deleted %i Brainsight samples ...\n', tms_deleted_in_eeg)
        
        LocStruct.Mat(list,:)=[];
        ErrStruct.Mat(list,:)=[];
        TimeStruct.Mat(list,:)=[];
        EMGStruct.Mat(list,:)=[];
    end
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
% DETECT MEPs
%% ------------------------------------------------------------------------
%% ------------------------------------------------------------------------
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
        if MEP_max-MEP_min>100
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
        if any([MEP_max-MEP_min EMGPeaktopeak1(trial)]>100)
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
fprintf('MEP Review done. \n%d MEPs detected.\n',sum(Goodness_MEP==0 ))

cont=input('Press any key to continue');

%     
% %% ------------------------------------------------------------------------
% %% ------------------------------------------------------------------------    
% %% Define target
% %% ------------------------------------------------------------------------
% %% ------------------------------------------------------------------------
% fprintf('\n-----------------\n')
% fprintf('Define Targets')
% fprintf('\n-----------------\n')
% % % First, check if all triple-pulses had the same target
% % targets_detected={};
% % for trial=1:length(AssocTarget)
% %     if Pulse_ID(trial)>0
% %         targets_detected{end+1}=AssocTarget{trial};
% %     end
% % end
% % First, check if all -pulses had the same target
% targets_detected={};
% for trial=1:length(AssocTarget)
%     targets_detected{end+1}=AssocTarget{trial};
% end
% [targets_detected,temp,target_count]=unique(targets_detected);
% if length(targets_detected)>1
%     fprintf('More than one target detected during triple pulses:\n')
%     for i=1:length(targets_detected)
%         fprintf('\t(%d) %s (%d) \n',i,targets_detected{i},sum(target_count==i));
%     end
%     chosen_target=input('Pick target: ');
%     target_oi=targets_detected{chosen_target};
% else
%     fprintf('Target:\n\t%s\n',targets_detected{1})
%     target_oi=targets_detected{1};
% end
% 
% for i=1:length(target_names)
%     if length(target_names{i}(~isspace(target_names{i})))==length(target_oi(~isspace(target_oi)))
%         if all(target_names{i}(~isspace(target_names{i}))==target_oi(~isspace(target_oi)))
%             target_i=i;
%         end
%     end
% end
% T_X=Target_LocX(target_i);
% T_Y=Target_LocY(target_i);
% T_Z=Target_LocZ(target_i);
% 
% Target_vector=zeros(size(AssocTarget));
% for trial=1:length(AssocTarget)
%     if length(AssocTarget{trial})==length(target_oi)
%         if AssocTarget{trial}== target_oi
%             Target_vector(trial)=1;
%         end
%     end
% end
% 
% cont=input('Press any key to continue');
% 
% %% ------------------------------------------------------------------------
% %% ------------------------------------------------------------------------    
% %% Target Error
% %% ------------------------------------------------------------------------
% %% ------------------------------------------------------------------------
% fprintf('\n-----------------\n')
% fprintf('Inspect Coil Location')
% fprintf('\n-----------------\n')
% cutoff1=1;%1std away from mean
% cutoff2=2;
% %based on target error
% Goodness_coil=ones(size(TargetError));
% medgoodness_coil=ones(size(TargetError));
% medgoodness_coil(abs(TargetError)>abs(mean(TargetError(Target_vector==1 & Pulse_ID>0)))+abs(std(TargetError(Target_vector==1 & Pulse_ID>0)).*cutoff1))=0;
% Goodness_coil(logical(abs(TargetError)>abs(mean(TargetError(Target_vector==1 & Pulse_ID>0)))+abs(std(TargetError(Target_vector==1 & Pulse_ID>0)).*cutoff2)))=0;
% 
% thisX=LocX;
% thisX(Pulse_ID==0 | Target_vector==0)=nan;
% thisY=LocY;
% thisY(Pulse_ID==0 | Target_vector==0)=nan;
% thisZ=LocZ;
% thisZ(Pulse_ID==0 | Target_vector==0)=nan;
% figure
% clf
% subplot(3,2,1)
% t=scatter3(T_X,T_Y,T_Z,'filled');
% t.MarkerEdgeColor='k';
% hold on
% a=scatter3(thisX(medgoodness_coil==1),thisY(medgoodness_coil==1),thisZ(medgoodness_coil==1))  ; 
% a.MarkerEdgeColor=[.344 .906 .344];
% a.LineWidth=1;
% b=scatter3(thisX(medgoodness_coil==0),thisY(medgoodness_coil==0),thisZ(medgoodness_coil==0))  ; 
% b.MarkerEdgeColor=[1 .625 .25];
% b.LineWidth=1;
% c=scatter3(thisX(Goodness_coil==0),thisY(Goodness_coil==0),thisZ(Goodness_coil==0))  ; 
% c.MarkerEdgeColor=[.75 0 0];
% c.LineWidth=1;
% title('Target Error')
% sum_tarer=sum(Goodness_coil==0);
% 
% %based on angular error
% tmp_Goodness_coil=ones(size(TargetError));
% tmp_medgoodness_coil=ones(size(TargetError));
% tmp_medgoodness_coil(abs(AngularError)>abs(mean(AngularError(Target_vector==1 & Pulse_ID>0)))+abs(std(AngularError(Target_vector==1 & Pulse_ID>0)).*cutoff1))=0;
% tmp_Goodness_coil(logical(abs(AngularError)>abs(mean(AngularError(Target_vector==1 & Pulse_ID>0)))+abs(std(AngularError(Target_vector==1 & Pulse_ID>0)).*cutoff2)))=0;
% subplot(3,2,2)
% scatter3(T_X,T_Y,T_Z,'filled')
% hold on
% a=scatter3(thisX(tmp_medgoodness_coil==1),thisY(tmp_medgoodness_coil==1),thisZ(tmp_medgoodness_coil==1))  ; 
% a.MarkerEdgeColor=[.344 .906 .344];
% a.LineWidth=1;
% b=scatter3(thisX(tmp_medgoodness_coil==0),thisY(tmp_medgoodness_coil==0),thisZ(tmp_medgoodness_coil==0))  ; 
% b.MarkerEdgeColor=[1 .625 .25];
% b.LineWidth=1;
% c=scatter3(thisX(tmp_Goodness_coil==0),thisY(tmp_Goodness_coil==0),thisZ(tmp_Goodness_coil==0))  ; 
% c.MarkerEdgeColor=[.75 0 0];
% c.LineWidth=1;
% title('Angular Error')
% sum_anger=sum(tmp_Goodness_coil==0);
% 
% %both
% Goodness_coil(tmp_Goodness_coil==0)=0;
% medgoodness_coil(tmp_medgoodness_coil==0)=0;
% subplot(3,2,3:6)
% scatter3(T_X,T_Y,T_Z,'filled')
% hold on
% a=scatter3(thisX(medgoodness_coil==1),thisY(medgoodness_coil==1),thisZ(medgoodness_coil==1))  ; 
% a.MarkerEdgeColor=[.344 .906 .344];
% a.LineWidth=1;
% b=scatter3(thisX(medgoodness_coil==0),thisY(medgoodness_coil==0),thisZ(medgoodness_coil==0))  ; 
% b.MarkerEdgeColor=[1 .625 .25];
% b.LineWidth=1;
% c=scatter3(thisX(Goodness_coil==0),thisY(Goodness_coil==0),thisZ(Goodness_coil==0))  ; 
% c.MarkerEdgeColor=[.75 0 0];
% c.LineWidth=1;
% title('Combined Error')
% 
% fprintf('Trials lost due to Coil error: %d \n\t Target Error: %d \n\t Angular Error: %d\n',sum(Goodness_coil==0),sum_tarer, sum_anger)
% 
% cont=input('Press any key to continue');
% close('all')
% 
% %% ------------------------------------------------------------------------
% %% ------------------------------------------------------------------------    
% %% Pick valid trials
% %% ------------------------------------------------------------------------
% %% ------------------------------------------------------------------------
% % trial valid if: part of triple, all pulses in triple detected and ok,
% % correct target, no MEP, no Coil error
% 
% Trial=nan(size(AssocTarget));
% good_trial_count=0;
% triplet_target_count=0;
% triplet_target_emg_count=0;
% for trial=1:length(AssocTarget)-2
%     if Target_vector(trial)==1 & Target_vector(trial+1)==1 & Target_vector(trial+2)==1 & Pulse_ID(trial)==1 & Pulse_ID(trial+1)==2 & Pulse_ID(trial+2)==3
%         triplet_target_count=triplet_target_count+1;
%         if Goodness_MEP(trial)==1 & Goodness_MEP(trial+1)==1 & Goodness_MEP(trial+2)==1
%             triplet_target_emg_count=triplet_target_emg_count+1;
%             if Goodness_coil(trial)==1 & Goodness_coil(trial+1)==1 &Goodness_coil(trial+2)==1
%                 good_trial_count=good_trial_count+1;
%                 Trial(trial:trial+2)=good_trial_count;
%             end
%         end
%     end
% end
% 
% fprintf('\n-----------------\n');
% fprintf('Original Nr of trials (triple-pulse sets in %s): %d\n',target_oi,triplet_target_count);
% fprintf('\t Trials Lost due to MEP: %d (%d pulses) \n',triplet_target_count-triplet_target_emg_count, sum(Pulse_ID>0 & Goodness_MEP==0));
% fprintf('\t Trials Lost due to Coil Location: %d \n',triplet_target_emg_count - good_trial_count);
% fprintf('\n-----------------\n');
% fprintf('Remaining Nr of trials (triple-pulse sets): %d',good_trial_count);
% fprintf('\n-----------------\n');
% 
% 
%  if write_to_file
%      fprintf(output_file,'\n\n-Summary-\n');
%      fprintf(output_file,'Session Date: %s\n', Date{1});
%      fprintf(output_file,'Target: %s\n',target_oi);
%      fprintf(output_file,'Original Nr of trials (triple-pulse sets in %s): %d\n',target_oi,triplet_target_count);
%      fprintf(output_file,'Trials Lost due to MEP: %d (%d pulses) \n',triplet_target_count-triplet_target_emg_count, sum(Pulse_ID>0 & Goodness_MEP==0));
%      fprintf(output_file,'Trials Lost due to Coil Location: %d \n',triplet_target_emg_count - good_trial_count);
%      fprintf(output_file,'Remaining Nr of trials (triple-pulse sets): %d',good_trial_count);
%      fprintf(output_file,'\n\n-Samples-\n');
%      fprintf(output_file, 'Sample\tGood\tTrial\tTriple\tTarget\tEMG\tCoilErr\n');
%      for s=1:length(SampleName)
%         fprintf(output_file,'%d\t%d\t%d\t%d\t%d\t%d\t%d\n',s,~isnan(Trial(s)),Trial(s),(Pulse_ID(s)>0),Target_vector(s),Goodness_MEP(s),Goodness_coil(s));
%      end
%   end
% 
%     
% 
%     
%     
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% % 
% %     
% %     
% % figure
% % clf
% % hold on
% % cut_off1=1;%1std away from mean
% % cutt_off2=2;
% % for trial=1:length(AssocTarget)
% %     err=0;
% %     if abs(thisX(trial))>abs(mean(thisX))+abs(std(thisX).*cut_off1) | abs(thisY(trial))>abs(mean(thisY))+abs(std(thisY).*cut_off1)  |abs(thisZ(trial))>abs(mean(thisZ))+abs(std(thisZ).*cut_off1) 
% %         err=1;
% %         if 
% %         
% %         
% % scatter3(T_X,T_Y,T_Z,'filled')
% % scatter3(thisX,thisY,thisZ)           
% %     
% % fieldtrip_dir='C:\Users\ckohl\Documents\fieldtrip-20190802\fieldtrip-20190802';
% % cd(fieldtrip_dir)
% % ft_defaults
% % % need to unzip this yourself first!
% % mri=ft_read_mri(strcat(mri_dir,'Beta',num2str(partic),'\MRI\Beta',num2str(partic),'_nifti.nii'))
% %       
% %     if length(unique(mri.dim))>1
% %         cfg=[];
% %         mri=ft_volumereslice(cfg,mri);
% %     end
% % 
% % 
% % cfg = [];
% % cfg.fiducial.nas=[-4.084	-109.471	-11.945]
% % cfg.fiducial.lpa=[74.090	-17.413	-48.189]
% % cfg.fiducial.rpa=[-75.596	-12.740	-47.676]
% % cfg.fiducial.zpoint=[34.242	18.824	64.882];
% % cfg.method = 'fiducial';
% % cfg.viewresult ='yes';
% % [mri] = ft_volumerealign(cfg, mri);
% % 
% % 
% %     tic
% %     cfg = [];
% %     cfg.output = {'brain','skull','scalp'};
% %     segmentedmri = ft_volumesegment(cfg, mri);
% %     toc
% % 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% % AssocTarget:        Target active during this sample
% % CrosshairDriver:    Tool tracked during sample (coil)
% % LocX/Y/Z:           Coil position at sample
% % m0n0/1/2:           Orientation (direction cosine)of the x axis of the coil
% % m1n0/1/2:           Orientation (direction cosine)of the y axis of the coil
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
