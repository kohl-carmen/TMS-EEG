function MotorThreshold()
    %%Setup Magic
    myMS = rapid('COM6','SuperPlus','8ec8-d16b8f45-39');
    myMS.connect()
    myMS.setAmplitudeA(0) 
    myMS.setChargeDelay(500)
    myMS.arm()
    myMS.ignoreCoilSafetyInterlock()

    looking = 1;
    keep_intensities = [];
    while looking
        donotset = 0;
        intensity = input('\nPlease enter intensity (press 0 to exit):')  
        while isempty(intensity)
            intensity = input('\nPlease enter intensity (press 0 to exit):')
        end
        if intensity > 99 | intensity < 0 
           fprintf('\n-Intensity invalid-')
           donotset = 1;  
        elseif intensity > 80
            confirm = input('\nHigh intensity selected - press 1 to confirm or 0 to re-enter:');   
            if confirm == 0
                donotset = 1;
            end
        end

        if ~donotset
            intensity
            myMS.setAmplitudeA(intensity) ;
            keep_intensities = [keep_intensities, intensity];
        end

        if intensity==0
            looking = 0;
        end
    end
    myMS.disconnect()
    cd('C:\Users\Jones Lab\Documents\TMSEEG\')
    save('temp','keep_intensities')
    cd('C:\Users\Jones Lab\Documents\Task_Code\New_Task_Code_Attention\Carmen')
end