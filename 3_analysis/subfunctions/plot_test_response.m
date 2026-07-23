function name= plot_test_response(stim,par)

% parameters
istim= find(~cellfun(@isempty, strfind(par.stims,par.session))); % stimulus number
sessions= par.session;
stim.names(strcmp(stim.names,'spont'))= []; % remove spontaneous (no timestamps)

% update figure name
name= {stim.groupName ' mean response per test',...
    '% responsive neurons, % withdrawal',...
    '7 days pre-CCI = Gray, pre-CCI = Black, 7 days post-CCI = red'};

if  par.no_withdrawal==1 % restrict to trials with no paw withdrawal
    name{1}= [name{1} '    no beh reaction'];
elseif  par.no_withdrawal==2 % restrict to trials with paw withdrawal
    name{1}= [name{1} '    beh reaction'];
end

if par.pos_response==1 % restrict to cells with positive response
    name{1}= [name{1} '    neurons with response above baseline'];
elseif  par.pos_response==2 % restrict to cells with negative response
    name{1}= [name{1} '    neurons with response below baseline'];
end

if par.thres_topNbTrials > 0 % restrict to top responsive cells
    name{1}= [name{1} ' ' num2str(par.thres_topNbTrials) ' % most consistently responsive neurons'];
elseif par.thres_topRespPerTest > 0 
    name{1}= [name{1} ' ' num2str(par.thres_topRespPerTest) ' % most strongly responsive neurons'];
end

figure('color','w','position',[10 100 1600 800])

%% plot
for isession= sessions
    for itest= 1:length(stim.names)
        subplot(4,6,itest)

        % get data
        resp= mean(stim.traces.sensoryStim.meanTrialResponse{isession}(:,:,itest,:),4);

        % select cells with positive or negative response
        if par.pos_response==1  % only activated neurons
            incl_ids= find(mean(resp(:,stim.traces.sensoryStim.twin_resp),2) > 0);
            resp= resp(incl_ids,:);
        elseif par.pos_response==2 % only suppressed neurons
            incl_ids= find( mean(resp(:,stim.traces.sensoryStim.twin_resp),2) < 0);
            resp= resp(incl_ids,:);
           
        elseif par.thres_topRespPerTest > 0 
             % cells sorted according to their mean response per test
             sortIds= stim.traces.sensoryStim.sortIds{isession,itest} (1: ceil( stim.session.ncell(isession) * par.thres_topRespPerTest/100));
             resp= resp(sortIds,:);
        elseif par.thres_topNbTrials > 0
            % define top responsive cells the number of responsive trials over session
            [~,ids]= sort(sum(squeeze(stim.traces.sensoryStim.RespTrialsIds{isession}(:,itest,:)),2),'descend');
            % take top % cells Ids with most responsive trials
            sortIds= ids(1:ceil(length(ids)*par.thres_topNbTrials/100));
            resp= resp(sortIds,:);
        end




        if ~isempty(resp) && size(resp,2)>1
            [mm,ss]= mmss(resp');
            SD_shadedErrorBar(stim.sensoryStim.twinp./stim.fr,mm,ss,{'-','color', stim.session.sessioncols{isession}},'transparent', 0.2); hold on
            yl(:,:,itest,isession)=get(gca,'Ylim'); % get yl
        elseif ~isempty(resp) && size(resp,2)==1  % only one neuron
            plot(resp);
            yl(:,:,itest,isession)=get(gca,'Ylim'); % get yl
        else
            yl(:,:,itest,isession)=nan;
        end
        box off
        title(stim.names{itest})
    end
end

% adjust ylim to all subplots
for isession= sessions
    for itest= 1:length(stim.names)
        subplot(4,6,itest);
        ylim([min(yl(:)) max(yl(:))])
        % percent withdrawal
        text((stim.sensoryStim.twinp(end)/stim.fr)-0.2, max(yl(:))/find(isession==sessions),...
            [num2str(round(mean(stim.sensoryStim.withdrawal{isession}(:,itest),1))) ' %w '], 'color', stim.session.sessioncols{isession})
        % percent responsive neurons
        respcellsNum= cellfun(@length, stim.traces.sensoryStim.respCellIds);
        respcellsPC= respcellsNum(isession,itest)./stim.session.ncell(isession)*100;
        text((stim.sensoryStim.twinp(1)/stim.fr)+0.2, max(yl(:))/find(isession==sessions),...
            [num2str(round(respcellsPC,1)) ' %res '], 'color', stim.session.sessioncols{isession})
    end
end
sgtitle(name,'interpreter','none')
sglabels('Time (s) around stimulus','Calcium intensity (z-score)')
% par.save
if par.save
    SD_save(name{1},par.saveDir);
end

