function Venn_US_intensity(stim,par)

figure('position',[50 50 900 800]);% Venn diagram
for isession= par.session
    % collect data
    US.int= stim.session.USintensityLabel(isession-1,:);
    % get responsive trial ids for each cell, each US intensity
    % get all responsive trials
    US.trialIds.all= stim.traces.US.RespTrialsIds{isession};
    % split responsive trials per US intensity
    US.trialIds.l= US.trialIds.all(:,find(strcmp(US.int,'l')));
    US.trialIds.m= US.trialIds.all(:,find(strcmp(US.int,'m')));
    US.trialIds.h= US.trialIds.all(:,find(strcmp(US.int,'h')));
    US.trialIds.m(:,1)= []; % remove first trial for same number of trials as others
    % get corresponding responsive cell ids
    US.cellIds.l= find(sum(US.trialIds.l,2) >= par.minRespTrial(1));
    US.cellIds.m= find(sum(US.trialIds.m,2) >= par.minRespTrial(2));
    US.cellIds.h= find(sum(US.trialIds.h,2) >= par.minRespTrial(3));
    % get specific intensity cell ids
    US.cellIds.lOnly= setdiff(US.cellIds.l, [US.cellIds.m ; US.cellIds.h]);
    US.cellIds.mOnly= setdiff(US.cellIds.m, [US.cellIds.l ; US.cellIds.h]);
    US.cellIds.hOnly= setdiff(US.cellIds.h, [US.cellIds.l ; US.cellIds.m]);
    % get overlap
    US.cellIds.lm= intersect(US.cellIds.l,US.cellIds.m);
    US.cellIds.mh= intersect(US.cellIds.m,US.cellIds.h);
    US.cellIds.lh= intersect(US.cellIds.l,US.cellIds.h);
    US.cellIds.lmh= intersect(US.cellIds.lm,US.cellIds.lh);
    US.cellIds_any= unique([US.cellIds.l; US.cellIds.m; US.cellIds.h]);
    
    % plot
    subplot(2,2,find(isession==par.session))
    venn([length(US.cellIds.l) length(US.cellIds.m) length(US.cellIds.h)],... % venn([c1 c2 c3],...
        [length(US.cellIds.lm) length(US.cellIds.mh) length(US.cellIds.lh)  length(US.cellIds.lmh)]);  % [i12 i13 i23 i123])
    hold on
    % appearance
    % circles properties
    ax= gca; tr= par.transparency;
    [ax.Children(:).FaceAlpha]= deal(tr(1),tr(2),tr(3)); % transparency
    [ax.Children(:).FaceColor]= deal(par.cols{1},par.cols{2},par.cols{3}); % color
    SD_figure_appearance; axis off
    % name
    clear name T; name{1}= ['session ' num2str(isession) ' ' stim.session.session_labels{isession}];
    name{2}= ['US-responsive cells to at least ' num2str(par.minRespTrial) ' stimuli'];
    name{3}= '(among all cells)';
    name{4}= 'US intensity: yel= low(l); ora= medium(m); red= high(h)';
    title(name,'fontsize',10); % title
    % text numbers
    f=fieldnames(US.cellIds);
    % all cells= cell with response to any US intensity
    for ifield=1:length(fieldnames(US.cellIds))
        n= length(US.cellIds.(f{ifield})) / stim.session.ncell(isession) *100;
        T{ifield}= [f{ifield} ': ' num2str(round(n,1)) ' %'];
    end
    T{ifield+1}= [num2str(length(US.cellIds_any)) ' US-responsive cells'];
    subplot(2,2,2+find(isession==par.session))
    axis off
    text(0.1,0.9,T,'interpreter','none','fontsize',10.5);
end

if par.save
    SD_save(name{1},par.saveDir);
end