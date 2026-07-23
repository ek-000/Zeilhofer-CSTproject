function compare_motion(groupStim,par)

isession= 1;
dat= {groupStim{1}.mean_motion(:,isession), groupStim{2}.mean_motion(:,isession)};

figure;
yl= boxplots(dat,'mean','line','scatter','marker_alpha',0.5);
    ylim([0 yl(2)])
    SD_figure_appearance
    xticklabels(stim.session.session_labels);
    ylabel('ratio time in center / corners')
    % statistics
    SD_ttest(dat{1},dat{2});