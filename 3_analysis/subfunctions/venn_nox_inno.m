function venn_nox_inno(stim,par)

par.side=   {'R','L'}; % 'R' or 'L'
sessions= stim.session.(par.session);

for iside= 1: length(par.side)
    side= par.side{iside};

    % get test ids per side, noxious or innocuous
    sideTests= stim.side{strcmp(side,stim.labels)};
    SideTestsNox= stim.noxious.testIds(find(ismember(stim.noxious.testIds, sideTests)));
    SideTestsNox= SideTestsNox-1; % remove spontaneous
    SideTestsInnoc= stim.innocuous.testIds(find(ismember(stim.innocuous.testIds, sideTests)));
    SideTestsInnoc= SideTestsInnoc-1; % remove spontaneous

    figure('position',[50 50 800 700]);

    for isession= sessions
        % collect data: responsive cell Inds to any noxious or innocuous test per side
        % noxious ids
        temp=           stim.traces.(par.session).respCellIds(isession,SideTestsNox); % get cell ids for each test
        noxiousIds=     unique(cell2mat(temp')); % combine responsive cell ids: to any test
        % innocuous ids
        temp=           stim.traces.(par.session).respCellIds(isession,SideTestsInnoc); % get cell ids for each test
        innocuousIds=   unique(cell2mat(temp')); % combine responsive cell ids: to any testend
        % overlap ids
        noxInnoOvIds=   intersect(noxiousIds, innocuousIds);
        % plot
        subplot(2,2,find(isession==sessions))
        venn([stim.session.ncell(isession) length(innocuousIds) length(noxiousIds)],...
            [length(innocuousIds) length(noxiousIds) length(noxInnoOvIds)  length(noxInnoOvIds)]); % venn([c1 c2 c3], [i12 i13 i23 i123])
        % appearance
        SD_figure_appearance; axis off
        % circles properties
        ax= gca; tr= par.transparency(isession==sessions);
        [ax.Children(:).FaceAlpha]= deal(tr,tr,tr); % transparency
        [ax.Children(:).FaceColor]= deal(par.cols{1},par.cols{2},par.cols{3}); % color

        name= ['session ' num2str(isession) '  ' side];
        title(name); % title

        % collect overlap percentages
        overlapPC.noxious_of_all=           length(noxiousIds)/stim.session.ncell(isession)*100;
        overlapPC.innocuous_of_all=         length(innocuousIds)/stim.session.ncell(isession)*100;
        overlapPC.noxious_innocuous_of_all= length(noxInnoOvIds)/stim.session.ncell(isession)*100;
        overlapPC.noxious_only_of_all=      (length(noxiousIds)-length(noxInnoOvIds))/stim.session.ncell(isession)*100;
        overlapPC.innocuous_only_of_all=    (length(innocuousIds)-length(noxInnoOvIds))/stim.session.ncell(isession)*100;
        overlapPC.noxious_of_innocuous=     length(noxInnoOvIds)/length(innocuousIds)*100;
        overlapPC.innocuous_of_noxious=     length(noxInnoOvIds)/length(noxiousIds)*100;

        % values to string for plot title
        f=fieldnames(overlapPC);
        for ifield=1:length(fieldnames(overlapPC))
            T{ifield}= [f{ifield} ': ' num2str(round(overlapPC.(f{ifield}),1)) ' %'];
        end
        subplot(2,2,2+find(isession==sessions))
        axis off
        text(0.1,0.9,T,'interpreter','none','fontsize',10.5);
    end
    % par.save
    if par.save
        SD_save(name, par.saveDir)
    end
end