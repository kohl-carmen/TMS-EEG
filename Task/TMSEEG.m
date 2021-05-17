function TMSEEG(subj_str,active, subj_intensity)
    %inputs:
%         subj_str: subject number as string ('BETAXX')
%         active: 1 for SI, 0 for control
%         subj_intensity: TMS intensity (80% MT)

    cd('C:\Users\Jones Lab\Documents\Task_Code\New_Task_Code_Attention\Carmen');

    SIloc_trials = 150; %150
    training_trials1 = 5;%5
    eeg_rest = 60; %60
    max_pest_trials = 33;%33;
    training_trials2 = [5,10,20];%[5,10,20];
    trialmultiplier = 6;%6
    %% TMS EEG Experiment
    % 1) S1 Localization 
    % 2) Training I
    % 3) Resting EEG Sound ON
    % 4) Resting EEG Sound OFF
    % 5) PEST 
    % 6) Training II
    % 7) Task
    % 8) S1 Localization 
    % 9) Resting EEG Sound ON
    % 10) Resting EEG Sound OFF
    
    %% Initializing Psychtoolbox & Serialport
    % we have to redo this once we want to use TMS
    Screen('Preference', 'SkipSyncTests', 1);
    PsychDefaultSetup(2); %default PTB setup
    screens = Screen('Screens'); %get screen numbers
    screenNumber = max(screens); %get max screen
    black = [0 0 0];
    white = [255 255 255];
    red = [255,0,0];
    green = [0,255,0];    
    SerialPortObj=serial('COM3', 'TimeOut', 1); % in this example x=3 SerialPortObj.BytesAvailableFcnMode='byte';
    SerialPortObj.BytesAvailableFcnCount=1; 
    SerialPortObj.BytesAvailableFcn=@ReadCallback;
    %%Psychtoolbox
    Screen('Preference','VisualDebugLevel',0);
    [windowPtr,rect]=Screen('OpenWindow', screenNumber, black);
    [x_centre, y_centre]=RectCenter(rect);
    %%Serialport
    fopen(SerialPortObj);
    fwrite(SerialPortObj, 0,'sync');  
     %%Nidaq
    da = daq('ni'); %analog - tap
    dd = daq('ni'); % digital - event
    addoutput(da, 'Dev1', 'ao0', 'Voltage'); %deliver tap
    addoutput(dd,'Dev1','port0/line0', 'Digital'); %tap event
    %Tap
    dq_dt = 1/da.Rate;
    freq = 100; phase = 3*pi/2; 
    time = 0:dq_dt:0.01; %0:0.01 sec in 0.1 msec steps
    sinewave = sin(2*pi*freq*time + phase)'; 
    sinewave = sinewave +1; 
    sinewave(end+1)=0;
    
    %% output
    output_directory =  strcat('C:\Users\Jones Lab\Documents\TMSEEG\',subj_str,'\Session',num2str(active),'\');
    mkdir(output_directory);
    experiment_notes = fopen(strcat(output_directory,subj_str,'_notes'), 'a');
    fprintf(experiment_notes, '\r\n \r\n %s ', datestr(now)); 
    fprintf(experiment_notes, '\n Session: %i ', active); 
    
    %load motor threshold intensities and save in notes
    %(this can fail if MotorThreshold.m was shut down abruptly)
    try
        intensities = load('C:\Users\Jones Lab\Documents\TMSEEG\temp');
        fprintf(experiment_notes,'\nMotor Thresholding: %s',num2str(intensities.keep_intensities));
    catch
        fprintf('intensities not found')
    end

    %%% define response buttons
    yes_button = 34;
    no_button = 40; 
    operator_button = 187; %=
    repeat_button = 189;%-
    % tap intensity
    supra = 1;
    
    repeat=0;
    %% 1) S1 Localization 
    % instructions
    Screen('TextSize',windowPtr, 50);
    Screen('TextFont',windowPtr,'Arial');
    text = sprintf('Finger Taps Only #1 \n\nThank you for participating in this study! \n\nLet the researchers know if you have any questions \nor if you experience discomfort at any point during the experiment. \n\nFirst, we will conduct a short trial session to help \nfamiliarize you with the sensation of the finger taps. \n\nRest your hand gently on the tap device \nand keep your eyes on the cross on the screen in front of you. \n\nThis part will take ~5 mins. \nPress any key to begin the trial session.');
    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Preference','VisualDebugLevel',0);
    Screen('Flip',windowPtr);
    contkeycode(operator_button)=0;
    while contkeycode(operator_button)==0
        [s, contkeycode, delta] = KbWait();
    end
    
    S1_Loc(SIloc_trials, SerialPortObj,windowPtr,black, white, red, x_centre, y_centre, da, dd, sinewave,supra)
    pause(1)
    
    
    %% 2) Training Block 1
    % instructions
    Screen('TextSize',windowPtr, 50);
    Screen('TextFont',windowPtr,'Arial');
    text = sprintf('Training #1 \n\nPlease keep your eyes on the cross on the screen, rest your hand on the tap device \nand pay attention to the tapping sensation on your hand. \n\nWhile the ARROW below the cross is RED, you might feel a tap or you might not. \nOnce the cross turns GREEN, report whether you felt a tap or not using the response buttons. \n\nPress ''Y'' with your left index finger if you DID feel a tap (Yes), \nor ''N'' with your left middle finger if you did NOT feel a tap (No). \n\nYour response will only count when the cross is GREEN. \n\nThis part will take ~1 min.');
    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Flip',windowPtr);
    contkeycode(operator_button)=0;
    while contkeycode(operator_button)==0
        [s, contkeycode, delta] = KbWait();
    end
    trainIacc=0;
    [trainIacc,repeat] = Training_I(training_trials1,subj_str,output_directory, SerialPortObj,windowPtr,black, white, red, green,x_centre, y_centre, da, dd, sinewave,yes_button,no_button,operator_button,active,repeat_button,supra);
    fprintf(experiment_notes, '\n TrainingI: %i%% ', trainIacc); 
    if repeat
        fprintf(experiment_notes, '\n Training I repeated'); 
        DrawFormattedText(windowPtr,text,'center','center',white);
        Screen('Flip',windowPtr);
        contkeycode(operator_button)=0;
        while contkeycode(operator_button)==0
            [s, contkeycode, delta] = KbWait();
        end
        trainIacc=0;
        [trainIacc,repeat] = Training_I(training_trials1,subj_str,output_directory, SerialPortObj,windowPtr,black, white, red, green,x_centre, y_centre, da, dd, sinewave,yes_button,no_button,operator_button,active,repeat_button,supra);
        fprintf(experiment_notes, '\n TrainingI: %i%% ', trainIacc);      
    end
    pause(1)
    
    
    
    %% 3) Resting EEG Sound ON
    %instructions
    text = sprintf('Resting EEG - Sound ON \n\n Look at the Cross #1 \n\nRelax while looking at the cross on the screen. \nYou don''t need to make any responses. \n\nThis part will take ~1 min.');
    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Flip',windowPtr);
    contkeycode(operator_button)=0;
    while contkeycode(operator_button)==0
        [s, contkeycode, delta] = KbWait();
    end
    Resting(eeg_rest, windowPtr, black,white,red,x_centre,y_centre,SerialPortObj)
    pause(1)
    
    %% 4) Resting EEG Sound OFF
    %instructions
    text = sprintf('Resting EEG - Sound OFF \n\n Look at the Cross #1 \n\nRelax while looking at the cross on the screen. \nYou don''t need to make any responses. \n\nThis part will take ~1 min.');
    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Flip',windowPtr);
    contkeycode(operator_button)=0;
    while contkeycode(operator_button)==0
        [s, contkeycode, delta] = KbWait();
    end
    Resting(eeg_rest, windowPtr, black,white,red,x_centre,y_centre,SerialPortObj)
    pause(1)
        
    
    %% 5) PEST
    %instructions
    text = sprintf('Pre-Task Procedure (PEST) \n\nKeep your eyes on the cross, and while the ARROW is RED \npay attention to the tapping sensation on your hand. \nOnce the cross turns GREEN, report whether you felt a tap or not. \n\nPress ''Y'' with your left index finger for ''Yes'' \nor ''N'' with your left middle finger for ''No''. \n\nYour response will only count when the cross is GREEN. \n\nThis part will take a few mins.');

    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Flip',windowPtr);
    contkeycode(operator_button)=0;
    while contkeycode(operator_button)==0
        [s, contkeycode, delta] = KbWait();
    end
    detection_threshold = 0;
    [detection_threshold,repeat] =  PEST(max_pest_trials,subj_str,output_directory, SerialPortObj,windowPtr,black, white, red, green,x_centre, y_centre, da, dd, sinewave,yes_button,no_button,operator_button,active,repeat_button);
    fprintf(experiment_notes, '\n Threshold: %2.2f ', detection_threshold); 
    if repeat
        fprintf(experiment_notes, '\n PEST repeated'); 
        DrawFormattedText(windowPtr,text,'center','center',white);
        Screen('Flip',windowPtr);
        contkeycode(operator_button)=0;
        while contkeycode(operator_button)==0
            [s, contkeycode, delta] = KbWait();
        end
        [detection_threshold,repeat] =  PEST(max_pest_trials,subj_str,output_directory, SerialPortObj,windowPtr,black, white, red, green,x_centre, y_centre, da, dd, sinewave,yes_button,no_button,operator_button,active,repeat_button);
        fprintf(experiment_notes, '\n Threshold: %2.2f ', detection_threshold); 
    end
    pause(1)

    %% 6) Training II
     % get ready to restart everything:
    fclose(SerialPortObj);
    delete(SerialPortObj);
    sca;
    %restart
    Screen('Preference','VisualDebugLevel',0);
    Screen('Preference', 'SkipSyncTests', 1);
    PsychDefaultSetup(2); %default PTB setup
    screens = Screen('Screens'); %get screen numbers
    screenNumber = max(screens); %get max screen
    black = [0 0 0];
    white = [255 255 255];
    red = [255,0,0];
    green = [0,255,0];    
    %%Magic
    myMS = rapid('COM6','SuperPlus','8ec8-d16b8f45-39');
    %%Serialport
    SerialPortObj=serial('COM3', 'TimeOut', 1); % in this example x=3 SerialPortObj.BytesAvailableFcnMode='byte';
    SerialPortObj.BytesAvailableFcnCount=1; 
    SerialPortObj.BytesAvailableFcn=@ReadCallback;
    %% Start (this order matters!)
    %%Psychtoolbox
    Screen('Preference','VisualDebugLevel',0);
    [windowPtr,rect]=Screen('OpenWindow', screenNumber, black);
    [x_centre, y_centre]=RectCenter(rect); 
    %%Magic
    myMS.connect();
    %%Serialport
    fopen(SerialPortObj);
    %% Other Prep
    %%Serialport
    fwrite(SerialPortObj, 0,'sync');
    %%Magic
    myMS.setAmplitudeA(0) ;
    myMS.setChargeDelay(500);
    myMS.arm();
    myMS.ignoreCoilSafetyInterlock();
    myMS.setAmplitudeA(subj_intensity); 
    %%Nidaq
    da = daq('ni'); %analog - tap
    dd = daq('ni'); % digital - event
    addoutput(da, 'Dev1', 'ao0', 'Voltage'); %deliver tap
    addoutput(dd,'Dev1','port0/line0', 'Digital'); %tap event

    %instructions
    Screen('TextSize',windowPtr, 50);
    Screen('TextFont',windowPtr,'Arial');
    text = sprintf('Training #2 \n \nWe''re going to change your task a little bit.\n Now you''ll see a RED ARROW either above or below the cross.\n\n When the RED arrow is ABOVE the cross pointing UP,\n pay attention to sensations on your HEAD from the TMS,\n and report whether or not you felt a sensation on your HEAD when the cross turns GREEN.\n\n When the RED arrow is BELOW the cross pointing DOWN,\n pay attention to sensations on your HAND from the tap device,\n and report whether or not you felt a sensation on your HAND when the cross turns GREEN.\n\n You might feel taps on your head and hand at the same time or close together in time.\n Just pay attention to and report taps at the body location indicated by the red arrow.');

    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Flip',windowPtr)
    contkeycode(operator_button)=0;
    while contkeycode(operator_button)==0
        [s, contkeycode, delta] = KbWait();
    end
    trainaccII1=0; trainaccII2=0; trainaccII3=0;
    [trainaccII1,trainaccII2,trainaccII3,repeat] = Training_II(training_trials2,subj_str,output_directory, SerialPortObj,windowPtr,black, white, red, green,x_centre, y_centre, da, dd, sinewave,detection_threshold,myMS,yes_button,no_button,operator_button,active,repeat_button,supra);
    fprintf(experiment_notes, '\n Training II: %i%%\t%i%%\t%i%% ', [trainaccII1,trainaccII2,trainaccII3]); 
    if repeat
        fprintf(experiment_notes,'\n Training II repeated');
        DrawFormattedText(windowPtr,text,'center','center',white);
        Screen('Flip',windowPtr)
        contkeycode(operator_button)=0;
        while contkeycode(operator_button)==0
            [s, contkeycode, delta] = KbWait();
        end
        trainaccII1=0;trainaccII2=0;trainaccII3=0;
        [trainaccII1,trainaccII2,trainaccII3,repeat] = Training_II(training_trials2,subj_str,output_directory, SerialPortObj,windowPtr,black, white, red, green,x_centre, y_centre, da, dd, sinewave,detection_threshold,myMS,yes_button,no_button,operator_button,active,repeat_button,supra);
        fprintf(experiment_notes, '\n Training II: %i%%\t%i%%\t%i%% ', [trainaccII1,trainaccII2,trainaccII3]); 
    end
        
        
    pause(1)
    
    
    %% 7) TMS-EEG Task 
    %instructions
    text = sprintf('Main Task \n\nNow we''re going to begin the full task, as we just practiced. \n\nAs a reminder: \nPay attention to your HEAD when the RED ARROW points UP, \nand then report whether or not you felt a sensation on your HEAD when the cross turns GREEN. \n\nPay attention to your HAND when the RED ARROW points DOWN, \nand then report whether or not you felt a sensation on your HAND once the cross turns GREEN. \n\nReport ''YES'' with your LEFT INDEX finger, and ''NO'' with your LEFT MIDDLE finger. \n\nThis part will take about 1 hour, and there will be several breaks during that time.\n We will stop to check in with you twice - 1/3 and 2/3 of the way through the task,\n and there will also be shorter (30 sec.) breaks in between check-ins. \n\nLet the experimenters know if anything is wrong or if you experience any discomfort.');
    
    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Flip',windowPtr);
    contkeycode(operator_button)=0;
    while contkeycode(operator_button)==0
        [s, contkeycode, delta] = KbWait();
    end
    
    Task(trialmultiplier,subj_str,output_directory, SerialPortObj,windowPtr,black, white, red, green,x_centre, y_centre, da, dd, sinewave,detection_threshold,myMS,yes_button,no_button,operator_button,active,subj_intensity, supra);
    pause(1)
    
    
    %% 8) S1 Localization 2
    % instructions
    text = sprintf('Finger Taps Only #2 \n \nYou''re almost done! \n\nRest your hand gently on the tap device \nand keep your eyes on the cross.\n You don''t need to make any responses.\n\n This part will take ~5 mins.');
    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Flip',windowPtr);
    contkeycode(operator_button)=0;
    while contkeycode(operator_button)==0
        [s, contkeycode, delta] = KbWait();
    end
    S1_Loc(SIloc_trials, SerialPortObj,windowPtr,black, white, red, x_centre, y_centre, da, dd, sinewave,supra)
    pause(1)
    
    
    %% 9) Resting EEG Sound ON
    %instructions
    text = sprintf('Resting EEG - Sound ON \n\n Look at the Cross #2 \n \n Just relax and look at the cross.\n You don''t need to make any responses.\n\n This part will take ~1 min.');
    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Flip',windowPtr)
    contkeycode(operator_button)=0;
    while contkeycode(operator_button)==0
        [s, contkeycode, delta] = KbWait();
    end
    Resting(eeg_rest, windowPtr, black,white,red,x_centre,y_centre,SerialPortObj)   
    
    %% 10) Resting EEG Sound OFF
    %instructions
    text = sprintf('Resting EEG - Sound OFF \n\n Look at the Cross #2 \n \nThis is the last part!\n\n Just relax and look at the cross.\n You don''t need to make any responses.\n\n This part will take ~1 min.');
    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Flip',windowPtr)
    contkeycode(operator_button)=0;
    while contkeycode(operator_button)==0
        [s, contkeycode, delta] = KbWait();
    end
    Resting(eeg_rest, windowPtr, black,white,red,x_centre,y_centre,SerialPortObj)  
    
    
    %All done
    text = sprintf('You''ve completed today''s session - thank you!!');
    DrawFormattedText(windowPtr,text,'center','center',white);
    Screen('Flip',windowPtr);
    KbStrokeWait
    fclose(SerialPortObj);
    delete(SerialPortObj);
    fclose('all');
    sca;
end