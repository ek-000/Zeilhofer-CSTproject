function [dat, means]= VonFrey_auto(data,stim,par)

sessions= stim.session.(par.session);

%% collect data
% find auto VonFrey trials 
trials_auto= stim.vf.trials_auto;
% get withdrawal threshold
for isession= 1:length(sessions)
    for imouse= stim.mice
        % for individual trials
        with_thres= [data(imouse,sessions(isession)).info.behavior(trials_auto).Hargreaves_sec_to_withdrawal];
        % mean per mouse
        with_thres_per_mouse(:,imouse,sessions(isession))= mean(with_thres,1); % side, mouse, session
    end
end

%% boxplot
% define data 
name{1}= [stim.groupName 'Automatic VonFrey withdrawal threshold'];
lab= {'BSL L','CCI L','BSL R','CCI R'}; % labels: baseline Vs CCI, right Vs left paw
dat= {with_thres_per_mouse(1,:,5), with_thres_per_mouse(1,:,6), with_thres_per_mouse(2,:,5), with_thres_per_mouse(2,:,6)};

% plot
figure('color','w')
[yl,mm_ss_n_str]= boxplots(dat,'mean','color',{'k','r','k','r'},'line','scatter','marker_alpha',par.marker_alpha);
% apperance
legend(mm_ss_n_str,'location','southeast','fontsize',9)
ylim([0 yl(2)])
xticklabels(lab)
ylabel('Withdrawal threshold (g)')

% statistics
[str,~,p,~,means,~,mmssstr]= SD_anovan(dat,'BC');
name{2}= str;
name{3}= ['P= ' num2str(round(p,3))];
name{4}= mmssstr;
title(name,'fontsize',12); % update title

% par.save
if par.save
    SD_save(name{1}, par.saveDir)
end






