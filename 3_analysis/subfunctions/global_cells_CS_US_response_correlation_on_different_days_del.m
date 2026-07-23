function global_cells_CS_US_response_correlation_on_different_days(stim,par)

% get data
if strcmp(par.response_selection,'number of responsive trials')
    % get number of CS response per cell on day 1
    CSd1= sum(stim.traces.CS.RespTrialsIds{1},2);
    % get number of CS response per cell on day 1
    CSd2= sum(stim.traces.CS.RespTrialsIds{2},2);
    % get number of CS response per cell on day 3
    CSd3= sum(stim.traces.CS.RespTrialsIds{3},2);
    % get number of US response per cell on day 2
    USd2= sum(stim.traces.US.RespTrialsIds{2},2);
elseif strcmp(par.response_selection,'integral response')
    % get number of CS response per cell on day 1
    CSd1= mean(stim.traces.CS.RespTrials{1},2);
    % get number of CS response per cell on day 1
    CSd2= mean(stim.traces.CS.RespTrials{2},2);
    % get number of CS response per cell on day 3
    CSd3= mean(stim.traces.CS.RespTrials{3},2);
    % get number of US response per cell on day 2
    USd2= mean(stim.traces.US.RespTrials{2},2);
    % get number of US response per cell on day 3
    USd3= mean(stim.traces.US.RespTrials{3},2);
    % get number of US response per cell on day 3
    USd4= mean(stim.traces.US.RespTrials{4},2);
end

% choose xdata

if strcmp(par.xdata, 'CS day1')
    dim1= CSd1;
elseif strcmp(par.xdata, 'CS day2')
    dim1= CSd2;
elseif strcmp(par.xdata, 'CS day3')
    dim1= CSd3;
elseif strcmp(par.xdata, 'CS day2 - CS day1')
    dim1= CSd2-CSd1;
elseif strcmp(par.xdata, 'CS day3 - CS day1')
    dim1= CSd3-CSd1;
elseif strcmp(par.xdata, 'CS day3 - CS day2')
    dim1= CSd3-CSd2;
elseif strcmp(par.xdata, 'US day2')
    dim1= USd2;
elseif strcmp(par.xdata, 'US day3')
    dim1= USd3;
elseif strcmp(par.xdata, 'US day4')
    dim1= USd4;
end

% choose ydata
if strcmp(par.ydata, 'CS day1')
    dim2= CSd1;
elseif strcmp(par.ydata, 'CS day2')
    dim2= CSd2;
elseif strcmp(par.ydata, 'CS day3')
    dim2= CSd3;
elseif strcmp(par.ydata, 'CS day2 - CS day1')
    dim2= CSd2-CSd1;
elseif strcmp(par.ydata, 'CS day3 - CS day1')
    dim2= CSd3-CSd1;
elseif strcmp(par.ydata, 'CS day3 - CS day2')
    dim2= CSd3-CSd2;
elseif strcmp(par.ydata, 'US day2')
    dim2= USd2;
elseif strcmp(par.ydata, 'US day3')
    dim2= USd3;
elseif strcmp(par.ydata, 'US day4')
    dim2= USd4;
end

% plot correlations
figure('position',[100 100 600 500]);
scatter(dim1,dim2,'k','MarkerEdgeColor','none','MarkerFaceColor','k','MarkerFaceAlpha',0.4);

% linear regression
coef = polyfit(dim1,dim2,1); hold on
X =  get(gca,'xlim');
Y = [coef(1)*X(1)+coef(2) coef(1)*X(2)+coef(2)] ;
[R,p] = corrcoef(dim1,dim2);
R = round(R(1,2),3);
p = round(p(1,2),3);
% plot linear regression
plot([X(1),X(2)],[Y(1),Y(2)],'color','r','linewidth',1); % regression
clear name
name{1}= [stim.groupName ' ' par.xdata ' Vs ' par.ydata ' ' par.response_selection];
name{2}= ['R=' num2str(R) '; P=' num2str(p) '; n=' num2str(round(length(dim1))) ' cells'];
title(name)
SD_figure_appearance

if ~isempty(par.xlim)
    xlim(par.xlim)
end
if ~isempty(par.ylim)
    ylim(par.ylim)
end

xlabel([par.xdata ' ' par.response_selection])
ylabel([par.ydata ' ' par.response_selection])

SD_save(name{1},par.saveDir)