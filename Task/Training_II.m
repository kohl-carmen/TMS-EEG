function [trainaccII1,trainaccII2,trainaccII3,repeat] = Training_II(training_trials,subj_str,output_directory, SerialPortObj,windowPtr,black, white, red, green,x_centre, y_centre, da, dd, sinewave,detection_threshold, myMS, yes_button,no_button,operator_button,active,repeat_button,supra)

    %trials
    min_thresh_per_cond = 84;
    total_per_cond = round(min_thresh_per_cond/0.7);
    total_num_trials = total_per_cond*6;    
    

%  function [output_array,threshold] = Dynamic_Thresholding(windowPtr,screens, screenNumber, black, white, red, green, x_centre, y_centre, detection_threshold, SerialPortObj, myMS, total_num_trials, da, dd, dd2, sinewave)

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
    train_results = fopen(strcat(output_directory,subj_str,'_trainII'), 'a');
    fprintf(train_results, '\r\n \r\n %s ', datestr(now)); 
    fprintf(train_results, '\n Session: %i ', active);
    fprintf(train_results, strcat('\n Trial\tCueCond\tTMSCond\tTapCond\t',...
            'Accuracy\tYesResponse\tNoResponse\tTapTime\tTMSTime\t',...
            'RT\tThreshold\n'));
     

    %define starting tap intensities 
    null = 0.0;
    threshold = detection_threshold;
    supra = supra;

    response_interval = 1;

    %define tap maxmin %%% 
    threshold_max = 8;
    threshold_min = 0; 
    change = .005;

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
    for training_blocks = [1:3]
        %     1: taps (strong) only
        %     2: taps (strong) and tms
        %     3: taps(normal) and tms
        trialArray = zeros(total_num_trials,3);
        halfway_pt = total_num_trials/2; 
        total_per_cond = total_num_trials/6;
        initial_cueType = [repmat(0,1,round(total_num_trials/2)),repmat(1,1,round(total_num_trials/2))];
        initial_zapTime = [repmat(0,1,round(halfway_pt/3)),repmat(1,1,round(halfway_pt/3)),repmat(2,1,round(halfway_pt/3))];
        initial_tapInt = [repmat(0,1,round(total_per_cond*.2)),repmat(1,1,round(total_per_cond*.7)),repmat(2,1,round(total_per_cond*.1))];
         trialArray(:,1) = initial_cueType;
        trialArray(:,2) = repmat(initial_zapTime,1,2);
        trialArray(:,3) = repmat(initial_tapInt,1,6);
        % Shuffle trial structure array
        trialArray_rand = trialArray(randperm(size(trialArray,1)),:);

        accuracy_memory = [];
        for i = 1:training_trials(training_blocks)

            if training_blocks==1
                trialArray_rand(i,3) = 2; %supra
                trialArray_rand(i,2) = 0; %nontms
                trialArray_rand(i,1) = 0; %hand cue         
            elseif training_blocks==2
                trialArray_rand(i,3) = 2; %supra
            end       

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
%                 stop(da)  


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
%                 stop(da)  
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
%                 stop(da)  

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
            if keyCode(yes_button) | keyCode(no_button) %if it's a button we specifiec
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
            accuracy_memory = [accuracy_memory, accuracy(i)];

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
            fprintf(train_results,'%i\t%i\t%i\t%i\t%i\t%i\t%i\t%2.4f\t%2.2f\t%2.2f\t%2.3f \n',...
                    i,trialArray_rand(i,1),trialArray_rand(i,2),trialArray_rand(i,3),...
                    accuracy(i), keyCode(yes_button), keyCode(no_button), ...
                    tap_time_rel,tms_time_rel,rt, threshold);
        end
        if training_blocks==1
            text = sprintf('Training Block 1 Done - Accuracy: %i%%\n Next, the cue will change from trial to trial, \ncueing you to attend to either your hand (down) or your head (up).', round(mean(accuracy_memory)*100));
            trainaccII1 = round(mean(accuracy_memory)*100);
        elseif training_blocks==2
            text = sprintf('Training Block 2  Done - Accuracy: %i%%\n We will repeat the same task, but increase the difficulty.', round(mean(accuracy_memory)*100));
            trainaccII2 = round(mean(accuracy_memory)*100);
        else
            text = sprintf('Training Complete - Accuracy: %i%%',round(mean(accuracy_memory*100)));
            trainaccII3 = round(mean(accuracy_memory)*100);
        end
        DrawFormattedText(windowPtr,text,'center','center',white);
        Screen('Flip',windowPtr)
        [s, keyCode_repeat, delta_min] = KbWait(-3, 2);
        repeat = 0;
        if keyCode_repeat(repeat_button)
            repeat = 1;
        end
    end
end