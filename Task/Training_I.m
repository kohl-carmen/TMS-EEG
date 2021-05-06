function [trainIaccuracy,repeat] = Training_I(training_trials,subj_str,output_directory, SerialPortObj,windowPtr,black, white, red, green,x_centre, y_centre, da, dd, sinewave,yes_button,no_button,operator_button,active,repeat_button,supra)

    % define events
    event_cue = 4;
    event_respcue = 16;


    %Initialize variables to store stimulus values
    max_stim = supra; % (the equivalent of 350 um ? CHECK THIS)
    mid_stim = max_stim/2;
    min_stim = 0;

    %Delay times
    delay_times = [.5 .6 .7 .8 .9 1 1.1 1.2 1.3 1.4 1.5];

    %Index to keep track of loop
    count = 0;

    %init output
    trainingI_results = fopen(strcat(output_directory,subj_str,'_train_I'), 'a');
    fprintf(trainingI_results, '\r\n \r\n %s ', datestr(now));  
    fprintf(trainingI_results, '\n Session: %i ', active); 
    fprintf(trainingI_results,'\nTrial\tType\tStim\tDetect\tRT\tTapTime\tRespTime\tCueTime\tUpdate');

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

    % Wait for any key press to start 
    KbStrokeWait()


    %% 5) For loop of actual task
    accuracy =[];
    for trial = 1:training_trials
        RT_max = 0;
        RT_mid = 0;
        RT_min = 0;

        % 1) Present cue
        % 2) Deliver stimulus 
        % 3) Present response cue
        % 4) Record response
        % 5) Repeat for other two intensities
        % 6) Update stimulation intensities

        %-----------------------------------------------------------------
        %% Delivery of Max stimulus
        delay_time_max = delay_times(randi([1 size(delay_times,2)]));
        %Draw cue
        Screen('DrawLines', windowPtr, cross_coords,2, white, [x_centre, y_centre]); 
        Screen('DrawLines', windowPtr, cue_up_coords,10, white, [x_centre, y_centre]);
        Screen('DrawLines', windowPtr, cue_down_coords,10, red, [x_centre, y_centre]); 
        Screen('Flip', windowPtr);
        % event
        fwrite(SerialPortObj, event_cue,'sync');
        fwrite(SerialPortObj, 0,'sync');
        cue_time_max = GetSecs;

        %Deliver Max stimulus
        stimulus = max_stim*sinewave;
        preload(da, stimulus)
            waiting=1;
            while waiting  
                if (GetSecs - cue_time_max) > delay_time_max
                        start(da) %tap
                        tap_time_max = GetSecs;
                        write(dd,[1]) %event
                        write(dd,[0])
                    waiting=0;
                end
            end       

        pause(2 - delay_time_max - .01)%%%
        stop(da)  

        %Draw green crosshair   
        Screen('DrawLines', windowPtr, cross_coords,2, green, [x_centre, y_centre]); 
        Screen('DrawLines', windowPtr, cue_up_coords,10, green, [x_centre, y_centre]);
        Screen('DrawLines', windowPtr, cue_down_coords,10, green, [x_centre, y_centre]);  
        %flip everything
        waiting=1;
        while waiting 
            if (GetSecs - cue_time_max) > 2
                Screen('Flip', windowPtr);
                waiting=0;
            end
        end

        %event
        fwrite(SerialPortObj, event_respcue,'sync');
        fwrite(SerialPortObj, 0,'sync');

        % Response
        respcue_time_max = GetSecs();
        [s, keyCode_max, delta_max] = KbWait(-3, 2, GetSecs()+1);

        %get RT
        if keyCode_max(yes_button) | keyCode_max(no_button)
             RT_max = s - respcue_time_max;
        end

        pause(1 - RT_max);

        % ------------------------------------------
        %% Delivery of Mid stimulus
        delay_time_mid = delay_times(randi([1 size(delay_times,2)]));
        %Draw cue
        Screen('DrawLines', windowPtr, cross_coords,2, white, [x_centre, y_centre]); 
        Screen('DrawLines', windowPtr, cue_up_coords,10, white, [x_centre, y_centre]);
        Screen('DrawLines', windowPtr, cue_down_coords,10, red, [x_centre, y_centre]); 
        Screen('Flip', windowPtr);
        % event
        fwrite(SerialPortObj, event_cue,'sync');
        fwrite(SerialPortObj, 0,'sync');
        cue_time_mid = GetSecs;

        %Deliver Mid stimulus
        stimulus = mid_stim*sinewave;
        preload(da, stimulus)
            waiting=1;
            while waiting  
                if (GetSecs - cue_time_mid) >delay_time_mid
                        start(da) %tap
                        tap_time_mid = GetSecs;
                        write(dd,[1]) %event
                        write(dd,[0])
                    waiting=0;
                end
            end       
            

         pause(2 - delay_time_max - .01)
         stop(da)  

        %Draw green crosshair   
        Screen('DrawLines', windowPtr, cross_coords,2, green, [x_centre, y_centre]); 
        Screen('DrawLines', windowPtr, cue_up_coords,10, green, [x_centre, y_centre]);
        Screen('DrawLines', windowPtr, cue_down_coords,10, green, [x_centre, y_centre]);  
        waiting=1;
        while waiting 
            if (GetSecs - cue_time_mid > 2)
                Screen('Flip', windowPtr);
                waiting=0;
            end
        end

        %event
        fwrite(SerialPortObj, event_respcue,'sync');
        fwrite(SerialPortObj, 0,'sync');

        % Response
        respcue_time_mid = GetSecs();
        [s, keyCode_mid, delta_mid] = KbWait(-3, 2, GetSecs()+1);

        %get RT
        if keyCode_mid(yes_button) | keyCode_max(no_button)
             RT_mid = s - respcue_time_mid;
        end
        pause(1 - RT_mid);

        % -----------------------------------------
        %% Delivery of Min stimulus
        delay_time_min = delay_times(randi([1 size(delay_times,2)]));
        %Draw cue
        Screen('DrawLines', windowPtr, cross_coords,2, white, [x_centre, y_centre]); 
        Screen('DrawLines', windowPtr, cue_up_coords,10, white, [x_centre, y_centre]);
        Screen('DrawLines', windowPtr, cue_down_coords,10, red, [x_centre, y_centre]); 
        Screen('Flip', windowPtr);
        % event
        fwrite(SerialPortObj, event_cue,'sync');
        fwrite(SerialPortObj, 0,'sync');
        cue_time_min = GetSecs;

        %Deliver Min stimulus
        stimulus=min_stim*sinewave;
        preload(da, stimulus)
            waiting=1;
            while waiting  
                if (GetSecs - cue_time_min) >delay_time_min
                        start(da) %tap
                        tap_time_min = GetSecs;
                        write(dd,[1]) %event
                        write(dd,[0])
                    waiting=0;
                end
            end       
             

        pause(2 - delay_time_max - .01)
        stop(da) 

        %Draw green crosshair   
        Screen('DrawLines', windowPtr, cross_coords,2, green, [x_centre, y_centre]); 
        Screen('DrawLines', windowPtr, cue_up_coords,10, green, [x_centre, y_centre]);
        Screen('DrawLines', windowPtr, cue_down_coords,10, green, [x_centre, y_centre]);  
        waiting=1;
        while waiting 
            if (GetSecs - cue_time_max) > 2
                Screen('Flip', windowPtr);
                waiting=0;
            end
        end

        %event
        fwrite(SerialPortObj, event_respcue,'sync');
        fwrite(SerialPortObj, 0,'sync');

        % Response
        respcue_time_min = GetSecs();
        [s, keyCode_min, delta_min] = KbWait(-3, 2, GetSecs()+1);
        RT_min = s - respcue_time_min;
        %get RT
        if keyCode_max(yes_button) | keyCode_max(no_button)
             RT_min = s - respcue_time_min;
        end

        pause(1 - RT_min);


        %% Adjustment of weights
        % Keeps track of participant's response (yes=1 is 49, no=2 is 50)
        max_detected = keyCode_max(yes_button);
        mid_detected = keyCode_mid(yes_button);
        min_detected = keyCode_min(yes_button);

        accuracy = [accuracy;max_detected; mid_detected; keyCode_min(no_button)];
        %save
        count = count + 3;    
        fprintf(trainingI_results,'\n%i\t%i\t%2.2f\t%i\t%i\t%2.2f\t%2.2f\t%2.2f\t',...
                count-2,2,max_stim, max_detected,round(RT_max*1000),tap_time_max-cue_time_max,respcue_time_max-cue_time_max,cue_time_max);
        fprintf(trainingI_results,'\n%i\t%i\t%2.2f\t%i\t%i\t%2.2f\t%2.2f\t%2.2f\t',...
            count-1,1,mid_stim, mid_detected,round(RT_mid*1000),tap_time_mid-cue_time_mid,respcue_time_mid-cue_time_mid,cue_time_mid);
        fprintf(trainingI_results,'\n%i\t%i\t%2.2f\t%i\t%i\t%2.2f\t%2.2f\t%2.2f\t',...
            count,0,min_stim, min_detected,round(RT_min*1000),tap_time_min-cue_time_min,respcue_time_min-cue_time_min,cue_time_min);

    end

    text = sprintf('End of Training\n Accuracy: %i%%',round(mean(accuracy)*100));
    trainIaccuracy= round(mean(accuracy)*100);
    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Flip',windowPtr)
    [s, keyCode_repeat, delta_min] = KbWait(-3, 2);
    repeat = 0;
    if keyCode_repeat(repeat_button)
        repeat = 1;
    end

end

    
