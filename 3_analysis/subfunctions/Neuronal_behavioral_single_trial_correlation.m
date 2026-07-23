function Neuronal_behavioral_single_trial_correlation(stim, par)

par.stim=   {'CS','US','motion_CS','motion_US'}; % 'motion_CS', 'motion_US' (acceleration)
par.labels= {'CS response integral','US response integral','CS locomotion cm/s','US locomotion cm/s'};

% loop through all combinations of stimuli
for idat1=      4%1:length(par.stim)
    for idat2=  2%:length(par.stim)

        if idat1~=idat2
            da1_2_cat=[]; figure;

            for isession= par.session
                dat1= stim.traces.(par.stim{idat1}).meanTrialResponse{isession}; % mouse or cell, resp, trial
                dat2= stim.traces.(par.stim{idat2}).meanTrialResponse{isession}; % mouse or cell, resp, trial

                if ~isempty(par.trials) % find the corresponding trial inds for CS-US trials fullcond
                    if contains(par.stim{idat1},'CS')
                        trials1= find(ismember(stim.session.fullcond.CS_trials_cat,par.trials));
                    elseif contains(par.stim{idat1},'US')
                        trials1= find(ismember(stim.session.fullcond.US_trials_cat,par.trials));
                    end
                    dat1= dat1(:,:,trials1); % limit data to these trials
                    if contains(par.stim{idat2},'CS') % same for dat2
                        trials2= find(ismember(stim.session.fullcond.CS_trials_cat,par.trials));
                    elseif contains(par.stim{idat2},'US')
                        trials2= find(ismember(stim.session.fullcond.US_trials_cat,par.trials));
                    end
                    dat2= dat2(:,:,trials2); % limit data to these trials
                end


                % get data
                for imouse= stim.mice
                    mouseIds= stim.session.cellIds{1,imouse,isession};
                    for itrial= 1:size(dat1,3) % should be the same size for dat1 and dat2


                        % get data
                        % dat1
                        clear mouseIdsSub ids
                        if contains (par.stim{idat1},'motion')
                            datTrial= dat1(imouse,:,itrial); % get motion
                            dat1Trial= mean(datTrial(stim.traces.(par.stim{idat1}).twin_resp)); % integral 
                        else
                            % get cell ids for the mouse
                            if par.high_fidelity_cells_only % select only X percent cells with highest number of responsive trials
                                if strcmp(par.sort_stim, par.stim{idat1})
                                     % define top responsive cells the number of responsive trials over session
                                    [~,ids]= sort(sum(stim.traces.(par.stim{idat1}).RespTrialsIds{isession}(mouseIds,trials1),2),'descend');
                                elseif strcmp(par.sort_stim, par.stim{idat2})
                                    % define top responsive cells the number of responsive trials over session
                                    [~,ids]= sort(sum(stim.traces.(par.stim{idat2}).RespTrialsIds{isession}(mouseIds,trials1),2),'descend');
                                else
                                    ids= mouseIds;
                                end
                                 % take top % cells Ids with most responsive trials
                                mouseIdsSub= ids(1:ceil(length(mouseIds)*par.thres_topRespPerTrial/100));
                                dat1Trial= trapz(dat1(mouseIds(mouseIdsSub),stim.traces.(par.stim{idat1}).twin_resp,itrial),2);
                            else
                                dat1Trial= trapz(dat1(mouseIds,stim.traces.(par.stim{idat1}).twin_resp,itrial),2); % cellIds, twin, itrial
                            end
                        end


                        % dat2
                        clear mouseIdsSub ids
                        if contains (par.stim{idat2},'motion')
                            datTrial= dat2(imouse,:,itrial); % get US motion
                            dat2Trial= mean(datTrial(stim.traces.(par.stim{idat2}).twin_resp)); % integral acceleration
                        else
                            % get cell ids for the mouse
                            if par.high_fidelity_cells_only % select only X percent cells with highest number of responsive trials\
                                if strcmp(par.sort_stim, par.stim{idat2})
                                     % define top responsive cells the number of responsive trials over session
                                    [~,ids]= sort(sum(stim.traces.(par.stim{idat2}).RespTrialsIds{isession}(mouseIds,trials2),2),'descend');
                                elseif strcmp(par.sort_stim, par.stim{idat1})
                                    % define top responsive cells the number of responsive trials over session
                                    [~,ids]= sort(sum(stim.traces.(par.stim{idat1}).RespTrialsIds{isession}(mouseIds,trials2),2),'descend');
                                else
                                    ids= mouseIds;
                                end
                                % take top % cells Ids with most responsive trials
                                mouseIdsSub= ids(1:ceil(length(mouseIds)*par.thres_topRespPerTrial/100));
                                dat2Trial= trapz(dat2(mouseIds(mouseIdsSub),stim.traces.(par.stim{idat2}).twin_resp,itrial),2); 
                            else
                                dat2Trial= trapz(dat2(mouseIds,stim.traces.(par.stim{idat2}).twin_resp,itrial),2); 
                            end
                        end


                        if par.average_cells
                            dat1Trial= mean(dat1Trial);
                            dat2Trial= mean(dat2Trial);
                        % copy behavioral data to match size of neuronal data
                        elseif length(dat1Trial) > length(dat2Trial)
                            dat2Trial= repmat(dat2Trial,length(dat1Trial),1);
                        elseif length(dat1Trial) < length(dat2Trial)
                            dat1Trial= repmat(dat1Trial,length(dat2Trial),1);
                        end

                        % concatenate trial data
                        da1_2_cat= cat(1,da1_2_cat, [dat1Trial dat2Trial]);
                    end
                end
            end


            % plot
            dim1= da1_2_cat(:,1); % dat1
            dim2= da1_2_cat(:,2); % dat2
            scatter(dim1,dim2,'k','.'); hold on
            xlabel(par.labels{idat1})
            ylabel(par.labels{idat2})
            % linear regression
            coef = polyfit(dim1,dim2,1); hold on
            X =  get(gca,'xlim');
            Y = [coef(1)*X(1)+coef(2) coef(1)*X(2)+coef(2)] ;
            [R,p] = corrcoef(dim1,dim2);
            R = round(R(1,2),3);
            p = round(p(1,2),3);
            % plot linear regression
            plot([X(1),X(2)],[Y(1),Y(2)],'color','r','linewidth',1); % regression
            clear name; name{1}= [stim.groupName ' ' par.stim{idat1} ' Vs ' par.stim{idat2} ' session ' num2str(par.session)];
            if par.high_fidelity_cells_only
                name{1}= [name{1} ' ' num2str(par.thres_topRespPerTrial) '% highest fidelity cells to ' par.sort_stim];
            end
            name{2}= ['R=' num2str(R) '; P=' num2str(p) '; n=' num2str(size(dat1,3)) ' trials from N=' num2str(length(stim.mice)) ' mice'];
            SD_figure_appearance
            title(name,'interpreter','none','fontsize',10)
            if par.save % save
                SD_save(name{1}, par.saveDir);
            end
        end
    end
end