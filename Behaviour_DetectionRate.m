
Partic = [7,9:12,14,18,20,22,23];

plot_per_partic = 1
% 
% %set up ppt
out_dir =  strcat('C:\Users\ckohl\Desktop\Data\');
% cd(out_dir)
% import mlreportgen.ppt.*
% ppt = Presentation(strcat('Behaviour Summary'));
% open(ppt);
% titleSlide = add(ppt,'Title Slide');
% replace(titleSlide,"Title",strcat('Behaviour Summary -  BehaviourIII.m'));

Session_name = {'Control','SI'};

hit_rate_tms0 = nan(length(Partic),2);
hit_rate_tms1 = nan(length(Partic),2);
hit_rate_tms2 = nan(length(Partic),2);
perc_change_tms0 = nan(length(Partic),2);
perc_change_tms1 = nan(length(Partic),2);
perc_change_tms2 = nan(length(Partic),2);

cmap = colormap;
colours_i = round([1 : length(cmap)/length(Partic) : length(cmap)]);
colours = cmap(colours_i,:);
     
for partic = 1:length(Partic)
    if plot_per_partic
        tempfig = figure()
        tempfig.Position(3) = tempfig.Position(3)*1.5;
        ylims = [0 0];
        x = 1:3;
    end
    partic_str = sprintf('%02d', Partic(partic));
    for session = [0,1]
        if plot_per_partic
            subplot(1,2,session+1)
            hold on
            xlim([x(1)-1,x(end)+1])
            title(strcat('Detection Rate - Partic: ',num2str(Partic(partic)),'Session: ',Session_name{session+1}))
        end
        sess_dir = strcat(out_dir,'BETA',partic_str,'\Session',num2str(session));
        if exist(sess_dir,'dir')
            %% Load
            file=strcat(sess_dir, '\beta',partic_str,'_results');
            file2=strcat(sess_dir, '\beta_',partic_str,'_results');
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
            
            % CueCond: 0=Hand, 1=Head
            % TapCond: 0=Null, 1=Threshold, 2=Supra
            % TMSCond: 0=Null, 1=100, 2=25

            %% Detection Rate            
%             hit rate for a given TMS condition =  # detected trials for a given TMS condition / total # trials for a given TMS condition
%             mean hit rate across all TMS conditions = mean of hit rate for all conds
%             percent change in hit rate from the mean for a given TMS condition = (hit rate for a given TMS condition / hit rate across all TMS condition )* 100 

            hit_rate_tms0(partic,session+1) = sum(Accuracy(CueCond==0 & TapCond==1 & TMSCond==0))/length(Accuracy(CueCond==0 & TapCond==1 & TMSCond==0));
            hit_rate_tms1(partic,session+1) = sum(Accuracy(CueCond==0 & TapCond==1 & TMSCond==1))/length(Accuracy(CueCond==0 & TapCond==1 & TMSCond==1));
            hit_rate_tms2(partic,session+1) = sum(Accuracy(CueCond==0 & TapCond==1 & TMSCond==2))/length(Accuracy(CueCond==0 & TapCond==1 & TMSCond==2));
            
            mean_hit_rate(partic,session+1) = nanmean([hit_rate_tms0(partic,session+1),hit_rate_tms1(partic,session+1),hit_rate_tms2(partic,session+1)]);
            
            perc_change_tms0(partic,session+1) = (hit_rate_tms0(partic,session+1) - mean_hit_rate(partic,session+1))/mean_hit_rate(partic,session+1)*100;
            perc_change_tms1(partic,session+1) = (hit_rate_tms1(partic,session+1) - mean_hit_rate(partic,session+1))/mean_hit_rate(partic,session+1)*100;
            perc_change_tms2(partic,session+1) = (hit_rate_tms2(partic,session+1) - mean_hit_rate(partic,session+1))/mean_hit_rate(partic,session+1)*100;
                
            if plot_per_partic 
                
                toplot = [perc_change_tms0(partic,session+1);perc_change_tms1(partic,session+1);perc_change_tms2(partic,session+1)];
                p = plot(x, toplot,'-','Color',colours(partic,:));
                scatter(x,toplot,150,'filled','MarkerFaceAlpha',3/8,'MarkerFaceColor',p.Color)   
                ylims_temp = ylim();
                ylims(1) = min(ylims(1),ylims_temp(1));
                ylims(2) = max(ylims(2),ylims_temp(2));
                legend(strcat('Mean Hit Rate: ', num2str(mean_hit_rate(partic,session+1))))
            end
        end
    end
    subplot(1,2,1)
    set(gca,'XTick',[1,2,3])
    set(gca,'xticklabel',{['TMS0'],['TMS100'],['TMS25']})
    ylabel('% change')   
    ylim(ylims)
    subplot(1,2,2)
    set(gca,'XTick',[1,2,3])
    set(gca,'xticklabel',{['TMS0'],['TMS100'],['TMS25']})
    ylabel('% change')   
    ylim(ylims)
    print(tempfig,"-dpng",strcat('tempfig',num2str(partic)))
end
             
%% Plot          
tempfig = figure();
tempfig.Position(3) = tempfig.Position(3)*1.5;
hold on
ylims = [0 0];
for session = [0,1]
    subplot(1,2,session+1)
    hold on
    title(strcat('Detection Rate - Session: ',Session_name{session+1}))
    toplot =[nanmean(perc_change_tms0(:,session+1));nanmean(perc_change_tms1(:,session+1));nanmean(perc_change_tms2(:,session+1))];
    
    b = bar(toplot,'FaceColor','flat');
    b.CData(1,:) = [255,160,122]./255;
    b.CData(2,:) = [205,92,92]./255;
    b.CData(3,:) = [139,0,0]./255;

    % errors
    sq = sqrt(length(perc_change_tms0(:,session+1)));
    error_toplot =[nanstd(perc_change_tms0(:,session+1))/sq,nanstd(perc_change_tms1(:,session+1))/sq,nanstd(perc_change_tms2(:,session+1))/sq];
    tick = 0.225;
    err=errorbar([1:3],toplot,error_toplot);
    err(1).Color = [0 0 0];                         
    err(1).LineStyle = 'none'; 
    
%     %swarmchart overlay
%     y = perc_change_tms0(:,session+1)';
%     x = ones(1,length(perc_change_tms0(:,session+1)'));
%     swarmchart(x,y,20,[255,160,122]./255,'filled','MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5)
%     
%     y = perc_change_tms1(:,session+1)';
%     x = ones(1,length(perc_change_tms1(:,session+1)'))*2;
%     swarmchart(x,y,20,[205,92,92]./255,'filled','MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5)
%     
%     y = perc_change_tms2(:,session+1)';
%     x = ones(1,length(perc_change_tms2(:,session+1)'))*3;
%     swarmchart(x,y,20,[130,0,0]./255,'filled','MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5)

    set(gca,'XTick',[1,2,3])
    set(gca,'xticklabel',{['TMS0'],['TMS100'],['TMS25']})
    ylabel('% change')   
    ylims_temp = ylim();
    ylims(1) = min(ylims(1),ylims_temp(1));
    ylims(2) = max(ylims(2),ylims_temp(2));
end
ylim(ylims)
subplot(1,2,session)
ylim(ylims)
print(tempfig,"-dpng",'tempfig111')
%ppt
% slide = add(ppt,"Title and Content");replace(slide,"Title",'Threshold Tap Detection Rate');
% print(tempfig,"-dpng",'tempfig1');Imageslide = Picture('tempfig1.png');
% replace(slide,"Content",Imageslide);


%% Plot          
tempfig = figure();
tempfig.Position(3) = tempfig.Position(3)*1.5;
hold on
ylims = [0 0];

 
x = [1:3];
for session = [0,1]
    subplot(1,2,session+1)
    hold on
    xlim([x(1)-1,x(end)+1])
    title(strcat('Detection Rate - Session: ',Session_name{session+1}))
    for partic = 1:length(Partic)
        
        toplot = [perc_change_tms0(partic,session+1);perc_change_tms1(partic,session+1);perc_change_tms2(partic,session+1)];
        p = plot(x, toplot,'-','Color',colours(partic,:));
        
        scatter(x,toplot,150,'filled','MarkerFaceAlpha',3/8,'MarkerFaceColor',p.Color)      
   
    end
    %mean
    toplot =[nanmean(perc_change_tms0(:,session+1));nanmean(perc_change_tms1(:,session+1));nanmean(perc_change_tms2(:,session+1))];
    plot(x,toplot,'k-','Linewidth',2) 
    err=errorbar([1:3],toplot,error_toplot);
    err(1).Color = [0 0 0];                         
    err(1).LineStyle = 'none';
    err(1).LineWidth = 2;
    
    
    set(gca,'XTick',[1,2,3])
    set(gca,'xticklabel',{['TMS0'],['TMS100'],['TMS25']})
    ylabel('% change')   
    ylims_temp = ylim();
    ylims(1) = min(ylims(1),ylims_temp(1));
    ylims(2) = max(ylims(2),ylims_temp(2));
end
ylim(ylims)
subplot(1,2,session)
ylim(ylims)
print(tempfig,"-dpng",'tempfig112')


% 
% close(ppt)
% delete tempfig1.png 
% close all    