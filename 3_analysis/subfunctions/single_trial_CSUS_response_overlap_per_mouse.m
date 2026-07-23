function single_trial_CSUS_response_overlap_per_mouse(stim,par)

% get data
for imouse= stim.mice
    for isession= 1:length(par.sess)
        for itrial= par.trials{isession}
            mouseIds= stim.session.cellIds{1,imouse,par.sess(isession)}; % istim, imouse, isession
            % get CS responses integral per cell for trial
            CSrespInt{isession,imouse}= trapz(stim.traces.CS.meanTrialResponse{par.sess(isession)}(mouseIds,stim.traces.CS.twin_resp,itrial),2); % get CS response integral
            [~,CSsortedIds]= sort(CSrespInt{isession,imouse},'descend');  % sort responses

             % split cells inds in 2: 50% most CS responsive and 50% least CS-responsive
            CSrespCellIds=      mouseIds( CSsortedIds(1:floor(length(CSsortedIds)/2)) ) ;
            CSnorespCellIds=    mouseIds( CSsortedIds(floor(1+length(CSsortedIds)/2):end) );

            % get US responses integral per cell for trial
            USrespInt{isession,imouse}= trapz(stim.traces.US.meanTrialResponse{par.sess(isession)}(mouseIds,stim.traces.US.twin_resp,itrial),2); % get CS response integral
            USrespCellIds= mouseIds(stim.traces.US.RespTrialsIds{par.sess(isession)}(mouseIds,itrial)); % get US responsive cells for trial

            % overlap between CS and US responses
            PcUSRespAmongCSResp(imouse,isession,itrial)= sum(ismember(USrespCellIds,CSrespCellIds)) / length(CSrespCellIds);
            PcUSRespAmongCSnoResp(imouse,isession,itrial)= sum(ismember(USrespCellIds,CSnorespCellIds)) / length(CSnorespCellIds);
        end
    end
end

% average trials
PcUSRespAmongCSResp= nanmean(PcUSRespAmongCSResp,3);
PcUSRespAmongCSnoResp= nanmean(PcUSRespAmongCSnoResp,3);
% remove eventual empty trials
PcUSRespAmongCSResp(PcUSRespAmongCSResp==0)= nan;
PcUSRespAmongCSnoResp(PcUSRespAmongCSnoResp==0)= nan;
% plot
figure('position', [100 100 700 500]);
cols= {stim.session.sessioncols{2}, stim.session.sessioncols{2}, stim.session.sessioncols{3}, stim.session.sessioncols{3}};
dat= {PcUSRespAmongCSResp(:,1), PcUSRespAmongCSnoResp(:,1), PcUSRespAmongCSResp(:,2), PcUSRespAmongCSnoResp(:,2)};
[yl,mm_ss_string]= boxplots(dat,'mean','color',cols);
ylim([0 yl(2)])
xticklabels({'50% most CS resp, cond','50% least CS resp, cond','50% most CS resp, condvar','50% least CS resp, condvar'})
xtickangle(45)
ylabel('Percent co-US responsive cells')
% add chance level line: 25% (50% of 50% cells with lowest or highest CS response)
line([0.5 4.5],[0.25 0.25],'color',0.6*[1 1 1],'linestyle','--');
% statistics
[str,~,p,~,~,~,mm_ss_string]= SD_anovan(dat,'BC');
name{1}= [stim.groupName ' session ' num2str(par.sess) ' trials ' ...
    [num2str(par.trials{isession}(1)) '-' num2str(par.trials{isession}(end))] ' CS-US response percent overlap'];
name{2}= str;
name{3}= num2str(round(p,3));
name{4}= mm_ss_string;
full_str = SD_ttest(dat{3},dat{4});
name{5}= ['3_4 ' full_str{2}];
title(name,'fontsize',12,'interpreter','none')

if par.save % save
    SD_save(name{1},par.saveDir);
end

%% plot correlation scatter
% get data
CSrespIntCat=[]; USrespIntCat=[]; 
for imouse= stim.mice
    for isession= 1:length(par.sess)
        CSrespIntCat= [CSrespIntCat; CSrespInt{isession,imouse}];
        USrespIntCat= [USrespIntCat; USrespInt{isession,imouse}];
    end
end
% plot
figure; clear name
dim1= CSrespIntCat; dim2= USrespIntCat;
scatter(dim1,dim2,'.','k'); hold on
% linear regression
coef = polyfit(dim1,dim2,1); hold on
X =  get(gca,'xlim');
Y = [coef(1)*X(1)+coef(2) coef(1)*X(2)+coef(2)] ;
[R,p] = corrcoef(dim1,dim2);
R = R(1,2); p = p(1,2);
% plot linear regression
plot([X(1),X(2)],[Y(1),Y(2)],'color','r','linewidth',1); % regression
xlabel('CS response integral'); ylabel('US response integral')
name{1}= [stim.groupName ' CS-US response integral correlation per cell (mean of all trials)'];
name{2}= ['R= ' num2str(round(R,3)) '; P= ' num2str(round(p,3))];
SD_figure_appearance
title(name,'fontsize',12)
xlim(par.xlim)
ylim(par.ylim)

if par.save % save
    SD_save(name{1},par.saveDir);
end



