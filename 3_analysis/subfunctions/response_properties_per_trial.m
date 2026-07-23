function response_properties_per_trial(stim,par)

if ~isempty(par.trial)
    par.ntrial= length(par.trial);
else
    par.ntrial= 10;
    par.trial= 1:10;
end
% get the right minimum number of resposive trials to consider high
% fidelity
istim= find(strcmp(par.stims, par.stim));
par.minRespTrial= par.minRespTrials(istim);

sessions= stim.session.(par.stim);
figure('position', [100 100 1600 1000]);

%% porportion of responsive cells per trial
for isession= 1:length(sessions)
    subplot(3,length(sessions)+1,isession);
    % get percent responsive cells per trial
    SumRespCells= sum(stim.traces.(par.stim).RespTrialsIds{sessions(isession)}(:,par.trial)); % sum of responsive cells per trial
    PcRespCells{isession}= SumRespCells./stim.session.ncell(isession)*100; % percentage responsive cells per trial
    % plot
    b= bar(PcRespCells{isession});
    b.FaceColor= 'k';
    xlabel('trial');
    ylabel('% resp. cells per trial');
    SD_figure_appearance
    xlabel(stim.session.session_labels(sessions(isession)));
    SD_figure_appearance
end
linkaxes
% quantification (boxplot)
subplot(3,length(sessions)+1,isession+1);
dat= PcRespCells;
yl= boxplots(dat,'mean','color',stim.session.sessioncols(sessions));
ylim([0 yl(2)]);
% statistics
[str,~,p,~,~,~,mm_ss_string]= SD_anovan(dat,'BC');
name{1}= str;
name{2}= ['P= ' num2str(round(p,3))];
name{3}= mm_ss_string;
title(name,'fontsize',12);
ylabel('% resp. cells per trial');
xticklabels(stim.session.session_labels);
NAME= [stim.groupName ' ' par.stim ' percent responsive cells per trial'];
subtitle(NAME);
SD_figure_appearance

%% mean response amplitude per cell per number of responsive trial
for isession= 1:length(sessions)
    respIntCatlo{isession}=[]; respIntCathi{isession}=[];
    ax(isession) = subplot(3,length(sessions)+1,2*(length(sessions)+1)+isession);
    % get mean response amplitude per responsive trial
    % get responsive trials
    resp_trials= stim.traces.(par.stim).RespTrialsIds{sessions(isession)}(:,par.trial);
    nresp_trials= sum(resp_trials,2);
    % get response integral per trial
    trials_resp= squeeze(trapz(stim.traces.(par.stim).meanTrialResponse{sessions(isession)}(:,stim.traces.(par.stim).twin_resp,par.trial),2));
    % calculate mean response of each cell to its responsive trials, split
    % by number of responsive trials per cell
    for inrespTrial= 1:size(trials_resp,2) % for a
        % select subset of cells that respond a particular number of trials
        trials_resp_sub= trials_resp(nresp_trials==inrespTrial,:);
        resp_trials_sub= resp_trials(nresp_trials==inrespTrial,:);

        % get mean response over responsive trials for each responsive cell
        respInt=[];
        for icell= 1:size(trials_resp_sub,1)
            respInt(icell)= mean(trials_resp_sub(icell, resp_trials_sub(icell,:)));
        end
        % average mean responses for all cells responsive to this number of
        % trials
        [mm(inrespTrial),ss(inrespTrial),ncell(inrespTrial)]= SD_mmss(respInt);
        if ncell(inrespTrial)==1 % remove data from 1 cell
            mm(inrespTrial)=nan; ss(inrespTrial)= nan;
        end
        if inrespTrial>=par.minRespTrial
            respIntCathi{isession}= [respIntCathi{isession} respInt];
        elseif inrespTrial<par.minRespTrial
            respIntCatlo{isession}= [respIntCatlo{isession} respInt];
        end
    end
    summary(sessions(isession)).meanIntegralResp= mm; %%%%%
    % plot
    b= bar(1:size(trials_resp,2), mm); hold on
    b.FaceColor= 'flat';
    b.CData(1:par.minRespTrial-1,:)= repmat([0 0 0], par.minRespTrial-1, 1 ); % unreliable cells color
    b.CData(par.minRespTrial:end,:)= repmat([1 0 0], par.ntrial-par.minRespTrial+1, 1 );  % reliable cells colors
    er= errorbar(1:size(trials_resp,2),mm,ss,'k','linestyle','none');
    er.YNegativeDelta= [];
    xlabel(stim.session.session_labels(sessions(isession)));
    ylabel('Resp. integral per cell');
    SD_figure_appearance
    linkaxes(ax);


    %% proportion of responsive cells per trial number
    ax2(isession) = subplot(3,length(sessions)+1,length(sessions)+1+isession);
    % plot
    n= ncell/size(nresp_trials,1)*100;
    respNlo(isession)= sum(n(1:par.minRespTrial-1)); % get number of cells per session with low response fidelity
    respNhi(isession)= sum(n(par.minRespTrial:end)); % get number of cells per session with high response fidelity
    b= bar(1:size(trials_resp,2),n);
    b.FaceColor= 'flat';
    b.CData(1:par.minRespTrial-1,:)= repmat([0 0 0], par.minRespTrial-1, 1 ); % unreliable cells color
    b.CData(par.minRespTrial:end,:)= repmat([1 0 0], par.ntrial-par.minRespTrial+1, 1 );  % reliable cells colors
    xlabel(stim.session.session_labels(sessions(isession)));
    ylabel('% resp. cells per nb resp. trials')
    SD_figure_appearance
    linkaxes(ax2);
    summary(sessions(isession)).PercentRespCells= n; %%%%%
end

% summary number of cells with low or high fidelity per session
subplot(3,length(sessions)+1,length(sessions)+1+isession+1)
b= bar(1:6,[respNlo respNhi]);
b.FaceColor= 'flat';
b.CData(1:3,:)= repmat([0 0 0], 3, 1 ); % unreliable cells color
b.CData(4:6,:)= repmat([1 0 0], 3, 1 );  % reliable cells colors
xticklabels( [stim.session.session_labels(sessions) stim.session.session_labels(sessions)] );
ylabel('% resp. cells');
SD_figure_appearance
title('Sum low/high fidelity cells %','fontsize',12);

% summary number of cells with low or high fidelity per session
subplot(3,length(sessions)+1,2*(length(sessions)+1)+isession+1);
dat= [respIntCatlo respIntCathi];
yl= boxplots(dat,'mean','color', {'k','k','k','r','r','r'});
SD_figure_appearance
ylabel('Resp. integral per cell');
ylim([0 yl(2)]);
% statistics: compare low or high fidelity cells for each session
clear name;
try str14= SD_ttest(dat{1},dat{isession+1});  name{1}= str14{2}; end
try str25= SD_ttest(dat{2},dat{isession+2});    name{2}= str25{2}; end
try str36= SD_ttest(dat{3},dat{isession+3});    name{3}= str36{2}; end
try title(name, 'fontsize',12); end

xticklabels( [stim.session.session_labels(sessions) stim.session.session_labels(sessions)] );

% add information content to label: norm (integral response * % resp. cells * nb trials)
for isession= 1:length(sessions)
    % integral response * % resp. cells * nb trials
    info_content(isession,:)= summary(sessions(isession)).meanIntegralResp .* summary(sessions(isession)).PercentRespCells .* [1:par.ntrial];
end

% sum up content per low and high fidelity
info_contentLow=    nansum(info_content(:,1:par.minRespTrial-1),2);
info_contentHigh=   nansum(info_content(:,par.minRespTrial:end),2);
% normalize content to the total information per session 
normval= info_contentLow+info_contentHigh;
info_contentLow= info_contentLow./(normval)*100;
info_contentHigh= info_contentHigh./(normval)*100;
% add label
for isession= 1:length(sessions)
    subplot(3,length(sessions)+1,2*(length(sessions)+1)+isession);
    xlabel({stim.session.session_labels{sessions(isession)},['Relative response contribution: '...
    num2str(round(info_contentLow(isession),1)) ' - '  num2str(round(info_contentHigh(isession),1)) '%']},'fontsize',12);
end


NAME=  [stim.groupName ' ' par.stim ' Response properties per trial ' num2str(par.trial)];
subtitle(NAME);

if par.save % save
    SD_save(NAME,par.saveDir);
end

