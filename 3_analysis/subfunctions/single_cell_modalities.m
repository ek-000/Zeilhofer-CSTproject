function single_cell_modalities(sessions,respidsstore,side,sorted_trials_side,saveDir,opt)

% tests
dat={[sorted_trials_side.test_ids.innocuous sorted_trials_side.test_ids.noxious],...
    sorted_trials_side.test_ids.noxious, sorted_trials_side.test_ids.innocuous}; % on plot per dat (all modalities, noxious and innocuous)
% data labels
names = {'All sensory modalities:','Noxious modalities:','Innocuous modalities:'};

for isession= sessions
    figure('position',[50 50 1000 500]);
    NAME= ['Number of sensory modalities per cell  session ' num2str(isession) ' ' side];
    for idat=1:length(dat)
        side_trials= sorted_trials_side.side{find(strcmp(side,sorted_trials_side.labels))};  % only one side
        trials= dat{idat}(ismember(dat{idat}, side_trials)); % restrict to test of the chosen modalities on chosen side

        if contains(sorted_trials_side.names{1},'spontaneous')
            trials= trials-1;

        end
        subplot(1,length(dat),idat)
        ids= respidsstore{isession}(:,trials);
        ov= sum(ids,2);
        h= histogram(ov,'Normalization','probability');
        % add label % cells
        lab= num2str(round(h.Values*100)');
        text(0:length(h.Values)-1,h.Values,lab,'horizontalalignment','center','verticalalignment','top')
        xticks(0:length(trials))
        clear name; name{1}= names{idat};
        if contains(sorted_trials_side.names{1},'spontaneous')
            trials= trials+ 1; % for title only
        end
        title( [name{1} sorted_trials_side.names(trials)] )

        SD_figure_appearance;
    end
    sgtitle(NAME)
    sglabels('Number of modalities per cell','Proportion of responsive neurons')
    if opt.save
        SD_save(NAME,saveDir)
    end
end