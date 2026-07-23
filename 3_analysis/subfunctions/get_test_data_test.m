function stim= get_test_data(par,data,stim,folder)

% define stims
if contains(folder.parentDir{1}, 'behavior only')
    stims= find(~par.imagingStim);
else
   stims= 1:length(par.stims);
end



%% average test data per trial
 for istim= stims
     meanTrialResponse={}; witstore={}; resppcCat={}; respidsstore={}; respIdsCat={}; sortIdsCat={}; respi={};  % temporary outputs (to append in struct within function)

for idatfield= 1:length(par.datFields)
   
        sessions= stim.session.(par.stims{istim});
        sessions(sessions> size(data,2))=[]; % in case no session 6 for example
        % parameters
        if contains(par.stims{istim},'motion') && par.high_fr_motion
            twinp= stim.twin{istim}(1)*par.motion_frame_rate: (stim.twin{istim}(2)*par.motion_frame_rate)-1;
            twin_respp{idatfield}= (abs(stim.twin{istim}(1))+stim.twin_resp{istim}(1))*par.motion_frame_rate+1:(abs(stim.twin{istim}(1))+stim.twin_resp{istim}(2))*par.motion_frame_rate;
        else
            twinp= stim.twin{istim}(1)*stim.fr: (stim.twin{istim}(2)*stim.fr)-1;
            twin_respp{idatfield}= (abs(stim.twin{istim}(1))+stim.twin_resp{istim}(1))*stim.fr+1:(abs(stim.twin{istim}(1))+stim.twin_resp{istim}(2))*stim.fr;
%             twin_respp{idatfield}= (abs(stim.twin{istim}(1))+stim.twin_resp{istim}(1))*stim.fr:(abs(stim.twin{istim}(1))+stim.twin_resp{istim}(2))*stim.fr;
        end

        for isession= sessions
            test_order= 1; % by default only one test
            mmcat=[]; clear respids;
            for imouse= stim.mice
                if ~isempty(data(imouse,isession).(par.datFields{idatfield})) || contains(par.stims{istim},'motion')
                    clear mm
                    test=0; % initialize

                    % get data
                    if contains(par.stims{istim},'motion')
                        if par.high_fr_motion
                            dat= data(imouse,isession).motion.rs_motion2; % get resampled motion
                        else
                            dat= data(imouse,isession).motion.rs_motion; % get resampled motion
                        end
                    else
                        dat= data(imouse,isession).(par.datFields{idatfield});
                    end

                    % get timestamps
                    if strcmp(par.stims{istim},'CS') || strcmp(par.stims{istim},'motion_CS') % CS  or motion (motion in response to CS)
                        ts= data(imouse,isession).info.timestamps(1);
                    elseif strcmp(par.stims{istim},'US') || strcmp(par.stims{istim},'motion_US')% US or motion (motion in response to US)
                        ts= data(imouse,isession).info.timestamps(2);
                        ts{1}= ts{1}(:)-1/stim.fr; % remove one frame, missaligned otherwise
                    elseif strcmp(par.stims{istim},'freezing') % freezing
                        ts= {data(imouse,isession).behavior.freezing.startfr / stim.fr};
                        ts_stop= {data(imouse,isession).behavior.freezing.stopfr / stim.fr};
                    elseif strcmp(par.stims{istim},'sensoryStim') % sens tests
                        ts= data(imouse,isession).info.timestamps;
                        test_order= 1:length(stim.names);
                    elseif strcmp(par.stims{istim},'nostim') % no stimulus control
                        % create random timestamps, excluding the very beginning and end for time window
                        nfr= length(data(imouse,isession).(par.datFields{idatfield})); % get number of data frames
%                         ts= randperm(nfr,20); % get 20 random timestamps
                          ts= [1721 2036 2323 7960 7575 8595 6732 6357 12127 5889 8778  5401 6919 6028 2248 2418 315 7082 8060 8301]; % same random values every time
                        exclTrange= round(nfr/10); % timerange to exclude (10% at begining end of recording)
                        ts(ts< exclTrange)=[]; ts(ts> (nfr- exclTrange))=[]; % remove timestaps outside of range
                        ts = {ts(1:10)/ stim.fr};
                   elseif strcmp(par.stims{istim},'loco')
                       ts= {round(data(imouse,isession).motion.ts(:)/stim.fr)};
                    end

                    for itest= test_order
                        if ~isempty(ts{itest})
                            test= test+1;
                            % define trials to include
                            if ismember(isession,stim.session.conditioning)
                                trials_selec= par.trials{istim};
                                if strcmp(par.stims{istim},'freezing')
                                    trials_selec= 1:length(data(imouse,isession).behavior.freezing.startfr);
                                    % reduce number of selected freezing episodes:
                                    delInds1= find(ts{:} + twinp(end) > size(dat,2)/stim.fr); % freezing episodes outside twinp
                                    delInds2= find(ts{:} + twinp(1) < 1); % freezing episodes outside twinp
                                    trials_selec(unique([delInds1 delInds2]))= []; % remove freezing episodes
                                    ts{:}(unique([delInds1 delInds2]))= []; % remove freezing episodes
                                    ts_stop{:}(unique([delInds1 delInds2]))= []; % remove freezing episodes
                                    if length(trials_selec) > par.nLongestFreezEpisodes % take only longest freezing episodes
                                        [~,durids]= sort(ts_stop{:}- ts{:},'descend'); % sort freezing episodes duration
                                        delInds= durids(par.nLongestFreezEpisodes+1:end);
                                        trials_selec(delInds)= []; % remove freezing episodes
                                        ts{:}(delInds)= []; % remove freezing episodes
                                        ts_stop{:}(delInds)= []; % remove freezing episodes
                                    end
                                    trials_selec= 1:length(trials_selec); % turn trial numbers to ids
                                elseif strcmp(par.stims{istim},'motion')
                                    trials_selec= 1:length(ts{1}); % average over all locomotion
                                end
                            else
                                trials_selec= par.trials{istim};
                            end

                            testresp= [];

                            if par.no_withdrawal==1
                                % delete trials with any reaction
                                trials_selec(data(imouse,isession).info.behavior(itest).aversive_reaction~=0)=[];
                            elseif par.no_withdrawal==2
                                % delete trials with no withdrawal
                                trials_selec(data(imouse,isession).info.behavior(itest).aversive_reaction==0)=[];
                            end

                            % paw withdrawal frequency
                            if strcmp(par.stims{istim},'sensoryStim')
                                witi= data(imouse,isession).info.behavior(itest).paw_withdrawal(trials_selec);
                                wit(imouse,test)= (sum(witi)/length(witi)*100);
                            else
                                wit=[];
                            end

                            % get response per trial and cell
                            if ~isempty(trials_selec)
                                % get response per trial
                                for itrial= trials_selec % collect data for each trial
                                    if contains(par.stims{istim},'motion') && par.high_fr_motion
                                        testresp(:,:,itrial)= dat(:, round(ts{itest}(itrial)*par.motion_frame_rate) + twinp); % get response around timestamp
                                    else
                                        testresp(:,:,itrial)= dat(:, round(ts{itest}(itrial)*stim.fr) + twinp); % get response around timestamp
                                    end


                                    % baseline mean response  for each trial and each cell by subtracting the mean over baseline period (traces only)
                                    if ~contains(par.stims{istim},'motion') && contains(par.datFields{idatfield},'traces') % no baseline for motion or spikes
                                        for icell= 1:size(testresp,1)
                                            testresp(icell,:,itrial)= testresp(icell,:,itrial) - mean(testresp(icell,1:par.baseline(istim)*stim.fr,itrial));
                                        end
                                    end
                                end

                            else
                                % if no data, fill with zeros
                                for itrial= trials_selec
                                    testresp(:,:,itrial)= zeros(length(twinp),size(dat,1));
                                end
                            end

                            % append test
                            mm(:,:,test,:)= testresp; % cells, frame, test, trial

                            % restrict to global cells (conditioning sessions only)
                            if par.globalCellsIds && ~isempty(stim.session.globalCellsIds) && istim<4
                                mm= mm(stim.session.globalCellsIds{imouse}(:,isession),:,:,:);
                            end
                        end
                    end

                    % add cellIds per mouse
                    try
                        lastId= cellIds{istim,imouse-1,isession}(end);
                    end

                    if imouse==1
                        cellIds{istim,imouse,isession}= 1:size(testresp,1);
                    else
                        cellIds{istim,imouse,isession}=  lastId + (1:size(mm,1));
                    end

                    % append mouse response
                    mmcat= cat(1,mmcat,mm); % icell, frames, itest, itrial

                else % if empty session data for mouse
                    cellIds{istim,imouse,isession}= 0;
                end
            end

            mmcat= squeeze(mmcat); % remove extra dimension if only one test (conditioning) or only one "cell" (motion) % icell, iframe, (itest), itrial
            dims= size(mmcat);

            %% get mean percent stim responses for each test based on MEAN response over twin_respp: mean(sum(stim.traces.CS.RespTrialsIds{isession},2))
            % different from percent of responsive cells
            if length(dims)==3 % only one test per session
                % get mean response within resp.win for each cell, each trial
                respi{isession}= squeeze(mean(mmcat(:,twin_respp{idatfield},:),2));
                respids= respi{isession} > par.thres_resp(istim);

                % percent responsive trials per cell
                resppcCat{isession,idatfield}= round(100*sum(respids(:,par.trials{istim}),'all') / (size(mmcat,1)*length(par.trials{istim})),1);

            elseif length(dims)==4  % several tests per session
                for itest= 1:dims(3)
                    % get mean response withing resp.win for each trial
                    respi{isession}(:,itest,:)= squeeze(mean(mmcat(:,twin_respp{idatfield},itest,:),2));
                    % get responsive trials per test, per cell
                    respids(:,itest,:)= respi{isession}(:,itest,:) > par.thres_resp(istim);
                end
                % percent responsive trials
                resppcCat{isession,idatfield}= round(100*sum(respids(:,:,par.trials{4}),[1 3]) / (size(mmcat,1)*length(par.trials{4})),1);
            end

            % get responsive cell ids, i.e what cells respond on more trials than par.minRespTrials
            if ~par.no_withdrawal
                respidsstore{isession,idatfield}= respids;
                if ismember(isession,stim.session.conditioning)
                    respIdsCat{isession}= find(sum(respids,2)>= par.minRespTrials(istim) );
                elseif ismember(isession,stim.session.sensoryStim)
                    [cellid,testid]= find( squeeze(sum(respids,3)) >= par.minRespTrials(istim) );
                    for itest= 1:length(unique(testid))
                        respIdsCat{isession,itest}= cellid(testid==itest);
                    end
                end
            else
                respidsstore{isession,idatfield}= nan;
                respIdsCat{isession}= nan;
            end

            meanTrialResponse{isession,idatfield}= mmcat; % store responses
            witstore{isession}= wit; % store paw withdrawal
            % get total number of cells per session
            ncell(isession,istim)= size(mmcat,1);


            %% sort cells according to MEAN response amplitude over mean response
            % does not change mmcat, only outputs MMcat
            if par.cell_sort
                MMcat= mean(mmcat,length(dims)); % average trials

                if  par.cell_sort_test && isequal(sessions,stim.session.sensoryStim)% sort cels within every test
                    % sort according to responses to one particular test (sensorystim only)
                    [~,sortIds]= sort(mean(MMcat(:, twin_respp{idatfield}, par.cell_sort_test),2),'descend');
                    sortIdsCat{isession}= sortIds;
                else
                    if length(dims)==4 % sensory stim, several tests per session
                        for itest= 1:size(mmcat,3)
                            if par.cell_sort_maxRespTime % sort according to time of maximum response
                                [~,maxFrame]= max(MMcat(:,twin_respp{idatfield}, itest),[],2);
                                [~,sortIds]= (sort(maxFrame));
                            else % sort according to maximum response
                                [~,sortIds]= sort(mean(MMcat(:,twin_respp{idatfield}, itest),2),'descend');
                            end
                            sortIdsCat{isession,itest}= sortIds;
                        end

                    elseif length(dims)==3 % conditioning, one test per session
                        if par.cell_sort_maxRespTime % sort according to time of maximum response
                            [~,maxFrame]= max(MMcat(:,twin_respp{idatfield}),[],2);
                            [~,sortIds]= (sort(maxFrame));
                        else % sort according to maximum response
                            [~,sortIds]= sort(max(MMcat(:,twin_respp{idatfield}),[],2),'descend');
                        end
                        sortIdsCat{isession}= sortIds;
                    end
                end
            end
        end

        %% append stim results
        stim.(par.datFields{idatfield}).(par.stims{istim}).meanTrialResponse= meanTrialResponse(:,idatfield)'; % mean response trace per test or session
        stim.(par.datFields{idatfield}).(par.stims{istim}).PcTrialResponses= resppcCat(:,idatfield)'; % percent of responses per test/session (bad name)
        stim.(par.datFields{idatfield}).(par.stims{istim}).RespTrialsIds= respidsstore(:,idatfield)'; % ids of responsive cells  per trial(empty if par.cell_sort)
        stim.(par.datFields{idatfield}).(par.stims{istim}).RespTrials= respi;
        stim.(par.datFields{idatfield}).(par.stims{istim}).respCellIds= respIdsCat; % inds responsive cells

        if par.globalCellsIds
            stim.session.ncell= stim.session.globIdsSum;
        else
            stim.session.ncell= max(ncell,[],2); % bit convoluted, I'll give you that
        end
        stim.session.cellIds= cellIds;
        % other
        stim.(par.datFields{idatfield}).(par.stims{istim}).twin_resp= twin_respp{1};
        stim.(par.stims{istim}).withdrawal= witstore; % paw withdrawal
        stim.(par.stims{istim}).twinp= twinp;
        stim.(par.datFields{idatfield}).(par.stims{istim}).sortIds= sortIdsCat;
    end
end
% stuff




