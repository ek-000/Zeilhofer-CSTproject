function neuronal_activity_locomotion_correlation_during_CS(stim,par)

for isession= stim.session.CS

    if strcmp(par.response_selection,'high fidelity')
        % get responsive cell ids (high fidelity)
        CSrespIds= stim.traces.CS.respCellIds{isession}; % get responsive cells to this trial
        % get unresponsive cell ids (high fidelity)
        cells= 1:stim.session.ncell(isession);
        CSunrespIds= cells(~ismember(cells,CSrespIds))'; % get responsive cells to this trial
    end

    for itrial= 1:10
        clear activityMotionCorr unactivityMotionCorr
        ncellResp=1; % initialize
        ncellunResp=1; % initialize

        if strcmp(par.response_selection,'trial resp')
            % get responsive cells to this trial
            CSrespIds= find(stim.traces.CS.RespTrialsIds{isession}(:,itrial)); % get responsive cells to this trial
            CSunrespIds= find(~stim.traces.CS.RespTrialsIds{isession}(:,itrial)); % get unresponsive cells to this trial
        end

        for imouse= stim.mice
            % get data
            % CS responsive cell ids per session
            mouseIds= stim.session.cellIds{1,imouse,isession}; % stim, mouse, session
            CSrespIds_imouse= CSrespIds(ismember(CSrespIds, mouseIds));
            CSunrespIds_imouse= CSunrespIds(ismember(CSunrespIds, mouseIds));
            % CS responsive cells traces
            CSresp= stim.(par.datFields).CS.meanTrialResponse{isession}(CSrespIds_imouse,stim.traces.CS.twin_resp,itrial); % cell, resp
            CSunresp= stim.(par.datFields).CS.meanTrialResponse{isession}(CSunrespIds_imouse,stim.traces.CS.twin_resp,itrial); % cell, resp
            % CS motion during trial
            CSmotion= stim.traces.motion_CS.meanTrialResponse{isession}(imouse,stim.traces.motion_CS.twin_resp,itrial); % resp imouse, twin, itrial

            % bin motion data
            CSmotionBin= resample(CSmotion, round(length(CSmotion)/(stim.fr*par.binsize)), length(CSmotion)); % binned motion

            % correlation between activity and motion during CS
            for icell= 1:size(CSresp,1)
                % bin cell data
                CSrespBin= resample(CSresp(icell,:), round(length(CSmotion)/(stim.fr*par.binsize)), length(CSmotion));
                % correlation
                C= corrcoef(CSmotionBin, CSrespBin);
                activityMotionCorr(ncellResp)= C(1,2);
                ncellResp= ncellResp+1;
            end
            % correlation between unactivity and motion during CS
            for icell= 1:size(CSunresp,1)
                % bin data
                CSunrespBin= resample(CSunresp(icell,:), round(length(CSmotion)/(stim.fr*par.binsize)), length(CSmotion));
                % correlation
                C= corrcoef(CSmotionBin, CSunrespBin);
                C(isnan(C))=0;
                unactivityMotionCorr(ncellunResp)= C(1,2);
                ncellunResp= ncellunResp+1;
            end
        end
        activityMotionCorrCat{isession,itrial,par.group}= activityMotionCorr;
        unactivityMotionCorrCat{isession,itrial,par.group}= unactivityMotionCorr;
    end
end


%% plot correlation per cell
figure('position',[100 100 1200 1000]);
for isession= stim.session.CS

    % plot CS responsive/motion corr
    ax(isession)= subplot(2,length(stim.session.CS),isession);
    clear mm ss
    for itrial= 1:10
        [mm(itrial),ss(itrial),n]= mmss([activityMotionCorrCat{isession,itrial,:}]);
    end
    b= bar(mm); hold on
    er= errorbar(mm,ss,'k','linestyle','none');
    xlabel('Trial number')
    ylabel('Corr(resp ampl Vs CS locomotion)')
    name= ['CS responsive cells: ' stim.session.session_labels{isession}];
    title(name)
    SD_figure_appearance

    % plot CS unresponsive/motion corr
    ax(isession+length(stim.session.CS))= subplot(2,length(stim.session.CS),isession + length(stim.session.CS));
    clear mm ss
    for itrial= 1:10
        [mm(itrial),ss(itrial),n]= mmss([unactivityMotionCorrCat{isession,itrial,:}]);
    end
    b= bar(mm); hold on
    er= errorbar(mm,ss,'k','linestyle','none');
    xlabel('Trial number')
    ylabel('Corr(resp ampl Vs CS loccomotion)')
    name= ['CS unresponsive cells: ' stim.session.session_labels{isession}];
    title(name)
    SD_figure_appearance
end
linkaxes(ax)

% save
NAME= [stim.groupName ' ' par.response_selection ' CS response amplitude Vs CS locomotion correlation per cell over trials'];
if par.save
    SD_save(NAME,par.saveDir);
end

