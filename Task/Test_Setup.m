%% Run tests before experiment

%% Tap --------------------------
fprintf('-- Sending Taps --\n')
da = daq('ni'); %analog - tap
dd = daq('ni'); % digital - event
addoutput(da, 'Dev1', 'ao0', 'Voltage'); %deliver tap
addoutput(dd,'Dev1','port0/line0', 'Digital'); %tap event

da.Rate = 5000; 
dq_dt = 1/da.Rate;
freq = 100; phase = 3*pi/2; 
time = 0:dq_dt:0.01; %0:0.01 sec in 0.1 msec steps
sinewave = sin(2*pi*freq*time + phase)'; 
sinewave = sinewave +1;     
sinewave(end+1)=0;

threshold = 1;
stimulus = threshold*sinewave;
pause(1);
for i = 1:3
    preload(da, stimulus);
    start(da);
    stop(da);
    fprintf('Tap%i\n',i);
    write(dd,[1]);
    write(dd, [0]);
    pause(1);
end
    
%% TMS --------------------------
fprintf('-- Sending Pulse --\n')

myMS = rapid('COM6','SuperPlus','8ec8-d16b8f45-39');
myMS.connect();
myMS.setAmplitudeA(0) ;
myMS.setChargeDelay(500);
myMS.arm();
myMS.ignoreCoilSafetyInterlock();

myMS.setAmplitudeA(10) ;
pause(1);
for i = 1:3
    myMS.fire();
    fprintf('Pulse%i\n',i);
    pause(1);
end
myMS.disconnect();


%% Events --------------------------
fprintf('-- Sending Events --\n')
SerialPortObj=serial('COM3', 'TimeOut', 1); 
SerialPortObj.BytesAvailableFcnCount=1; 
SerialPortObj.BytesAvailableFcn=@ReadCallback;
fopen(SerialPortObj);
fwrite(SerialPortObj, 0,'sync');  

event_respcue = 16;
pause(1);
for i = 1:3
    fwrite(SerialPortObj, event_respcue,'sync');
    fwrite(SerialPortObj, 0,'sync');
    fprintf('ResponseEvent%i\n',i);
    pause(1);
end
fclose(SerialPortObj);
delete(SerialPortObj);
fclose('all');