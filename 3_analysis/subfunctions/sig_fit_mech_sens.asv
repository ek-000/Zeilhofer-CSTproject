function sig_fit_mech_sens(par,stim)

% parameters
sessions= stim.session.(par.session);

if sessions==4 % fullcond
    nempty_trial= 0;
else
    nempty_trial= 1;
end

figure('color','w','position',[50 50 500 800]);

for isession= 1:length(sessions)
    subplot(length(sessions),1,isession)

    % x scale: original (default)
    if par.noXscale
        x= 1:length(stim.vf.g);
    else % x scale: one xtick per VF datapoint
        x= stim.vf.g;
    end

    % get data: percent withdrawal
    wit= stim.(par.session).withdrawal{sessions(isession)};
    if  strcmp(par.paw,'left')
        y= wit(:,stim.vf.trials_per_side{1}-nempty_trial); % imouse, itrial
    elseif  strcmp(par.paw,'right')
        y= wit(:,stim.vf.trials_per_side{2}-nempty_trial);
    end

    % remove untested mice (nans)
    y= y(all(~isnan(y),2),:);

    % plot values per mouse
    for imouse=1:size(y,1)
        scatter(x,y(imouse,:),80,'.','b'); hold on
    end
    % plot mean values
    scatter(x,mean(y,1),500,'.','color',stim.session.sessioncols{sessions(isession)});
    % fit sigmoid on mean values
    sigm_fit(x,mean(y,1)); hold on % first session to compare

        % get intersection for line crossing 50% for group (all mice together)
        ax= gca;
        ysig= ax.Children(1).YData; xsig= ax.Children(1).XData; % get sigmoid x and y
        [~,pos] = (min(abs(ysig - 50))); % smallest distance to 50 (% withdrawal)
        thresh_50pc_group= round(xsig(pos),3);

         % get intersection for line crossing 50% for each mouse, then average 
      figure;
    for imouse= 1:size(y,1)
        sigm_fit(x,y(imouse,:));
        ax= gca;
        yfit= ax.Children(1).YData; xfit= ax.Children(1).XData; % get sigmoid x and y
        [~,pos] = (min(abs(yfit - 50))); % smallest distance to 50 (% withdrawal)
        thresh_50pci(imouse)= xfit(pos);
    end
    thresh_50pc_indiv= round(mean(thresh_50pci),3);
    close(gcf)

    % appearance
    xticks(x);
    xticklabels(stim.vf.label)
    ylabel('Paw withdrawal %')
    xlabel('Von Frey filament strength (g)')
    box off
    SD_figure_appearance
    % draw 50% withdrawal line
    xl= get(gca,'xlim');
    line(xl,[50 50],'color',0.5*[1 1 1],'linestyle','--')
    set(gca,'ylim',[0 100])
     legend(stim.session.session_labels{sessions(isession)},'Location','southeast')

    % title
    ti=['vonFrey mean from ' par.paw ' par.paw'];
    name{1}=[];
    % subtitle
    name{2}= ['50% withdrawal threshold, for group: ' num2str(thresh_50pc_group) ' g'];
    name{3}= ['50% withdrawal threshold, mean from single mice: ' num2str(thresh_50pc_indiv) ' g'];
    if isession==1
        name{1}= ti;
        title(name)
    end
    title(name,'fontsize',11)
end
% par.save
if par.save
    SD_save(ti, par.saveDir)
end
