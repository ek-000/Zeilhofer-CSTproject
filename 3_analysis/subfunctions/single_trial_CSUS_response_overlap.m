function single_trial_CSUS_response_overlap(stim,par)

for isession= 1:length(par.sessions)
        for imouse= stim.mice
            mouseIds= stim.session.cellIds{1,imouse,par.sessions(isession)}; % istim, imouse, isession
            [~,ids]= sort(sum(stim.traces.CS.RespTrialsIds{par.sessions(isession)}(mouseIds,par.trials),2),'descend'); 
            CSrespCellIds=      ids(1:floor(length(ids)/2));
            CSnorespCellIds=    ids(floor(1+length(ids)/2):end);
            USrespCellIds= find(sum(stim.traces.US.RespTrialsIds{par.sessions(isession)}(mouseIds,par.trials),2) >=2) ;
            PcUSRespAmongCSResp(imouse,isession)= sum(ismember(USrespCellIds,CSrespCellIds)) /length(CSrespCellIds);
            PcUSRespAmongCSnoResp(imouse,isession)= sum(ismember(USrespCellIds,CSnorespCellIds)) /length(CSnorespCellIds);
        end
end
% remove eventual empty trials
PcUSRespAmongCSResp(PcUSRespAmongCSResp==0)= nan;
PcUSRespAmongCSnoResp(PcUSRespAmongCSnoResp==0)= nan;
% plot
figure('position', [100 100 700 500]);
cols= {stim.session.sessioncols{2}, stim.session.sessioncols{2}, stim.session.sessioncols{3}, stim.session.sessioncols{3}};
dat= {PcUSRespAmongCSResp(:,1), PcUSRespAmongCSnoResp(:,1), PcUSRespAmongCSResp(:,2), PcUSRespAmongCSnoResp(:,2)};
boxplots(dat,'mean','color',cols);
xticklabels({'CS responsive, cond','CS unresp, cond','CS responsive, condvar','CS unresp, condvar'})
xtickangle(45)
ylabel('Percent co-US responsive cells')
% statistics
 [str,tbl,p,results,means,stats,mm_ss_string]= SD_anovan(dat,'BC');
name{1}= [stim.groupName ' session ' num2str(par.sessions) ' trials ' [num2str(par.trials(1)) '-' num2str(par.trials(end))] ' CS-US response percent overlap'];
name{2}= str;
name{3}= num2str(round(p,3));
name{4}= mm_ss_string;
full_str = SD_ttest(dat{3},dat{4});
name{5}= ['3_4 ' full_str{2}];
title(name,'fontsize',12,'interpreter','none')

if par.save % save
    SD_save(name{1},par.saveDir);
end

