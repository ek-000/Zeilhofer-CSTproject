function Number_responsive_trials_per_cell(stim,par)

sessions= stim.session.(par.stim);

figure('position', [100 100, 500 500]); clear RespTrials name
for isession= 1:length(sessions)
    % get number of responsive trials per cell
    RespTrials{isession}= sum(stim.traces.(par.stim).RespTrialsIds{sessions(isession)},2)'; % sum of responsive cells per trial
end
dat= RespTrials;
% plot
boxplots(dat,'mean','color', stim.session.sessioncols(sessions));
xlabel('trial')
ylabel('number of trials')
SD_figure_appearance;
name{1}= [stim.groupName ' ' par.stim ' number of responsive trials per cell'];
% statistics
[str,~,p,~,~,~,mm_ss_string]= SD_anovan(dat,'BC');
name{2}= str; name{3}= ['P= ' num2str(round(p,3))]; name{4}= mm_ss_string;
title(name)
if par.save % save
    SD_save(name{1},par.saveDir);
end