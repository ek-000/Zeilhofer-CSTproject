function plot_session_traces(data,stim,par,opt)

% parameters
save=       par.save;
saveDir=    par.saveDir;
mouse=      par.mouse;
session=    par.session;
space=      par.space;
fr=         stim.fr;

% get data
% traces
traces= data(mouse,session).traces;
% spikes
spikes= data(mouse,session).spikes;

ts= data(mouse,session).info.timestamps;
ncell= size(traces,1);

if opt.motion_only
    nfr= length(data(mouse,session).motion.rs_motion);
else
    nfr= size(traces,2);
end

t= 1/fr:1/fr:nfr/fr;



figure('color','w','position',[10 100 1400 1000])

%% plot traces
if ~opt.motion_only
    if ~par.plot_selec
        ax(1)= subplot(5,1,[1 2]);
        cells= 1:ncell;
    else
        cells= par.cellRange;
    end

    for icell= cells
        % plot trace
        if par.plot_selec
            plot(par.timeRange/fr, traces(icell,par.timeRange) + space*(icell-1),'color','k'); hold on
        else
            plot(t, traces(icell,:) + space*(icell-1),'color','k'); hold on
        end
        % add spikes detection
        if par.show_spikes_on_traces && sum(spikes(icell,:)) > 0 % if there are any spikes at all
            s= spikes(icell,:); s(s==0)= nan; % make zero spikes nans to avoid plotting them
            scatter(t, traces(icell,:) + space*(icell-1) + 0.0001*s, 80, '.')
        end
    end
    ylim([-space*0.1 space*ncell])
    yticks(1:space:space*ncell)
    yticklabels(num2cell(1:ncell))
    set(gca,'TickLength',[0 0])
    axis tight; box off;
    xlabel('Time (s)','fontsize',12);
    ylabel('Cell no','fontsize',12)

    if ~stim.session.sensoryStim
        title([stim.groupName ' ' data(mouse,session).info.info.mouse_number ', ' stim.session.session_labels{session} ' session, '...
            num2str(round(mean(data(mouse,session).behavior.freezing.pctToneFreez),1)) ' % freeezing during tone']);
    else
        title([stim.groupName ' ' data(mouse,session).info.info.mouse_number ', ' stim.session.session_labels{session}]);
    end
end

% get stimuli timestamps
tscat=[];
if  ismember(session,stim.session.conditioning)
    tscat= [ts{1} ; ts{2}]; % CS and US together
elseif stim.session.sensoryStim
    for itest= 1:length(ts)
        tscat= [tscat ; ts{itest}];
    end
end

% add test label
for itest= 1:length(data(mouse,session).info.behavior)
    if ~isempty(ts{itest})
        if ~isempty(ts{itest})
            yl= get(gca,'ylim');
            text(ts{itest}(1), yl(2)+yl(2)/30, data(mouse,session).info.info(itest).test)
        end
    end
end

%% plot spikes
if ~opt.motion_only
    ax(2)= subplot(5,1,3);
    plot(t,sum(spikes),'k'); hold on

    % appearance
    box off; axis tight
    ylabel('Spikes per frame','fontsize',12)

    % plot binned spikes
    ax(3)= subplot(5,1,4);
    binnedSpikes= data(mouse,session).binnedSpikes;
    plot(binnedSpikes,'k'); hold on

    % appearance
    box off; axis tight
    ylabel('Binned spikes per frame','fontsize',12)
end

%% plot motion
if ~ismember(session, stim.session.sensoryStim)
    if ~opt.motion_only
        ax(4)= subplot(5,1,5);
    else
        subplot(2,1,1)
    end
    motion= data(mouse,session).motion.rs_motion;
    % add empty frames at the begining if frames were dropped
    if ~isempty(par.dropped_frames_nb)
        motion= [zeros(1,par.dropped_frames_nb) motion];
        nfr= length(motion);
        t= 1/fr:1/fr:nfr/fr;
    end
    plot(t,motion,'color',0.5*[1 1 1]); hold on % plot

    % appearance
    box off; axis tight
    xlabel('Time (s)','fontsize',12);
    ylabel('Motion (cm/s)','fontsize',12)
    ylim([-1 prctile(motion,99.5)])
end

%% add stimulus lines for each plot
if opt.motion_only
    ax= 1; % only one plot
end
for iplot= 1:length(ax)
    if iplot==1 && ~opt.motion_only
        subplot(5,1,[1 2])
    else
        if ~opt.motion_only
            subplot(5,1,iplot+1)
        end
        yl= get(gca,'ylim');
        ylim([-1 yl(2)]);
        % add freezing episodes
        if ~stim.session.sensoryStim
            freez= data(mouse,session).behavior.freezing;
            for iep= 1:length(freez.startfr)
                plot([freez.startfr(iep) freez.stopfr(iep)]/fr,[-1 -1],'r','linewidth',4)
            end
        end
    end
    line([tscat tscat], yl, 'color', 'b');
end

if ~opt.motion_only
    linkaxes(ax,'x'); % link x axes for all plots
else
    % add plot mean response
    nfr= nfr+ par.added_frames;
    motion= resample(motion,nfr,length(motion)); % resample motion

    twin_fr= -19:100; % time window (frames)
    subplot(2,1,2)
    [mm,ss]= SD_meanEventTrigResp(motion', ts{1}, t', twin_fr, 1); % tones
    SD_shadedErrorBar(twin_fr/fr, mm, ss, {'-', 'LineWidth', 1, 'color', 'k'}, 'transparent', 0.3);
    [mm,ss]= SD_meanEventTrigResp(motion', ts{2}, t', twin_fr, 1); hold on % shock
    SD_shadedErrorBar(twin_fr/fr, mm, ss, {'-', 'LineWidth', 1, 'color', 'r'}, 'transparent', 0.3);
    yl= get(gca,'ylim');
    line([0 0], yl, 'color', 'b'); % add zero line
    ylabel('Motion (cm/s)','fontsize',12)
    SD_figure_appearance
end

%% Figure2: Spikes vs motion correlation (smoothened)
if par.spike_motion_correlation && ~stim.session.sensoryStim
    figure('position',[100 100 1200 500]);
    dim1= data(mouse,session).binnedSpikes;
    dim2= data(mouse,session).motion.binnedMotion;
    subplot(1,2,1) % traces binnes motion and spikes
    % spikes
    dim1= zscore(dim1);
    plot(dim1,'color','k'); hold on

    % motion
    dim2= zscore(dim2);
    plot(dim2,'r');

    % appearance
    SD_figure_appearance
    ylabel('zscore Binned motion and spike number')
    xlabel('Time, s','fontsize',12)

    % add stim lines on plot
    yl= get(gca,'ylim');
    for itest= 1:length(data(mouse,session).info.behavior)
        tsplot= cat(1,ts);
        scatter(tsplot, yl(1) * ones(length(tsplot),1),120,'.','b');
    end
    legend('spikes','motion')

    % plot scatter
    subplot(1,2,2)  % scatter binnes motion and spikes
    dim1= data(mouse,session).motion.binnedMotion;
    dim2=  data(mouse,session).binnedSpikes;
    scatter(dim1,dim2)
    % linear regression
    coef = polyfit(dim1,dim2,1); hold on
    X =  get(gca,'xlim');
    Y = [coef(1)*X(1)+coef(2) coef(1)*X(2)+coef(2)] ;
    [R,p] = corrcoef(dim1,dim2); R = R(1,2); p = p(1,2);

    % plot linear regression
    plot([X(1),X(2)],[Y(1),Y(2)],'color','k','linewidth',1); % regression
    SD_figure_appearance
    xl= get(gca,'xlim'); xlim([-3 xl(2)])
    yl= get(gca,'ylim'); ylim([-3 yl(2)])
    xlabel('binned motion (a.u, 1 sec bins)')
    ylabel('binned spike number (1 sec bins)')
    title(['R = ' num2str(round(R,3)), '; P = ' num2str(round((p),4))]);
end

%% save
if save
    name= [stim.groupName ' mouse ' num2str(mouse) ' session ' num2str(session)];
    SD_save(name,saveDir,'png')
end