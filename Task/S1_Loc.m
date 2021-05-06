function S1_Loc(SIloc_trials, SerialPortObj,windowPtr,black, white, red, x_centre, y_centre, da, dd, sinewave,supra)

    %% define events
    event_cue = 4;
    supra_time = zeros(SIloc_trials,1);
    stimulus = supra*sinewave;

    % draw visual stimuli %%% rename cross_coords and draw only once
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

    % Cue
    Screen('DrawLines', windowPtr, cross_coords,2, white, [x_centre, y_centre]); 
    Screen('DrawLines', windowPtr, cue_up_coords,10, white, [x_centre, y_centre]);
    Screen('DrawLines', windowPtr, cue_down_coords,10, red, [x_centre, y_centre]); 
    Screen('Flip', windowPtr);
    fwrite(SerialPortObj, event_cue,'sync');
    fwrite(SerialPortObj, 0,'sync');
    pause(1)

    %% 2) Actual presentation of stimuli   
    for trial = 1:SIloc_trials
        % Deliver Tap
        preload(da, stimulus)
        start(da) %tap
        write(dd,[1]) %event
        write(dd,[0]) 
        pause(2)  
        stop(da)
   
    end
end


