function Task(trialmultiplier,subj_str,output_directory, SerialPortObj,windowPtr,black, white, red, green,x_centre, y_centre, da, dd, sinewave,detection_threshold,myMS,yes_button,no_button,operator_button,active,subj_intensity,supra)
% %% Stuff that should go in the wrapper:
%     subj='Steph';
%     subj_intensity = 0;
%     
%     %% Setup
%     %%Psychtoolbox
%     Screen('Preference', 'SkipSyncTests', 1);
%     PsychDefaultSetup(2); %default PTB setup
%     screens = Screen('Screens'); %get screen numbers
%     screenNumber = max(screens); %get max screen
%     black = [0 0 0];
%     white = [255 255 255];
%     red = [255,0,0];
%     green = [0,255,0];    
%     %%Magic
%     myMS = rapid('COM6','SuperPlus','8ec8-d16b8f45-39');
%     %%Serialport
%     SerialPortObj=serial('COM3', 'TimeOut', 1); % in this example x=3 SerialPortObj.BytesAvailableFcnMode='byte';
%     SerialPortObj.BytesAvailableFcnCount=1; 
%     SerialPortObj.BytesAvailableFcn=@ReadCallback;
%     %% Start (this order matters!)
%     %%Psychtoolbox
%     [windowPtr,rect]=Screen('OpenWindow', screenNumber, black);
%     [x_centre, y_centre]=RectCenter(rect); 
%     %%Magic
%     myMS.connect()
%     %%Serialport
%     fopen(SerialPortObj);
%     %% Other Prep
%     %%Serialport
%     fwrite(SerialPortObj, 0,'sync');
%     %%Magic
%     myMS.setAmplitudeA(0) 
%     myMS.setChargeDelay(500)
%     myMS.arm()
%     myMS.ignoreCoilSafetyInterlock()
%     myMS.setAmplitudeA(subj_intensity) 
%     %%Nidaq
%     da = daq('ni'); %analog - tap
%     dd = daq('ni'); % digital - event
% %     dd2 = daq('ni'); % digital2 - tms
%     addoutput(da, 'Dev1', 'ao0', 'Voltage'); %deliver tap
%     addoutput(dd,'Dev1','port0/line0', 'Digital'); %tap event
% %     addoutput(dd2, 'Dev1','port0/line1', 'Digital'); %deliver TMS
%     %Tap
%     da.Rate = 5000; 
%     dq_dt = 1/da.Rate;
%     freq = 100; phase = 3*pi/2; 
%     time = 0:dq_dt:0.01; %0:0.01 sec in 0.1 msec steps
%     sinewave = sin(2*pi*freq*time + phase)'; 
%     sinewave = sinewave +1;     
%     sinewave(end+1)=0;
    %%Task
    
    
    % Trials
    min_thresh_per_cond = 84;
    total_per_cond = round(min_thresh_per_cond/0.7);
    total_num_trials = total_per_cond*trialmultiplier; 
    

    %% 1) Initialize variables
    %fixation cross 
    cross=30; 
    x_coords=[-cross, cross, 0, 0];
    y_coords=[0, 0, -cross, cross];
    cross_coords=[x_coords; y_coords];
    Screen('DrawLines', windowPtr, cross_coords,2, white, [x_centre, y_centre]);   
    %up cue
    x_coords=[-30,0,0,30];
    y_coords=[-50,-100,-100,-50];
    cue_up_coords=[x_coords; y_coords];
    Screen('DrawLines', windowPtr, cue_up_coords,10, white, [x_centre, y_centre]);   
    %down cue
    cue_down_coords=[x_coords; y_coords*-1];
    Screen('DrawLines', windowPtr, cue_down_coords,10, white, [x_centre, y_centre]); 
    %flip everything
    Screen('Flip', windowPtr);
    KbStrokeWait()
    %% define events
    event_cue = [4 8];
    event_respcue = 16;


    %% trial structure array
    % trials x (#1) CUE attn (0,1) for (hand,head), (#2) ZAP time (0,1,2) 
    % for (null,-100,+25), (#3) TAP intensity (0,1,2) for 
    % (20%null,70%thresh,10%supra) 
    trialArray = zeros(total_num_trials,3);
    halfway_pt = total_num_trials/2; 
    total_per_cond = total_num_trials/6;
    % array to store CUE placeholders (0,1) for (hand, head) at equal proportions
    initial_cueType = [repmat(0,1,round(total_num_trials/2)),repmat(1,1,round(total_num_trials/2))];
    % array to store ZAP placeholders (0,1,2) for (null,-100,+25) at equal proportions
    initial_zapTime = [repmat(0,1,round(halfway_pt/3)),repmat(1,1,round(halfway_pt/3)),repmat(2,1,round(halfway_pt/3))];
    % array to store TAP placeholders (0,1,2) for (null, threshold, supra) at the correct proportions (ie 20%, 70%, 10%)
    initial_tapInt = [repmat(0,1,round(total_per_cond*.2)),repmat(1,1,round(total_per_cond*.7)),repmat(2,1,round(total_per_cond*.1))];
    % cue, zap, tap
    trialArray(:,1) = initial_cueType;
    trialArray(:,2) = repmat(initial_zapTime,1,2);
    trialArray(:,3) = repmat(initial_tapInt,1,6);
    % Shuffle trial structure array
    trialArray_rand = trialArray(randperm(size(trialArray,1)),:);

    %%% save results %%% add intensity
    %%% also print subject in file name - not currently passed 
    task_results = fopen(strcat(output_directory,subj_str,'_results'), 'a');
    task_times = fopen(strcat(output_directory,subj_str,'_times'), 'a');
    fprintf(task_results, '\r\n \r\n %s ', datestr(now)); 
    fprintf(task_results, '\n Session: %i ', active);
    fprintf(task_times, '\r\n \r\n %s ', datestr(now));
    fprintf(task_times, '\n Session: %i ', active);
    fprintf(task_results, strcat('\n Trial\tCueCond\tTMSCond\tTapCond\t',...
            'Accuracy\tYesResponse\tNoResponse\tTapTime\tTMSTime\t',...
            'RT\tThreshold\n'));
    fprintf(task_times, strcat('\n Trial\tCueTime\tTapTime\t',...
             'TMSTimes\tResponseCueTime\n'));

    %define starting tap intensities 
    null = 0.0;
    threshold = detection_threshold;

    response_interval = 1;

    %define tap maxmin %%% 
    threshold_max = 8;
    threshold_min = 0; 
    change = .01;%.005;

    %breaks
    break_trials = 120;
    break_max_time = 30;
    big_breaks = total_num_trials/3;

    %init
    tms_time = zeros(total_num_trials,1);
    tap_time = zeros(total_num_trials,1);
    accuracy = zeros(total_num_trials,1);
    response_cue_time = zeros(total_num_trials,1);
    cue_time = zeros(total_num_trials,1);
    RT = zeros(total_num_trials,1);
    threshold_memory = [];


    %time calibration
    min_tap_delay = 22;
    min_tms_delay = 7;
    min_25_delay = 6;
    min_100_delay = 15;


    %% 4)  Delivery of stimuli (TMS pulses *ZAPs* & tactile stimuli *TAPs*) and participant responses
    if trialmultiplier ==1
        total_num_trials = 10; 
    end

    for i = 1:total_num_trials

        % 1) iterate through trialArray - each line is randomized combo of cue type, zap time, tap intensity
        % 2) display cue stimulus - red cross hair with arrow up or down (hand or head)
        % 3) deliver tap stimulus in fixed interval 1000 ms after presentation of cue
        % 4) deliver TMS (null, 100 msec *before* tap, OR 25 msec *after* tap)
        % 6) display green crosshair 1000 ms after tap - cue to respond
        % 7) gives user up to 1 s for response y or n
        % 8) Checks to see if the threshold needs to be changed and does so
        % 9) Outputs array of data
        % value to store the changing threshold

        %% select tap intensity  
        if (trialArray_rand(i,3) == 0)
            stimulus = null*sinewave; 
        elseif (trialArray_rand(i,3) == 1)
            stimulus = threshold*sinewave;
        elseif (trialArray_rand(i,3) == 2)
            stimulus = supra*sinewave;
        end

        %% draw appropriate CUE crosshair & arrow    
        if (trialArray_rand(i,1) == 0) % hand
            %draw cue %% delete nonsense repetitions
            Screen('DrawLines', windowPtr, cross_coords,2, white, [x_centre, y_centre]); 
            Screen('DrawLines', windowPtr, cue_up_coords,10, white, [x_centre, y_centre]);
            Screen('DrawLines', windowPtr, cue_down_coords,10, red, [x_centre, y_centre]); 
            %flip everything
            Screen('Flip', windowPtr);
            % Record event (trigger box) cue event = 'S 4' 
            fwrite(SerialPortObj, event_cue(trialArray_rand(i,1)+1),'sync');
            fwrite(SerialPortObj, 0,'sync');
            cue_time(i) = GetSecs;

        elseif (trialArray_rand(i,1) == 1) % head
            %draw fixation cross
            Screen('DrawLines', windowPtr, cross_coords,2, white, [x_centre, y_centre]); 
            Screen('DrawLines', windowPtr, cue_up_coords,10, red, [x_centre, y_centre]);
            Screen('DrawLines', windowPtr, cue_down_coords,10, white, [x_centre, y_centre]); 
            %flip everything
            Screen('Flip', windowPtr);  
            % Record event (trigger box) cue event = 'S 8' 
            fwrite(SerialPortObj, event_cue(trialArray_rand(i,1)+1),'sync');
            fwrite(SerialPortObj, 0,'sync');
            cue_time(i) = GetSecs;

        end


        %% deliver TAP & ZAP with relative timing based on condition

    %     (1) ZAP is 100 msec BEFORE TAP
        if (trialArray_rand(i,2) == 1)
            preload(da, stimulus)
            waiting=1;
            while waiting 
                if (GetSecs - cue_time(i))*1000 >900-min_tms_delay
                    tms_time(i) = GetSecs;
                    myMS.fire(); %tms
                    waiting=0;
                end
            end

            waiting=1;
            while waiting 
                if (GetSecs - tms_time(i))*1000 >100-min_100_delay
                    if trialArray_rand(i,3)>0
                        start(da) %tap
                        tap_time(i) = GetSecs;
                        write(dd,[1]) %event
                        write(dd, [0])
                    else
                        tap_time(i) = GetSecs;
                    end
                    waiting=0;
                end
            end
% %             stop(da)  


        % (2) ZAP is 25 msec AFTER TAP
        elseif (trialArray_rand(i,2) == 2)
            %send timed output
            preload(da, stimulus)
            waiting=1;
            while waiting  
                if (GetSecs - cue_time(i))*1000 >1000-min_tap_delay
                    if trialArray_rand(i,3)>0
                        start(da) %tap    
                        tap_time(i) = GetSecs;
                        write(dd,1) %event                   
                        write(dd,0)
                    else   
                        tap_time(i) = GetSecs;
                    end
                    waiting=0;
                end
            end

            waiting=1;
            while waiting 
                if (GetSecs -tap_time(i))*1000 >25-min_25_delay
                    tms_time(i) = GetSecs; 
                    myMS.fire(); %tms   
                    waiting=0;
                end
            end
%             stop(da)  
            write(dd, [0])

            % (3) no ZAP; TAP is 1 sec after cue 
        else 
            preload(da, stimulus)
            waiting=1;
            while waiting  
                if (GetSecs - cue_time(i))*1000 >1000-min_tap_delay
                    if trialArray_rand(i,3)>0
                        start(da) %tap
                        tap_time(i) = GetSecs;
                        write(dd,[1]) %event
                        write(dd,[0])
                    end
                    waiting=0;
                end
            end       
%             stop(da)  

        end

        % Cue Response - Draw green crosshair
        Screen('DrawLines', windowPtr, cross_coords,2, green, [x_centre, y_centre]); 
        Screen('DrawLines', windowPtr, cue_up_coords,10, green, [x_centre, y_centre]);
        Screen('DrawLines', windowPtr, cue_down_coords,10, green, [x_centre, y_centre]);  
        %flip everything
        waiting=1;
        while waiting 
            if GetSecs - cue_time(i) > 2
                Screen('Flip', windowPtr);
                response_cue_time(i) = GetSecs - cue_time(i);
                waiting=0;
            end
        end
        stop(da)
        fwrite(SerialPortObj, event_respcue,'sync');
        fwrite(SerialPortObj, 0,'sync');

        % Response
        response_window_onset = GetSecs();
        [s, keyCode, delta] = KbWait(-3, 2, GetSecs()+1);

        % get RT
        if keyCode(yes_button) | keyCode(no_button)| keyCode(operator_button) %if it's a button we specifiec
            RT(i) = s - response_window_onset;
        end
            %define accuracy
        if trialArray_rand(i,1)==0 & trialArray_rand(i,3) > 0 %cue hand - tap not null
            if keyCode(yes_button); accuracy(i) = 1;  end
        elseif trialArray_rand(i,1)==0 & trialArray_rand(i,3) == 0 %cue hand - tap null
            if keyCode(no_button); accuracy(i) = 1;end
        elseif trialArray_rand(i,1)==1 &  trialArray_rand(i,2) > 0  %cue head - zap not null
            if keyCode(yes_button); accuracy(i) = 1; end
        elseif trialArray_rand(i,1)==1 & trialArray_rand(i,2) == 0  %cue head - zap null
            if keyCode(no_button); accuracy(i) = 1;end 
        end
        %unscheduled break
        if (keyCode(operator_button) == 1)
             break_start = GetSecs();
             pause(1);
             text = sprintf('Break\n(Press any key to continue)');
             DrawFormattedText(windowPtr,text,'center','center',white);
             Screen('Flip',windowPtr)
             breakkeycode(operator_button)=0;
             while breakkeycode(operator_button)==0
                [s, breakkeycode, delta] = KbWait();
             end
             fprintf(task_times, 'unscheduled break: %is \n',round(GetSecs-break_start));      
        end

        pause(response_interval - RT(i));

        %edit time for output
        rt = RT(i)*1000;
        tms_time_rel =0;
        if tms_time(i)>0
            tms_time_rel = (tms_time(i)-tap_time(i))*1000;
        end
        if trialArray_rand(i,3)==0 %delete fake tap times
            tap_time(i)=0;
            tap_time_rel = 0;
        else
            tap_time_rel = tap_time(i)-cue_time(i);
        end


        %output (before updating for next trial)
        fprintf(task_results,'%i\t%i\t%i\t%i\t%i\t%i\t%i\t%2.4f\t%2.2f\t%2.2f\t%2.3f \n',...
                i,trialArray_rand(i,1),trialArray_rand(i,2),trialArray_rand(i,3),...
                accuracy(i), keyCode(yes_button), keyCode(no_button), ...
                tap_time_rel,tms_time_rel,rt, threshold);

        fprintf(task_times,'%i\t %f\t %f\t %f\t %f\t \n',...
            i,cue_time(i),tap_time(i),tms_time(i), response_cue_time(i));

        %% Dynamic Thresholding
        if trialArray_rand(i,1) == 0 & trialArray_rand(i,3) == 1 % if hand cue and threshold tap
            threshold_memory = [threshold_memory, accuracy(i)];
            if length(threshold_memory)>1
                if all(threshold_memory(end-1:end)==1)
                    threshold = threshold - change;
                    threshold_memory = [];
                end
            end
            if length(threshold_memory)>2
                if all(threshold_memory(end-2:end)==0)
                    threshold = threshold + change;
                    threshold_memory =[];
                end
            end
        end
        if threshold > threshold_max
            threshold = threshold_max;
        elseif threshold <threshold_min
            threshold = threshold_min;
        end

        %scheduled break
        if round(i/break_trials) == i/break_trials & i<total_num_trials & round(i/big_breaks) ~= i/big_breaks
             break_start = GetSecs();
             waiting = 1;
             countsecs = 0;
             while waiting
                 if GetSecs()-break_start > 1+countsecs                             
                     text = sprintf('Short Break\n %i s until task\n(Press any key to continue earlier)',break_max_time - countsecs); %cheats by one second
                     countsecs = countsecs +1;
                     DrawFormattedText(windowPtr,text,'center','center',white);
                     Screen('Flip',windowPtr)
                 end
                 if countsecs > break_max_time | KbCheck()
                     waiting = 0;
                 end
             end
             fprintf(task_times, 'scheduled break: %is \n',round(GetSecs-break_start));   
        end
        %big break
        if round(i/big_breaks) == i/big_breaks & i<total_num_trials
            break_start = GetSecs();
            disarmtracker = break_start;
            text = sprintf('Break\n%i/%i trials completed\n', i,total_num_trials);
            DrawFormattedText(windowPtr,text,'center','center',white);
            Screen('Flip',windowPtr)
            breakkeycode(operator_button)=0;
            while breakkeycode(operator_button)==0
                [s, breakkeycode, delta] = KbWait(-3, 2, GetSecs()+1);
                if GetSecs-disarmtracker > 5*60 %fire every 5mins to avoid disarm (10min)
                    myMS.setAmplitudeA(0)
                    myMS.fire()
                    myMS.setAmplitudeA(subj_intensity)
                    disarmtracker = GetSecs;
                end
            end
            fprintf(task_times, 'scheduled break: %is \n',round(GetSecs-break_start));
            Screen('DrawLines', windowPtr, cross_coords,2, [255 255 255], [x_centre, y_centre]); 
            Screen('DrawLines', windowPtr, cue_up_coords,10, [255 255 255], [x_centre, y_centre]);
            Screen('DrawLines', windowPtr, cue_down_coords,10, [255 255 255], [x_centre, y_centre]);
            Screen('Flip', windowPtr);
            pause(1);
        end
    end
    % fclose(SerialPortObj);
    % delete(SerialPortObj);
    % fclose('all');
    myMS.disarm()
    myMS.disconnect()
    
    text = sprintf('End of Task');
    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Flip',windowPtr)
    KbWait();

end