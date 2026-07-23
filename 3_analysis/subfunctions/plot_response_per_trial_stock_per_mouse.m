function  [dat,means]= plot_response_per_trial(stim,par)

% parameters
istim= find(strcmp(par.stims,par.stim)); % stimulus number
sessions= stim(1).session.(par.stim);
filtering= hanning(par.filt(istim))./sum(hanning(par.filt(istim))); % low-pass filtering
t= stim(1).(par.stim).twinp/stim(1).fr;
session_labels= stim(1).session.session_labels(sessions); % get session names
USintensityLabel= stim(1).session.USintensityLabel; % US intensity (low, medium, high)

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

figure('position',[10 10,1900,900])
clear mm ss mmMax ssMax respIdsCat
flag_empty=[];

for isession= 1:length(sessions)
    clear respAuc
    % get "stimulus-responsive" cells inds: responsive to at least 'par.minRespTrials' of 10 trials
    respIds= find(sum(stim(1).traces.(par.stim).RespTrialsIds{sessions(isession)},2)  >=  par.minRespTrials(istim) );

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

    %% collect only responses of stimulus-responsive cells accross trials
    for itrial= trials
        % get data
        resp= dat{isession}(:,:,itrial);
        inclIds= 1:size(resp,1);
        twinresp= stim(1).traces.(par.stims{istim}).twin_resp;


        if  ~contains(par.stim,'motion')
            if par.thres_topNbTrials> 0 || par.thres_topRespPerTrial> 0
                if par.thres_topRespPerTrial > 0
                    % define top responsive cells by integral response during trial
                    [~,ids]= sort(trapz( dat{isession} (:,twinresp,itrial) ,2),'descend');
                    % take top % cells Ids with most responsive trials
                    sortIds= ids(1:ceil(ncell*par.thres_topRespPerTrial/100));
                elseif par.thres_topNbTrials > 0
                    % define top responsive cells the number of responsive trials over session
                    [~,ids]= sort(sum(stim(1).traces.(par.stim).RespTrialsIds{sessions(isession)},2),'descend');
                    % take top % cells Ids with most responsive trials
                    sortIds= ids(1:ceil(ncell*par.thres_topNbTrials/100));
                end
                sortIds= ids;

                % other cases (default)
                if  ~par.thres_minRespTrials && ~par.CS_US_cells_only % restrict to max % responsive cells (sortIds)
                    inclIds= sortIds;
                elseif par.thres_minRespTrials || par.CS_US_cells_only % include cells according to sortID AND respID
                    inclIds= intersect(sortIds,respIds);
                    inclIds= unique([sortIds ; respIds]);
                end
            end

            if par.thres_minRespTrials || par.CS_US_cells_only % restrict to responsive cells (response > ntrial)
                % include cells according to respID (responsive cells in more thatn thresh number of trials, defined in get_data.m)
                inclIds= respIds; % defined for whole session
            end
        end


        % average cell responses per mouse
        if par.per_mouse && ~contains(par.stim,'motion')
            for imouse= stim(1).mice
                mouseIds= stim(1).session.cellIds{istim,imouse,stim(1).session.(par.stim)(isession)}; % all cell id for the mouse
%                 mouseIds= mouseIds(ismember(mouseIds,inclIds)); % del
                 % get position of inclIds in mouseIds
                pos= find(ismember(inclIds,mouseIds));
                % sort positions according to criterium
                % take x% mouseID highest on the sorted list= first position
                if par.thres_topNbTrials > 0
                   mouseIds= inclIds (pos(1:ceil(length(mouseIds)*par.thres_topNbTrials/100)));
                end
                respimm(imouse,:)= mean(resp(mouseIds,:)); % average mouse response
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

            % acceleration instead of motion i.e diff(motion)
            if contains(par.stim,'motion') && par.acceleration
                [respmm, respss]= mmss(resp'); % mean and SEM accoss cells / mouse
            else
                [respmm, respss]= mmss(resp'); % mean and SEM accoss cells / mouse
            end

            % baseline
            if ~contains(par.stim,'motion')
                respmm= respmm-mean(respmm(1:par.baseline(istim)*stim(1).fr));
                respss= respss--mean(respmm(1:par.baseline(istim)*stim(1).fr));
            end

            % this is for later
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
            subplot(2,4,isession)
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
                if contains(par.stim,'motion') && par.acceleration
                    respAuci(isession,:,itrial)= max(squeeze(resp(:,stim(1).traces.(par.stim).twin_resp)),[],2)'; % get max acceleration per trial
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
            [mm(isession,itrial), ss(isession,itrial)]= mmss(respAuc'); % mean and SEM AUC accoss cells
            % use time to max instead of AUC
            if par.time_to_max
                [~,maxTime]=find(resp==max(resp(:,stim(1).traces.(par.stim).twin_resp(1):end),[],2)); % get maximum response frame
                maxTime= maxTime-stim(1).traces.(par.stim).twin_resp(1); % subtract number of baseline frames
                maxTime= maxTime./stim(1).fr; % convert frame to seconds
                [mmMax(isession,itrial), ssMax(isession,itrial)]= mmss(maxTime); % mean and SEM max response time accoss cells
            end
        end
    end


    SD_figure_appearance;
    if ~isempty(resp)

        %% plot AUC or max acceleration
        subplot(2,4,length(dat) + isession +1)
        mm(mm==0)=nan;  ss(ss==0)=nan;  % remove empty session
        b= bar(mm(isession,:)); hold on % AUC bar plot
        e= errorbar(mm(isession,:),ss(isession,:), '.','color','k'); % add error bar
        e.YNegativeDelta=[]; % remove negative error bar
        % appearance: bar color
        if isempty(par.trial) % otherwise complicated
            b.FaceColor= 'flat';
            b.CData= par.cols{istim}((1:size(dat{isession},3))+5,:); % add colors
        end
        SD_figure_appearance;
        xticks(1:length(mm));
        if strcmp(par.stim,'US') ||  strcmp(par.stim,'motion_US')
            xticklabels( USintensityLabel(isession,:));
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
    twin= stim(1).twin{istim}(1)* stim(1).fr : stim(1).twin{istim}(end)* stim(1).fr;
    stim_win= 0:stim(1).stim_duration(istim)* stim(1).fr;
    xrext= [stim_win(1) stim_win(end) stim_win(end) stim_win(1)]./stim(1).fr;
    yrect= [min(yl(:)) min(yl(:)) max(yl(:)) max(yl(:))];
    patch(xrext,yrect,'k','EdgeColor','none','FaceAlpha',0.03);
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
        subplot(2,4,length(dat)+2); ylabel('Max. acceleration (cm/s^2)'); % ylabel
    else
        subplot(2,4,1); ylabel('Motion (cm/s)'); % ylabel
        subplot(2,4,length(dat)+2); ylabel('Motion (cm/s integral)'); % ylabel
    end
end

% remove empty trials
if par.per_mouse && ~isempty(par.trial)
    respmmCAt= respmmCAt(:,:,par.trial,:);
end


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
    respmmCAt= squeeze(mean(respmmCAt,3)); % session, mouse, trial, response
end

if ~isempty(par.per_US_intensity) % split per intensity
    nintensity= length(par.per_US_intensity);
else
    nintensity= 1;
end


% average over trials for each session
for isession= 1:length(sess)
    session= find(ismember(sessions,sess(isession)));

    for iintensity= 1:nintensity
        % define trials to consider
        if ~isempty(par.trial) % average over trials
            trials= par.trial;
        else
            trials= 1:size(respmmCAt,2);
        end
        if ~isempty(par.per_US_intensity)
            trials= find(contains(USintensityLabel(session,:), par.per_US_intensity(iintensity)));
        end

        if par.per_mouse
            if isempty(par.per_US_intensity) % average over mice
                [respMM, respSS]= mmss(squeeze(respmmCAt(:,session,:))'); % trials already averaged
            else
                temp= squeeze(mean(respmmCAt(:,:,trials,:),3)); % average over intensity trials
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
            respMM= respMM-mean(respMM(1:par.baseline(istim)*stim(1).fr));
            respSS= respSS-mean(respMM(1:par.baseline(istim)*stim(1).fr));
        end

        % line color
        col= stim(1).session.sessioncols{sess(isession)}; % session color

        % plot
        if isempty(par.per_US_intensity)
            SD_shadedErrorBar(t,respMM,respSS,{'-','color',col,'linewidth',2},1,0.15);
        else
            SD_shadedErrorBar(t,respMM,respSS,{'-','color',col,'linewidth',1*iintensity},1,0.075*iintensity);
        end

        hold on;
        SD_figure_appearance, box off
        yl= get(gca,'ylim');
    end
end

% stimulus patch
yrect= [yl(1) yl(1) yl(2) yl(2)];
patch(xrext,yrect,'k','EdgeColor','none','FaceAlpha',0.03);

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
        mm= mmmouse; ss= ssmouse; % isession,imouse  AUC
    else
        mm= respAuci; % isession,imouse,itrial  AUC
    end
end

dims= size(mm);


clear dat cols
if ~isempty(par.per_US_intensity) && length(par.session_compare)==1 % compare US intensities
    session= find(ismember(sessions,sess));
    for iintensity= 1:nintensity
        if par.per_mouse
            dat{iintensity}= mean(mm(session,:,contains(USintensityLabel(session,:),par.per_US_intensity(iintensity))),3); % average intensity trials
        else
            dat{iintensity}= mm(session, contains(USintensityLabel(session,:), par.per_US_intensity(iintensity)));
        end
        cols{iintensity}= par.cols{2}(iintensity*4+4,:); % intensity color
    end


elseif ~isempty(par.per_US_intensity) && length(par.session_compare)>=1 % compare US intensities and sessions
    session= find(ismember(sessions,par.session_compare));
    for isession= 1:length(par.session_compare)
        for iintensity= 1:nintensity
             if par.per_mouse
                dat{isession,iintensity}= mean(mm(session(isession),:,contains(USintensityLabel(session(isession),:), par.per_US_intensity(iintensity))),3); % average trials
             else
                dat{isession,iintensity}= mm(session(isession), contains(USintensityLabel(session(isession),:), par.per_US_intensity(iintensity))); % select trials
             end
                cols(isession,iintensity)= stim(1).session.sessioncols(sess(isession)); % intensity color
        end
    end
    dat= reshape(dat,1,nintensity*length(par.session_compare));
    cols= reshape(cols,1,nintensity*length(par.session_compare));

else  % compare sessions
    dat= mat2cell(mm,ones(1,dims(1)),dims(2))';
    if par.session_compare % restrict to a couple of sessions
        dat= dat(ismember(sessions,sess));
    end
    cols= stim(1).session.sessioncols(sess); % session color
end

% plot
yl= boxplots(dat,'mean','line','scatter','color',cols);
% xticklabels
if ~isempty(par.per_US_intensity)
    if  length(par.session_compare)==1
        xticklabels(par.per_US_intensity); % intensity
    else
        intlab= par.per_US_intensity; sesslab= stim(1).session.session_labels(sess);
        xticklabels( {[intlab{1} ' ' sesslab{1}], [intlab{1} ' ' sesslab{2}], [intlab{2} ' ' sesslab{1}], [intlab{2} ' ' sesslab{2}]} );% intensity and session, hardcoded
    end
else
    xticklabels(stim(1).session.session_labels(sess)); % session
end
ylabel('Mean over trials');
SD_figure_appearance
if ~strcmp(par.stim,'motion_CS') && ~strcmp(par.stim,'freezing')
    ylim([0 yl(2)])
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
name{2}= str;
name{3}= ['P= ' num2str(round(p,3))];
name{4}= mm_ss_string;
title(name,'fontsize',12);

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
if par.thres_minRespTrials
    NAME{1}= [NAME{1} num2str(par.minRespTrials(istim)) ' or more responsive trials'];
elseif par.thres_topNbTrials > 0
    NAME{1}= [NAME{1} ' top ' num2str(par.thres_topNbTrials) ' percent responsive cells'];
elseif par.thres_topRespPerTrial > 0
    NAME{1}= [NAME{1} ' top ' num2str(par.thres_topRespPerTrial) ' percent responsive cells'];
end
subtitle(NAME);

if par.save % save
    SD_save([name{1} ' ' NAME{1}],par.saveDir);
end