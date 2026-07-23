function P= single_cell_test_response_comparison(stim,par,opt)

%% collect responses
% collect cell response average per test
resp= stim.traces.sensoryStim.meanTrialResponse{par.session}; % icell, resp, itest, itrial
meanresp= mean(resp,4); % mean response over all trials % icell, resp, itest

twinresp= stim.traces.sensoryStim.twin_resp; % response time window

tests= 1:size(meanresp,3);

% integrate response (AUC)
respAuc=[];
for itest= tests
    respAuc(:,itest)= trapz(squeeze(meanresp(:,twinresp,itest)),2); % get AUC response per trial % icell, itest
end


%% plot response amplitude correlation between all tests (imagesc)
if opt.imagesc
    if ~isempty(par.tests)
        tests= par.tests;
    end
    R=[]; P=[];
    for itest= tests
        dim1= respAuc(:,itest);
        for iitest= tests
            dim2= respAuc(:,iitest);
            [r,p] = corrcoef(dim1,dim2);
            R(itest,iitest)= round(r(1,2),3);
            P(itest,iitest)= round(p(1,2),3);
        end
    end
    R(R==1)=0; % remove autocorrelation
    % plot imagesc
    figure; imagesc(tril(R)); caxis([-par.colaxis par.colaxis]);
    colormap(redblue)
    SD_figure_appearance
    colorbar
    yticks(tests)
    xticks(tests)
    if par.session>4
        tests= tests+1; % shift by one test because first one is spontaneous
    end
    yticklabels(stim.names(tests))
    xticklabels(stim.names(tests))
    clear name
    name{1}= ['single_cell_test_response_comparison tests session ' num2str(par.session)];
    name{2}= ['tests ' num2str(par.tests)];
    title(name,'fontsize',12,'interpreter','none')

    P= tril(P);
    
    if par.save % save
        SD_save(name{1},par.saveDir)
    end
end


%% plot response amplitude correlation chosen tests (scatter)
if opt.scatter
    figure('position',[200 200 1200 300]);
    for itest_compare= 1:length(par.test_compare)
        subplot(1,length(par.test_compare),itest_compare)
        dat1= respAuc(:,par.test_compare{itest_compare}(1));
        dat2= respAuc(:,par.test_compare{itest_compare}(2));
        % plot
        scatter(dat1,dat2,'k','MarkerEdgeColor','none','MarkerFaceColor','k','MarkerFaceAlpha',0.4);
        xlabel (stim.names(par.test_compare{itest_compare}(1)));
        ylabel (stim.names(par.test_compare{itest_compare}(2)));
        SD_figure_appearance
        % linear regression
        coef= polyfit(dat1,dat2,1); hold on
        X=  get(gca,'xlim');
        Y= [coef(1)*X(1)+coef(2) coef(1)*X(2)+coef(2)] ;
        plot([X(1),X(2)],[Y(1),Y(2)],'color','r','linewidth',1); % regression
        % R and P values
        [R,p]= corrcoef(dat1,dat2);
        R= round(R(1,2),3);
        p= round(p(1,2),3);
        title(['R=' num2str(R) '; P=' num2str(p) '; n=' num2str(round(length(dim1))) ' cells'])
        linkaxes
    end
    clear name
    name= ['single_cell_test_response_comparison tests ' num2str(unique([par.test_compare{:}]))];
    

    if par.save % save
        SD_save(name,par.saveDir)
    end
end

