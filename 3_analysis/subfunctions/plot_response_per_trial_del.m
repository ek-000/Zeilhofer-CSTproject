function  [dat,means]= plot_response_per_trial(stim,par)

means=[];

if contains(par.stim,'motion') && par.high_fr_motion
    stim(1).fr= par.motion_frame_rate;
end

% parameters
istim= find(strcmp(par.stims,par.stim)); % stimulus number
sessions= stim(1).session.(par.stim);
filtering= hanning(par.filt(istim))./sum(hanning(par.filt(istim))); % low-pass filtering
t= stim(1).(par.stim).twinp/stim(1).fr;
session_labels= stim(1).session.session_labels(sessions); % get session names
USintensityLabel= stim(1).session.USintensityLabel; % US intensity (low, medium, high) (isession, istim)

% collect data (responses around stimulus)
if ~par.merge_groups
    dat= stim.traces.(par.stim).meanTrialResponse; % mouse, resp, trial
else % concatenate mice from groups
    dat1= stim(1).traces.(par.stim).meanTrialResponse; % mouse, resp, trial
    dat2= stim(2).traces.(par.stim).meanTrialResponse; % mouse, resp, trial
    for isession= 1:length(dat1)
        dat{isession}= cat(1,dat1{isession},dat2{isession});
    end
    % merge mouse numbers
    stim(1).mice= 1:(stim(1).mice(end) + stim(2).mice(end));
end
dat(cellfun(@isempty,dat))=[]; % remove empty sessions

% restrict mice
if ~isempty(par.mice)
     stim(1).mice= par.mice;
end



figure('position',[10 10,1900,900])
clear mm ss mmMax ssMax respIdsCat
flag_empty=[];

for isession= 1:length(sessions)
    clear respAuc
    % get "stimulus-responsive" cells inds: responsive to at least 'par.minRespTrials' of 10 trials
    respIds= find(sum(stim(1).traces.(par.stim).RespTrialsIds{sessions(isession)},2)  >=  par.minRespTrials);

    % get number of cell in session
    if par.globalCellsIds
        ncell= stim(1).session.globIdsSum;
    else
        ncell= stim(1).session.ncell(sessions(isession));
    end

    %% include only CS_US cells
    if par.CS_US_cells_only
        if istim==1 && isession==2  ||  istim==2 && isession==1
            respIds= stim(1).session.cond.CS_US;
        elseif  istim==1 && isession==3  || istim==2 && isession==2
            respIds= stim(1).session.condvar.CS_US;
        else
            respIds=[];
        end
    end

    %% exclude CS_US cells
    if par.CS_US_cells_excluded
        if istim==1 && isession==2  ||  istim==2 && isession==1
            del= intersect(stim(1).session.cond.CS_US,respIds);
            respIds(ismember(respIds,del))=[];
        elseif istim==1 && isession==3  || istim==2 && isession==2
            del= intersect(stim(1).session.condvar.CS_US,respIds);
            respIds(ismember(respIds,del))=[];
        end
    end

    %% restrict data to specific trials
    if isempty(par.trial)
        trials= 1:size(dat{isession},3);
    else
        trials= par.trial;
    end
    if par.CS_trials_only && isession==2
        trials= find(stim.session.fullcond.CS_trials_only)';
    end

    %% collect only responses of stimulus-responsive cells accross trials
    for itrial= trials
        % get data
        resp= dat{isession}(:,:,itrial);
        inclIds= 1:size(resp,1);
        twinresp= stim(1).traces.(par.stims{istim}).twin_resp;


        if ~contains(par.stim,'motion')
            if par.thres_topNbTrials > 0 || par.thres_topRespPerTrial >0 || par.TotalRespPerTrial
                if par.thres_topRespPerTrial > 0
                    % sort cells according to the maximally responsive trials
                    [~,ids]= sort(trapz(dat{isession}(:,twinresp,itrial),2),'descend');
                    % select top % cells Ids with most responsive trials
                    sortIds= ids(1:ceil(ncell*par.thres_topRespPerTrial/100));
                elseif par.thres_topNbTrials > 0
                    % define top responsive cells the number of responsive trials over session
                    [~,ids]= sort(sum(stim(1).traces.(par.stim).RespTrialsIds{sessions(isession)},2),'descend');
                    % take top % cells Ids with most responsive trials
                    sortIds= ids(1:ceil(ncell*par.thres_topNbTrials/100));
                elseif par.TotalRespPerTrial
                    sortIds= find(stim(1).traces.(par.stim).RespTrialsIds{sessions(isession)}(:,itrial));
                end

                % other cases
                if  ~par.high_fidelity_cells && ~par.CS_US_cells_only % restrict to max % responsive cells (sortIds)
                    inclIds= sortIds;
                elseif par.high_fidelity_cells || par.CS_US_cells_only % include cells according to sortID AND respID
                    inclIds= intersect(sortIds,respIds);
                    inclIds= unique([sortIds ; respIds]);
                end
            end

            if par.high_fidelity_cells || par.CS_US_cells_only % restrict to responsive cells (response > ntrial)
                % include cells according to respID (responsive cells in more thatn thresh number of trials, defined in get_data.m)
                inclIds= respIds; % defined for whole session
            end
        end


        % average cells response per mouse
        if par.per_mouse && ~contains(par.stim,'motion')
            for imouse= stim(1).mice
                mouseIds= stim(1).session.cellIds{istim,imouse,stim(1).session.(par.stim)(isession)}; % all cell id for the mouse
                mouseIds= mouseIds(ismember(mouseIds,inclIds));
                if par.TotalRespPerTrial
                    respimm(imouse,:)= sum(resp(mouseIds,:)); % average mouse response
                else
                    respimm(imouse,:)= nanmean(resp(mouseIds,:)); % average mouse response
                end
                mouseIDs(imouse)= length(mouseIds);
            end
            resp= respimm;
        else
            resp= resp(inclIds,:); % go to put that here to keep resp intact
        end




        if ~isempty(resp)
            if par.filt(istim)>0
                try
                    % filter the non-nan coolumns (can be mice thwhere no  cell qualifies)
                    respf= resp(all(~isnan(resp),2),:);
                    respf= filtfilt(filtering,1,respf')'; % smoothen response
                    resp(all(~isnan(resp),2),:)=respf;
                catch
                    error('stop')
                end
            end

            if par.acceleration
                resp= padarray(diff(resp'),1,'pre')'; % diff for acceletation and pad with 0
            end


            if contains(par.stim,'motion') && par.acceleration % acceleration instead of motion i.e diff(motion)
                [respmm, respss]= mmss(resp'); % mean and SEM accoss cells / mouse
            elseif par.TotalRespPerTrial
                respmm= sum(resp);
            else
                [respmm, respss]= mmss(resp'); % mean and SEM accoss cells / mouse
            end

            % baseline mean response
            if ~contains(par.stim,'motion')
                respmm= respmm - nanmean(respmm(1:par.baseline(istim)*stim(1).fr));
                % exception
                if par.TotalRespPerTrial
                    respss= zeros(1,length(respmm));
                else
                    respss= respss - nanmean(respmm(1:par.baseline(istim)*stim(1).fr));
                end
            end

            % this is for plot average per trial or mouse later
            if par.per_mouse
                if contains(par.stim,'motion')
                    respmmCAt(:,isession,itrial,:)= resp; % mouse, session, trial, resp
                else
                    respmmCAt(:,isession,itrial,:)= respimm; % mouse, session, trial, resp
                end
            else
                respmmCAt(isession,itrial,:)= respmm; % session, trial, resp
            end







            %% plot traces
            subplot(2,4,isession) % plot single trial
            SD_shadedErrorBar(t,respmm, respss,{'-','color',par.cols{istim}(itrial+5,:), 'linewidth',1.5}, 1, 0.05); hold on;

            yl(isession,:)= get(gca,'ylim'); % get ylim
            if par.per_mouse && ~contains(par.stim,'motion')
                PcRespCell= round(100*sum(mouseIDs) / size(dat{isession},1),1); % get percent of responsive cells
            else
                PcRespCell= round(100*size(resp,1) / size(dat{isession},1),1); % get percent of responsive cells
            end
            title([session_labels{isession} ' ' num2str(PcRespCell) ' percent stimulus-responsive cells'],'interpreter','none');

            if par.per_mouse
                % collect mean response AUC over mice
                if contains(par.stim,'motion') && par.max
                    respAuci(isession,:,itrial)= max(squeeze(resp(:,stim(1).traces.(par.stim).twin_resp)),[],2)'; % get max per trial
                else
                    respAuci(isession,:,itrial)= trapz(squeeze(resp(:,stim(1).traces.(par.stim).twin_resp)),2); % get AUC response per trial
                end
                if itrial== trials(end)
                    for imouse= stim(1).mice
                        [mmmouse(isession,imouse), ssmouse(isession,imouse)]= mmss(respAuci(isession,imouse,:)); % mean and SEM AUC accoss trials
                    end
                end
            else
                mmmouse=[]; ssmouse=[];
            end

            % collect mean response over trials
            respAuc= trapz(squeeze(resp(:,stim(1).traces.(par.stim).twin_resp)),2); % get AUC response per trial
            if par.TotalRespPerTrial
                mm(isession,itrial)= sum(respAuc); % sum AUC accoss cells
                ss(isession,itrial)= 0;
            else
                [mm(isession,itrial), ss(isession,itrial)]= mmss(respAuc'); % mean and SEM AUC accoss cells
            end

            % for motion
            if par.time_to_max % use time to max instead of AUC
                [~,maxTime]= find(resp==max(resp(:,stim(1).traces.(par.stim).twin_resp),[],2)); % get maximum response frame %%%%%%%%%%
                maxTime= maxTime-stim(1).traces.(par.stim).twin_resp(1); % subtract number of baseline frames
                maxTime= maxTime./stim(1).fr; % convert frame to seconds
                [mmMax(isession,itrial), ssMax(isession,itrial)]= mmss(maxTime); % mean and SEM max response time accoss cells

            elseif par.max && ~par.time_to_max % use max instead of AUC
                [mm(isession,itrial), ss(isession,itrial)]= mmss(max(resp(:,stim(1).traces.(par.stim).twin_resp),[],2));
            end
        end
    end

    SD_figure_appearance;
    if ~isempty(resp)

        %% plot AUC (or max acceleration)
        subplot(2,4,length(dat) + isession +1)
        if par.time_to_max % consider time (frame) of maximum response
            mm= mmMax; ss= ssMax;
        end
        mm(mm==0)=nan;
        if ~par.TotalRespPerTrial
            ss(ss==0)=nan;  % remove empty session
        end

%         if isession==2
%             error('stop')
%         end
        b= bar(mm(isession,~isnan(mm(isession,:)))); hold on % AUC bar plot
        e= errorbar(mm(isession,(~isnan(mm(isession,:)))), ss(isession,~isnan(ss(isession,:))), '.','color','k'); % add error bar
        e.YNegativeDelta=[]; % remove negative error bar
        % appearance: bar color
        if isempty(par.trial) % otherwise complicated
            b.FaceColor= 'flat';
            b.CData= par.cols{istim}(1:length(trials),:); % add colors
        end
        SD_figure_appearance;
        xticks(1:length(mm(~isnan(mm(isession,:)))));
        if (strcmp(par.stim,'US') ||  strcmp(par.stim,'motion_US')) && isempty(par.UStrial_compare{1}) 
            try xticklabels(USintensityLabel(isession,:)'); end
        end
    else
        flag_empty= isession;
    end
end

%% Appearance
% homogenize ylimits
for isession= 1:length(sessions)
    % traces
    subplot(2,4,isession);
    ylim([min(yl(:)) max(yl(:))]);
    % add stimulus patch
%     twin= stim(1).twin{istim}(1)* stim(1).fr : stim(1).twin{istim}(end)* stim(1).fr;
    stim_win= 0:stim(1).stim_duration(istim)* stim(1).fr;
    xrext= [stim_win(1) stim_win(end) stim_win(end) stim_win(1)]./stim(1).fr;
    yrect= [min(yl(:)) min(yl(:)) max(yl(:)) max(yl(:))];
    patch(xrext,yrect,'k','EdgeColor','none','FaceAlpha',0.03);
    % add stimulus start line
    line( [0 0], [ min(yl(:)) max(yl(:))], 'color',0.65*[1 1 1])
    % AUC
    subplot(2,4,length(dat) + isession +1);
    ylim([0 max(mm(:) + max(ss(:)))]);
end

% axis labels
subplot(2,4,1); ylabel('Calcium activity (z-score)'); % ylabel
subplot(2,4,2); xlabel('Time from stimulus onset (sec)'); % xlabel
subplot(2,4,length(dat)+2); ylabel('Calcium activity (z-score integral)'); % ylabel
subplot(2,4,length(dat)+3);
if strcmp(par.stim,'CS')
    xlabel('CS trial number'); % xlabel
elseif strcmp(par.stim,'US')
    xlabel('US intensity per trial') % xlabel
elseif contains(par.stim,'motion')
    if par.acceleration
        subplot(2,4,1); ylabel('Acceleration (cm/s^2)'); % ylabel
        subplot(2,4,length(dat)+2)
        if par.max
            ylabel('Max. acceleration (cm/s^2)'); % ylabel
        else
            ylabel('Acceleration (cm/s^2)'); % ylabel
        end
    else
        subplot(2,4,1); ylabel('Motion (cm/s)'); % ylabel
        subplot(2,4,length(dat)+2); ylabel('Motion (cm/s integral)'); % ylabel
        if par.max
            ylabel('Max. velocity (cm/s)'); % ylabel
        else
            ylabel('Velocity (cm/s)'); % ylabel
        end
    end
    if par.time_to_max
        ylabel('Latency to max (s)'); % ylabel
    end
end

% remove empty trials
if par.per_mouse && ~isempty(par.trial)
    respmmCAt= respmmCAt(:,:,par.trial,:);
end

% remove zeros (different trial lengths)
respmmCAt(respmmCAt==0)=nan;


%% Plot response average over trials
subplot(2,4,length(dat)+1)
% remove empty session
if ~isempty(flag_empty) && ~par.per_mouse
    sess= sessions(sessions~=sessions(flag_empty));
    try
        respmmCAt(:,flag_empty,:)=[];
    end
else
    sess= sessions;
end


if ~isempty(par.session_compare) % restrict to a couple of sessions
    sess= par.session_compare;
end

if par.per_mouse && isempty(par.per_US_intensity) % average trials
    respmmCAt= squeeze(nanmean(respmmCAt,3)); % session, mouse, trial, response
end

if ~isempty(par.per_US_intensity) % split per intensity
    ntrial_compare= length(par.per_US_intensity);
elseif ~isempty(par.UStrial_compare{1})
    ntrial_compare= sum(~cellfun(@isempty, par.UStrial_compare));
else
    ntrial_compare= 1;
end


% average over trials for each session
for isession= 1:length(sess)
    session= find(ismember(sessions,sess(isession)));

    for itrial_compare= 1:ntrial_compare
        % define trials to consider
        if ~isempty(par.trial) % average over trials
            trials= par.trial;
        else
            trials= 1:size(respmmCAt,2);
        end
        if ~isempty(par.per_US_intensity)
            trials= find(contains(USintensityLabel(session,:), par.per_US_intensity(itrial_compare)));
        elseif ~isempty(par.UStrial_compare{1})
            trials= find(ismember(stim.session.fullcond.US_trials_cat,par.UStrial_compare{itrial_compare}));
        end

        if par.per_mouse
            if isempty(par.per_US_intensity) % average over mice
                if length(sess)==1
                    [respMM, respSS]= mmss(respmmCAt'); % trials already averaged
                else
                    [respMM, respSS]= mmss(squeeze(respmmCAt(:,session,:))'); % trials already averaged
                end
            else
                temp= squeeze(nanmean(respmmCAt(:,:,trials,:),3)); % average over intensity trials
                [respMM, respSS]= mmss(squeeze(temp(:,session,:))'); % average over mice (SEM over mice)
            end

            if par.filt>0
                respMM= filtfilt(filtering,1,respMM); % smoothen
                respSS= filtfilt(filtering,1,respSS); % smoothen
            end
        else
            [respMM, respSS]= mmss(squeeze(respmmCAt(session,trials,:))');
        end

        % baseline
        if ~contains(par.stim,'motion')
            respMM= respMM - nanmean(respMM(1:par.baseline(istim)*stim(1).fr));
            respSS= respSS - nanmean(respMM(1:par.baseline(istim)*stim(1).fr));
        end

        % line color
        col= stim(1).session.sessioncols{sess(isession)}; % session color

        % plot
        if ~isempty(par.per_US_intensity) || ~isempty(par.UStrial_compare{1})
            SD_shadedErrorBar(t,respMM,respSS,{'-','color',col,'linewidth',1*itrial_compare},1,0.075*itrial_compare);
        else
            SD_shadedErrorBar(t,respMM,respSS,{'-','color',col,'linewidth',2},1,0.15);
        end

        hold on;
        SD_figure_appearance, box off
        if~isempty(par.ylim_plot)
            ylim(par.ylim_plot)
        end
        yl= get(gca,'ylim');
    end
end

% stimulus patch
yrect= [yl(1) yl(1) yl(2) yl(2)];
patch(xrext,yrect,'k','EdgeColor','none','FaceAlpha',0.03);
% add stimulus start line
line( [0 0], [yl(1) yl(2)], 'color',0.65*[1 1 1])

if par.per_mouse
    title('mean per session, per mouse');
else
    title('mean per session');
end

%% Box plot compare sessions AUC
subplot(2,4,2*(length(dat)+1))

% use time to maximum instead of AUC
if par.time_to_max
    mm= mmMax;
    ss= ssMax;
    % remove empty trials
    mm(:,sum(mm)==0)=[];
    ss(:,sum(ss)==0)=[];
end

% remove empty session
if ~isempty(flag_empty) && ~par.per_mouse
    try
        mm(flag_empty,:)=[];
        ss(flag_empty,:)=[];
    end
end

if ~isempty(mmmouse) % for per_mouse
    if isempty(par.per_US_intensity)
        mm= mmmouse;
        ss= ssmouse; % isession,imouse  AUC
    else
        mm= respAuci; % isession,imouse,itrial  AUC
    end
end

% if ~isempty(par.UStrial_compare{1})
%     mm= mm(:,trials);
% end

dims= size(mm);


clear dat cols
if (~isempty(par.per_US_intensity) || ~isempty(par.UStrial_compare{1})) && length(par.session_compare)<2 % compare trial types
    session= find(ismember(sessions,sess));
    for itrial_compare= 1:ntrial_compare
        if ~isempty(par.per_US_intensity)
            if par.per_mouse
                dat{itrial_compare}= nanmean(mm(session,:,contains(USintensityLabel(session,:),par.per_US_intensity(itrial_compare))),3); % average intensity trials
            else
                dat{itrial_compare}= mm(session, contains(USintensityLabel(session,:), par.per_US_intensity(itrial_compare)));
            end
        elseif ~isempty(par.UStrial_compare{1})
            dat{itrial_compare}= mm(session, ismember(stim.session.fullcond.US_trials_cat,par.UStrial_compare{itrial_compare}));

        end
        cols{itrial_compare}= par.cols{2}(itrial_compare*4+4,:); % intensity color
    end

elseif ~isempty(par.per_US_intensity) && length(par.session_compare)>=1 % compare US intensities and sessions
    session= find(ismember(sessions,par.session_compare));
    for isession= 1:length(par.session_compare)
        for itrial_compare= 1:ntrial_compare
            if par.per_mouse
                dat{isession,itrial_compare}= nanmean(mm(session(isession),:,contains(USintensityLabel(session(isession),:), par.per_US_intensity(itrial_compare))),3); % average trials
            else
                dat{isession,itrial_compare}= mm(session(isession), contains(USintensityLabel(session(isession),:), par.per_US_intensity(itrial_compare))); % select trials
            end
            cols(isession,itrial_compare)= stim(1).session.sessioncols(sess(isession)); % intensity color
        end
    end
    dat= reshape(dat,1,ntrial_compare*length(par.session_compare));
    cols= reshape(cols,1,ntrial_compare*length(par.session_compare));

else % compare sessions
    dat= mat2cell(mm,ones(1,dims(1)),dims(2))';
    if par.session_compare % restrict to a couple of sessions
        dat= dat(ismember(sessions,sess));
    end
    cols= stim(1).session.sessioncols(sess); % session color
end

% remove nans
for idat= 1:length(dat)
    dat{idat}= dat{idat}(~isnan(dat{idat}));
end

% plot
yl= boxplots(dat,'mean','scatter','color',cols);
% xticklabels
if ~isempty(par.per_US_intensity)
    if  length(par.session_compare)<2
        set(gca,'xticklabels',(par.per_US_intensity)); 
      
    else
        intlab= par.per_US_intensity; sesslab= stim(1).session.session_labels(sess);
        xticklabels({[intlab{1} ' ' sesslab{1}], [intlab{1} ' ' sesslab{2}], [intlab{2} ' ' sesslab{1}], [intlab{2} ' ' sesslab{2}]} ); % intensity and session, hardcoded
    end
elseif ~isempty(par.UStrial_compare{1})
    for itrial_compare= 1:ntrial_compare
        xticklabels(itrial_compare)= {['trial ' num2str(par.UStrial_compare{itrial_compare})]};
    end
    set(gca,'xticklabels',xticklabels)
else
    set(gca,'xticklabels',(stim(1).session.session_labels(sess))); % session
end
ylabel('Mean over trials');
SD_figure_appearance
% set ylim
if ~strcmp(par.stim,'motion_CS') && ~strcmp(par.stim,'freezing')
    ylim([0 yl(2)])
end
if ~isempty(par.ylim_whisker)
    ylim([par.ylim_whisker]) 
end

% statistics
if length(dat)>2
    [str,~,p,~,means,~,mm_ss_string]= SD_anovan(dat,'BC');
elseif length(dat)==2
    [full_str,p,~,mm_ss_string,~,~,~] = SD_ttest(dat{1},dat{2});
    str= full_str{2};
end

% name
clear name;
if par.per_mouse
    name{1}= 'mean per session, per mouse';
else
    name{1}= 'mean per session';
end
if ~isempty(par.trial)
    name{1}= [name{1} ' ' num2str(par.trial)];
end
if length(dat)>=2
    name{2}= str;
    name{3}= ['P= ' num2str(round(p,3))];
    name{4}= mm_ss_string;
end
title(name(2:end),'fontsize',8);

%% whole figure title
NAME{1}= [stim(1).groupName ' ' par.stim '-responsive cells response'];
if isempty(par.per_US_intensity)
    NAME{1}= [NAME{1} ' per trial'];
else
    NAME{1}= [NAME{1} ' per US intensity'];
end
if par.acceleration && contains(par.stim, 'motion')
    NAME{1}= [NAME{1} ' acceleration'];
end
if par.time_to_max
    NAME{1}= [NAME{1} ' latency'];
end
if par.session_compare
    NAME{1}= [NAME{1} ' session ' num2str(par.session_compare)];
end



NAME{2}= [num2str(round(par.thres_resp(istim),2)) ' zscore within '...
    num2str(stim(1).twin_resp{istim}) ' seconds post-stimulus trial-responsive threshold'];
if par.high_fidelity_cells
    NAME{1}= [NAME{1} num2str(par.minRespTrials) ' or more responsive trials'];
elseif par.thres_topNbTrials > 0
    NAME{1}= [NAME{1} ' top ' num2str(par.thres_topNbTrials) ' percent responsive cells'];
elseif par.thres_topRespPerTrial > 0
    NAME{1}= [NAME{1} ' top ' num2str(par.thres_topRespPerTrial) ' percent responsive cells'];
end
subtitle(NAME);

if par.save % save
    SD_save([name{1} ' ' NAME{1}],par.saveDir);
end

% %% 2 ways ANOVA
% par.saveDir= 'C:\Users\sdaqui\Desktop\New folder'; mkdir(par.saveDir)
% figure
% dat= [dat_veh dat_cno];
% yl= boxplots(dat,'mean');
% ylim([0 yl(2)])
% % appearance
% SD_figure_appearance
% ylabel('velocity integral')
% xticklabels({'veh unexp','veh exp','CNO unexp','CNO exp'})
% % statistics: 2-way ANOVA
% vals2= [[dat_veh{1}, dat_veh{2}] ; [dat_cno{1}, dat_cno{2}]];
% % column = unexp vs exp  row= veh vs CNO  
% p = anova2(vals2',size(vals,2)); close
% clear name; name{1}= 'column = unexp vs exp  row= veh vs CNO';
% name{2}= ['column P= ' num2str(round(p(1),4)) ' row P= ' num2str(round(p(2),4)) ' interaction P= ' num2str(round(p(3),4))];
% title(name)
% % save
% SD_save(name{1}, par.saveDir);
