function Resting(eeg_rest, windowPtr, black,white,red,x_centre,y_centre,SerialPortObj)

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
% % % % fwrite(SerialPortObj, 4,'sync%%%
% fwrite(SerialPortObj, 0,'sync');
event_cue = 4;
fwrite(SerialPortObj, event_cue,'sync');
fwrite(SerialPortObj, 0,'sync');
pause(eeg_rest)


text = sprintf('End of Rest');
DrawFormattedText(windowPtr,text,'center','center',white);
Screen('Flip',windowPtr)
KbStrokeWait()



