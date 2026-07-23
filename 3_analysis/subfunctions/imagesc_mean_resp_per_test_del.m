function imagesc_mean_resp_per_test(data,stim,par)

% parameters
istim= find(strcmp(par.stims,par.stim)); % stimulus number
sessions= stim.session.(par.stim);
sessions(sessions> size(data,2))=[]; % in case no session 6 for example
% get data
dat= stim.(par.datFields).(par.stim).meanTrialResponse;


% make figure
if isequal(sessions,stim.session.CS) || isequal(sessions,stim.session.US)
    figure('color','w','position',[10 100 1600 800])
end

% average trials per session (last dimension)
for isession= sessions
    dims= size(dat{isession});
    if length(dims)==3 && isequal(sessions, stim.session.CS) || isequal(sessions, stim.session.US) || strcmp(par.stims{istim},'loco')
        dat{isession}= mean(dat{isession}(:,:,1:dims(end)),length(dims));  % limit to set number of trials: replace par.trials{istim} with 1:dims(end) 
    elseif  length(dims)==4 && sum(ismember(sessions, stim.session.sensoryStim))> 0
        dat{isession}= mean(dat{isession}(:,:,:,1:dims(end)),length(dims)); % limit to set number of trials: replace par.trials{istim} with 1:dims(end) 
    end
end


for isession= sessions
    % sort (rearrange session data for plot according to sortIds)
    if ~isempty(stim.(par.datFields).(par.stim).sortIds)
        if ismember(isession,stim.session.sensoryStim)
            for itest= 1:size(dat{isession},3)
                sortIds= stim.(par.datFields).(par.stim).sortIds{isession,itest};
                dat{isession}(:,:,itest)= dat{isession}(sortIds,:,itest);
            end
        else
            if par.sort_session % sort according to a particular session
                sortIds= stim.(par.datFields).(par.stim).sortIds{par.sort_session};
            else
                sortIds= stim.(par.datFields).(par.stim).sortIds{isession};
            end
            dat{isession}= dat{isession}(sortIds,:,:);
        end
    end

    % plot name
    if ismember(isession,stim.session.conditioning)
        name= {[stim.groupName ' ' par.stim ' mean response per session,   sessions ' num2str(sessions)],...
            [num2str(size(data,1)) ' mice, mean per trial, twin =' num2str(stim.twin{istim}) ' sec around stimulus'],...
            [' % responsive neurons over ' num2str(stim.twin_resp{istim}),'s post-stimulus onset'],' '};
    elseif ismember(isession,stim.session.sensoryStim)
        name= {[stim.groupName ' ' par.stim ' mean response per test,   session ' num2str(isession)],...
            [' mice ' num2str(size(data,1)) ' mean per trial, twin =' num2str(stim.twin{istim}) ' sec around stimulus'],...
            ['% withdrawal, % responsive neurons over ' num2str(stim.twin_resp{istim}),'s post-stimulus onset'],' '};
        if  par.no_withdrawal
            name{1}= [name{1} '    no withrawal'];
        else
            name{1}= [name{1} '    withrawal'];
        end
    end

    if par.globalCellsIds && istim <4
        name{1}= ['global cells ' name{1}];
    end

    if par.sort_session
         name{1}= [name{1} ' sorted to session ' num2str(par.sort_session)];
    end 

    stim.names(strcmp(stim.names,'spont'))=[]; % remove spontaneous (no timestamps)


    %% only CS_US cells
    if par.CS_US_cells_only
        if istim==1 && isession==2 || istim==2 && isession==2
            dat{isession}= dat{isession}(stim.session.cond.CS_US,:);
        elseif istim==1 && isession==3  || istim==2 && isession==3
            dat{isession}= dat{isession}(stim.session.condvar.CS_US,:);
        end
    end

    %% exclude CS_US cells
    if par.CS_US_cells_excluded
        if istim==1 && isession==2 || istim==2 && isession==2
            [~,delIds]= ismember(stim.session.cond.CS_US,delIds);
            dat{isession}(delIds,:)=[];
        elseif istim==1 && isession==3  || istim==2 && isession==3
            [~,delIds]= ismember(stim.session.condvar.CS_US,delIds);
            dat{isession}(delIds,:)=[];
        end
    end


    %% reshape for plot
    dims= size(dat{isession});
    % pad data to plot sessions with different numbers of cells together
    if ismember(isession,stim.session.conditioning)
        % get max number of cells per session
        if par.globalCellsIds && istim <4
            ncell= stim.session.globIdsSum;
        else
            ncell= stim.session.ncell(sessions);
            % pad sessions with less cells to get same number of cells in each session
            for isession= 1:length(sessions)
                if ncell(isession) < max(ncell)
                    dat{sessions(isession)}(ncell(isession)+1:max(ncell),:)= 0; % pad with zero
                end
            end
        end

        mmcatp= cat(2,dat{:}); % concatenate sessions
    elseif ismember(isession,stim.session.sensoryStim)
        mmcatp= reshape(dat{isession},[dims(1) dims(2)*dims(3)]); % concatenate tests
    end
    dims= size(mmcatp);


    %% plot
    % figure
    if ~isequal(sessions,stim.session.CS) && ~isequal(sessions,stim.session.US)
        figure('color','w','position',[10 100 1600 800])
    end
    imagesc(mmcatp);
    % appearance
    colormap(redblue);
    % color axis
    if strcmp(par.datFields,'traces')
        caxis([-par.caxis(istim) par.caxis(istim)])
    elseif strcmp(par.datFields,'spikes')
        caxis([-0.1 0.1])
    end

    set(gca,'TickLength',[0 0])
    set(gca,'xTick',[]);
    yl= get(gca,'ylim');

    % add line between sessions and stimulus start
    if ismember(isession,stim.session.conditioning)
        % line between tests
        ts_bet= 1:length(stim.(par.stim).twinp):length(stim.(par.stim).twinp)*length(sessions);
        line([ts_bet'  ts_bet'], yl ,'color', 0.5*[1 1 1]);
        % line stimulus start
        ts_st= 1+abs(stim.twin{istim}(1)*stim.fr):length(stim.(par.stim).twinp):length(stim.(par.stim).twinp)*length(sessions);
        line([ts_st'  ts_st'], yl ,'color', 'k','linewidth',1);
    elseif ismember(isession,stim.session.sensoryStim)
        % line between tests
        ts_bet= 1:length(stim.(par.stim).twinp):dims(2);
        line([ts_bet'  ts_bet'], yl ,'color', 0.5*[1 1 1]);
        % line stimulus start
        ts_st= 1+abs(stim.twin{istim}(1)*stim.fr):length(stim.(par.stim).twinp):dims(2);
        line([ts_st'  ts_st'], yl ,'color', 'k','linewidth',1.5);
    end

    % add session name and percent responsive neurons
    if ismember(isession,stim.session.conditioning)
        % session names
        text(ts_bet+10, repmat(yl(2)+yl(2)/40,[1 length(ts_bet)]) , stim.session.session_labels(sessions) ,'fontsize',10, 'fontweight', 'bold')
        % percent responsive neurons
        respcellsIds= stim.traces.(par.stim).respCellIds; respcellsIds(cellfun(@isempty,respcellsIds))=[];
        if ~par.globalCellsIds % because ncell is not done well, otherwise would work 
        PcResp= (cellfun(@length, respcellsIds)./stim.session.ncell(sessions)')*100; % get pc resp neurons into matrix
        text(ts_bet+10, repmat(yl(2)+yl(2)/10,[1 length(ts_bet)]), num2cell(round(PcResp,1)) ,'fontsize',10, 'fontweight', 'bold')
        end
    elseif ismember(isession,stim.session.sensoryStim)
        % test names
        text(ts_bet+10, repmat(yl(2)+yl(2)/40,[1 length(ts_bet)]), stim.names ,'fontsize',10, 'fontweight', 'bold')
        % withdrawal rate
        text(ts_bet+10, repmat(yl(2)+yl(2)/20,[1 length(ts_bet)]), num2cell(round(nanmean(stim.(par.stim).withdrawal{isession},1))) ,'fontsize',10, 'fontweight', 'bold')
        % percent responsive neurons
        respcellsNum= cellfun(@length, stim.traces.sensoryStim.respCellIds);
        respcellsPC= respcellsNum(isession,:)./stim.session.ncell(isession)*100;
        text(ts_bet+10, repmat(yl(2)+yl(2)/12,[1 length(ts_bet)]),  num2cell(round(respcellsPC,1))  ,'fontsize',10, 'fontweight', 'bold')
        if isession==6
            % percent responsive neurons
            respcellsPC2= respcellsNum(isession-1,:)./stim.session.ncell(isession-1)*100;
            respcellsPCchange= (respcellsPC-respcellsPC2);
            text(ts_bet+10, repmat(yl(2)+yl(2)/9,[1 length(ts_bet)]),  num2cell(round(respcellsPCchange,1))  ,'fontsize',10, 'fontweight', 'bold')
        end

        % test numbers
        text(ts_st, repmat(yl(1)-3,[1 length(ts_bet)]) , num2cell(1:length(ts_bet)),'fontsize',10, 'fontweight', 'bold')
    end

    % title
    title(name,'interpreter','none')
    ylabel('neuron #','fontsize',12,'fontweight', 'bold')
    h = colorbar; ylabel(h, 'z-score','fontsize', 12)

    if par.save
        SD_save(name{1},par.saveDir);
    end
end
