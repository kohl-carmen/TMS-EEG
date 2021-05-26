%% Sanitycheck all behavioural output and print performance
clear

plot_individual = 0;
fig_overall_acc = figure();
fig_overall_rt = figure();
for session = [0,1]
    if session == 0
        Partics = [9,10,11,14,22];
    else
        Partics = [7, 9,10,11,12,22]
    end
       
    KEEP_ACC = struct();
    KEEP_RT = struct();
    pcount=0;
    for partic = Partics
        pcount=pcount+1;

        partic_str = sprintf('%02d', partic);
        filedir = strcat('C:\Users\ckohl\Desktop\Data\Beta',partic_str,'\Session',num2str(session));
        file=strcat(filedir, '\beta',partic_str,'_results');
        file2=strcat(filedir, '\beta_',partic_str,'_results');

        %% load behavioural data
        opts = delimitedTextImportOptions("NumVariables", 11);
        opts.DataLines = [6, Inf];
        opts.Delimiter = "\t";
        opts.VariableNames = ["Trial", "CueCond", "TMSCond", "TapCond", "Accuracy", "YesResponse", "NoResponse", "TapTime", "TMSTime", "RT", "Threshold"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
        try
            tbl = readtable(file, opts);
        catch
            tbl = readtable(file2, opts);
        end
        % Convert to output type
        Trial = tbl.Trial;
        CueCond = tbl.CueCond;
        TMSCond = tbl.TMSCond;
        TapCond = tbl.TapCond;
        Accuracy = tbl.Accuracy;
        YesResponse = tbl.YesResponse;
        NoResponse = tbl.NoResponse;
        TapTime = tbl.TapTime;
        TMSTime = tbl.TMSTime;
        RT = tbl.RT;
        Threshold = tbl.Threshold;
        clear opts tbl


        disp ('------------------------------')
        disp('check performance')
        disp ('------------------------------')  
        fprintf('BETA%s\n',partic_str)
        disp ('------------------------------')  
        disp(' ')

        txt = sprintf('\nDetecting Taps -  overall\n');
        fprintf('%s',txt);
        txt = sprintf('Null Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==0 & CueCond==0))*100), round(mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1))));
        fprintf('%s\n',txt);
        txt = sprintf('Threshold Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==1 & CueCond==0))*100), round(mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1))));      
        fprintf('%s\n',txt);
        txt = sprintf('Supra Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==2 & CueCond==0))*100), round(mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1))));      
        fprintf('%s\n',txt);


        txt = sprintf('\nDetecting TMS -  overall\n');
        fprintf('%s',txt);

        txt = sprintf('Null TMS:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TMSCond==0 & CueCond==1))*100), round(mean(RT(TMSCond==0 & CueCond==1 & Accuracy ==1)))) ;     
        fprintf('%s\n',txt);

        txt = sprintf('TMS100:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TMSCond==1 & CueCond==1))*100), round(mean(RT(TMSCond==1 & CueCond==1 & Accuracy ==1))));      
        fprintf('%s\n',txt);

        txt = sprintf('TMS25:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TMSCond==2 & CueCond==1))*100), round(mean(RT(TMSCond==2 & CueCond==1 & Accuracy ==1)))) ;
        fprintf('%s\n',txt);


        txt = sprintf('\nDetecting Taps -  No TMS\n');
        fprintf('%s',txt);

        txt = sprintf('Null Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==0))*100), round(mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==0))));      
        fprintf('%s\n',txt);
        KEEP_ACC.NoTMS.Null(pcount) = mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==0));
        KEEP_RT.NoTMS.Null(pcount)  = mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==0))./1000;

        txt = sprintf('Threshold Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==0))*100), round(mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==0)))) ;     
        fprintf('%s\n',txt);
        KEEP_ACC.NoTMS.Thresh(pcount)  = mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==0));
        KEEP_RT.NoTMS.Thresh(pcount)  = mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==0))./1000;

        txt = sprintf('Supra Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==0))*100), round(mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==0))));      
        fprintf('%s\n',txt);
        KEEP_ACC.NoTMS.Supra(pcount)  = mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==0));
        KEEP_RT.NoTMS.Supra(pcount)  = mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==0))./1000;



        txt = sprintf('\nDetecting Taps -  100ms\n');
        fprintf('%s',txt);

        txt = sprintf('Null Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==1))*100), round(mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==1)))) ;     
        fprintf('%s\n',txt);
        KEEP_ACC.TMS100.Null(pcount)  = mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==1));
        KEEP_RT.TMS100.Null(pcount)  = mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==1))./1000;

        txt = sprintf('Threshold Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==1))*100), round(mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==1))))  ;    
        fprintf('%s\n',txt);
        KEEP_ACC.TMS100.Thresh(pcount)  = mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==1));
        KEEP_RT.TMS100.Thresh(pcount)  = mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==1))./1000;

        txt = sprintf('Supra Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==1))*100), round(mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==0)))); 
        fprintf('%s\n',txt);
        KEEP_ACC.TMS100.Supra(pcount)  = mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==1));
        KEEP_RT.TMS100.Supra(pcount)  = mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==1))./1000;


        txt = sprintf('\nDetecting Taps -  25ms\n');
        fprintf('%s',txt);

        txt = sprintf('Null Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==2))*100), round(mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==2))))  ;    
        fprintf('%s\n',txt);
        KEEP_ACC.TMS25.Null(pcount)  = mean(Accuracy(TapCond==0 & CueCond==0 & TMSCond==2));
        KEEP_RT.TMS25.Null(pcount)  = mean(RT(TapCond==0 & CueCond==0 & Accuracy ==1 & TMSCond==2))./1000;

        txt = sprintf('Threshold Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==2))*100), round(mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==2)))) ;     
        fprintf('%s\n',txt);
        KEEP_ACC.TMS25.Thresh(pcount)  = mean(Accuracy(TapCond==1 & CueCond==0 & TMSCond==2));
        KEEP_RT.TMS25.Thresh(pcount)  = mean(RT(TapCond==1 & CueCond==0 & Accuracy ==1 & TMSCond==2))./1000;

        txt = sprintf('Supra Tap:\tAccuracy: %i%%,  RT: %ims',round(mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==2))*100), round(mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==2)))) ; 
        fprintf('%s\n',txt);
        KEEP_ACC.TMS25.Supra(pcount)  = mean(Accuracy(TapCond==2 & CueCond==0 & TMSCond==2));
        KEEP_RT.TMS25.Supra(pcount)  = mean(RT(TapCond==2 & CueCond==0 & Accuracy ==1 & TMSCond==2))./1000;


        if plot_individual
            figure
            hold on
            subplot(1,2,1)
            hold on
            title('Accuracy')
            toplot = [KEEP_ACC.NoTMS.Null(pcount) ,KEEP_ACC.TMS100.Null(pcount) ,KEEP_ACC.TMS25.Null(pcount) ;...
                KEEP_ACC.NoTMS.Supra(pcount) , KEEP_ACC.TMS100.Supra(pcount) ,KEEP_ACC.TMS25.Supra(pcount) ;...
                KEEP_ACC.NoTMS.Thresh(pcount) ,KEEP_ACC.TMS100.Thresh(pcount) ,KEEP_ACC.TMS25.Thresh(pcount) ];
            bar(toplot)
            set(gca,'XTick',[1,2,3])
            set(gca,'xticklabel',{['No Tap'],['Supra Tap'],['Threshold Tap']})
            ylabel('Accuracy (proportion correct)')
            ylim([0 1])

            subplot(1,2,2)
            hold on
            title('RT')
            toplot = [KEEP_RT.NoTMS.Null(pcount) ,KEEP_RT.TMS100.Null(pcount) ,KEEP_RT.TMS25.Null(pcount) ;...
                KEEP_RT.NoTMS.Supra(pcount) , KEEP_RT.TMS100.Supra(pcount) ,KEEP_RT.TMS25.Supra(pcount) ;...
                KEEP_RT.NoTMS.Thresh(pcount) ,KEEP_RT.TMS100.Thresh(pcount) ,KEEP_RT.TMS25.Thresh(pcount) ];
            bar(toplot)
            ylim([0 1])
            legend('NoTMS','TMS100','TMS25')
            set(gca,'XTick',[1,2,3])
            set(gca,'xticklabel',{['No Tap'],['Supra Tap'],['Threshold Tap']})
            ylabel('RT (s)')

            cd('C:\Users\ckohl\Desktop\Data\')
            print("-dpng",strcat('Partic',num2str(partic),'Sess',num2str(session)))
        end

    end


    %% Overall
    %ACC
    figure(fig_overall_acc)
    hold on
    subplot(1,2,session+1)
    hold on
    title(strcat('Accuracy - Session',num2str(session)))
    toplot = [mean(KEEP_ACC.NoTMS.Null) ,mean(KEEP_ACC.TMS100.Null) ,mean(KEEP_ACC.TMS25.Null) ;...
        mean(KEEP_ACC.NoTMS.Supra) , mean(KEEP_ACC.TMS100.Supra) ,mean(KEEP_ACC.TMS25.Supra) ;...
        mean(KEEP_ACC.NoTMS.Thresh) ,mean(KEEP_ACC.TMS100.Thresh) ,mean(KEEP_ACC.TMS25.Thresh) ];
    bar(toplot)
    set(gca,'XTick',[1,2,3])
    set(gca,'xticklabel',{['No Tap'],['Supra Tap'],['Threshold Tap']})
    ylabel('Accuracy (proportion correct)')
    ylim([0 1])
    
    %RT
    figure(fig_overall_rt)
    subplot(1,2,session+1)
    hold on
    title(strcat('RT - Session',num2str(session)))
    toplot = [mean(KEEP_RT.NoTMS.Null) ,mean(KEEP_RT.TMS100.Null) ,mean(KEEP_RT.TMS25.Null) ;...
        mean(KEEP_RT.NoTMS.Supra) ,mean(KEEP_RT.TMS100.Supra) ,mean(KEEP_RT.TMS25.Supra) ;...
        mean(KEEP_RT.NoTMS.Thresh) ,mean(KEEP_RT.TMS100.Thresh) ,mean(KEEP_RT.TMS25.Thresh) ];
    bar(toplot)
    ylim([0 1])
    legend('NoTMS','TMS100','TMS25')
    set(gca,'XTick',[1,2,3])
    set(gca,'xticklabel',{['No Tap'],['Supra Tap'],['Threshold Tap']})
    ylabel('RT (s)')
end


