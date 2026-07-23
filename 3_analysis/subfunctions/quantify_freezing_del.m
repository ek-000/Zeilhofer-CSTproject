function data= quantify_freezing(data,stim,par)

% parameters
par.winmerge=       0.2; % sec, merge freezing episodes 0.2
par.winfreez=       2; % sec, minimum time freezing for freezing episode 2
par.tones=          1:10;
par.mice=           stim(1).mice;
par.marker_alpha=   0.6; % plot marker transparency

% define sessions
par.sessions= stim(1).session.freezing;
if size(data,2) < length(par.sessions) % if less sessions than conditioning sessions (e.g control conditioning)
    par.sessions= par.sessions(1:size(data,2));
end


if length(stim)==1

    for imouse= par.mice

        try
            nfr= data(imouse,isession).info.info.nfr;
        catch
            nfr= 15200;
        end

        for isession= par.sessions
            %% get data
            if ~isempty(data(imouse,isession).motion)
                dat= data(imouse,isession).motion.rs_motion; % get resampled motion
                dat(dat > prctile(dat,99.5))=  prctile(dat,99.5); % limit artifacts

                %% get freezing episodes start and end
                freezfr= dat < par.freez_thres;
                freezfr(1)=0; freezfr(end)=0;

                % freezing episodes
                startFreez= find(diff(freezfr)== 1);
                stopFreez= find(diff(freezfr)== -1);

                % merge closeby episodes
                for iep= 2:length(startFreez)
                    stop_time= startFreez(iep) - stopFreez(iep-1);
                    if stop_time < par.winmerge  *stim.fr
                        startFreez(iep)= nan; stopFreez(iep-1)= nan;
                    end
                end
                startFreez(isnan(startFreez))= []; stopFreez(isnan(stopFreez))= [];

                % remove short episodes
                for iep=1:length(startFreez)
                    ep_time= stopFreez(iep) - startFreez(iep);
                    if ep_time < par.winfreez* stim.fr
                        startFreez(iep)= nan; stopFreez(iep)= nan;
                    end
                end
                startFreez(isnan(startFreez))= []; stopFreez(isnan(stopFreez))= [];

                % update freezing frames
                freezfr= [];
                for iep=1:length(startFreez)
                    ifreez= startFreez(iep):stopFreez(iep);
                    freezfr= [freezfr ifreez];
                end
                freez_all(imouse,isession).freezfr= freezfr; % append
                freez_all(imouse,isession).startfr= startFreez; % append
                freez_all(imouse,isession).stopfr=  stopFreez; % append

                %% Freezing during tone CS
                tonefr={}; toneFreezfr={}; pctToneFreez=[];
                for itone= par.tones
                    try
                        tonefr{itone}= round(data(imouse,isession).behavior.tone.tson(itone) *stim.fr : data(imouse,isession).behavior.tone.tsoff(itone) *stim.fr);
                        toneFreezfr{itone}= ismember(tonefr{itone}, freezfr);
                        pctToneFreez(itone)= round(sum(toneFreezfr{itone} / length(toneFreezfr{itone}))*100, 2);
                    catch
                        tonefr{itone}= [];
                        pctToneFreez(itone)= 0;
                    end
                end
                data(imouse,isession).behavior.tone.tonefr= tonefr; % append
                freez_all(imouse,isession).pctToneFreez= pctToneFreez; % append
                freez_all(imouse,isession).toneFreezfr= toneFreezfr; % append

                %% plot single mouse freezing
                if par.single_mouse
                    t= 1/stim.fr: 1/stim.fr: length(dat)/stim.fr; % time vector
                    figure('position',[100 100 1600 500]);
                    % plot motion
                    plot(t, dat,'k'); hold on
                    % add threshold line
                    line([0 t(end)],[par.freez_thres par.freez_thres], 'color', 'm')
                    % add freezing episodes
                    for iep= 1:length(startFreez)
                        plot([startFreez(iep) stopFreez(iep)]/stim.fr,[0 0],'r','linewidth',6);
                    end
                    % add tones
                    for istim= par.tones
                        if ~isempty(tonefr{istim})
                            xrect = [tonefr{istim}(1) tonefr{istim}(end)  tonefr{istim}(end) tonefr{istim}(1)]/ stim.fr;
                            yrect = [0, 0, max(dat), max(dat)];
                            patch(xrect, yrect, 'b','FaceAlpha',0.15,'edgecolor','none');
                        end
                    end
                    % appearance
                    SD_figure_appearance
                    ylabel('motion between frames')
                    xlabel('time (sec)')
                    set(gca,'ticklength',[0 0]);
                    name= [data(imouse,isession).info.info.mouse_number ' ' stim.session.session_labels{isession} '     '...
                        num2str(round(mean(freez_all(imouse,isession).pctToneFreez))) ' % freezing during tone'];
                    title(name,'interpreter','none')
                    % save
                    if par.save
                        mkdir(fullfile(par.saveDir,'single mouse'))
                        SD_save(name,fullfile(par.saveDir,'single mouse'))
                    end
                end

                % calculate a couple of useful things for output
                data(imouse,isession).behavior.freezing= freez_all(imouse,isession); % append
                % convert all freezing frames to seconds
                data(imouse,isession).behavior.freezing.freezTime= unique(round(data(imouse,isession).behavior.freezing.freezfr))/ stim.fr;
                % get overall freezing pc
                data(imouse,isession).behavior.freezing.PcFreez= round(length(data(imouse,isession).behavior.freezing.freezTime ) / nfr *100,1);
                % get CS freezing pc during CS
                data(imouse,isession).behavior.freezing.PcFreezCS= round(mean(data(imouse,isession).behavior.freezing.pctToneFreez),1);
                % get CS freezing pc outside CS

            end
        end
    end
end


%% plot average freezing per group
clear pctToneFreez
if length(stim)==1
    for imouse= stim.mice
        for isession= par.sessions
            pctToneFreez(isession,imouse,:)= data(imouse,isession).behavior.freezing.pctToneFreez;
        end
    end

else

    iimouse= 0;
    for igroup= 1:length(data)
        for imouse= stim(igroup).mice
            iimouse= iimouse+1;
            for isession= stim(1).session.CS
                pctToneFreez(isession,iimouse,:)= data{igroup}(imouse,isession).behavior.freezing.pctToneFreez;
            end
        end
    end
end

dat= nanmean(pctToneFreez,3); % session,mouse
plotdat= mat2cell(dat, ones(size(dat,1),1), size(dat,2));
cols= stim(1).session.sessioncols(stim(1).session.CS);

if par.remove_session2
    plotdat(2)=[];
    cols(2)=[];
end



% plot per session
if par.plot
    figure;
    boxplots(plotdat,'mean','color',cols,'line','scatter','marker_alpha',par.marker_alpha);
    % appearance
    ylim([0 100])
    ylabel('% freezing during tone')
    xticklabels(stim(1).session.session_labels(par.sessions))
    % statistics
    [str,~,p,~,~,~,mmssstr]= SD_anovan(plotdat,'BC');
    clear name; name{1}= 'mean freezing during tone';
    name{2}= str;
    name{3}= ['P= ' num2str(round(p,3))];
    name{4}= mmssstr;
    title(name{1},'fontsize',12); % update title

    title(name,'fontsize',12,'interpreter','none')
    % save
    if par.save
        SD_save(name{1},par.saveDir)
    end
end

%% plot average freezing per tone
plotdat= squeeze(nanmean(pctToneFreez,2))';
plotdat= reshape(plotdat,[1 size(plotdat,1)*size(plotdat,2)]);

if par.plot
    figure;
    b= bar(plotdat); hold on
    b.FaceColor = 'flat';
    for isession= par.sessions
        trials= 1+(isession-1)*size(pctToneFreez,3) : isession*size(pctToneFreez,3);
        b.CData(trials,:)= repmat(stim(1).session.sessioncols{isession},length(trials),1);
    end
    % appearance
    SD_figure_appearance
    ylim([0 100])
    ylabel('% freezing during tone CS')
    xlabel('Tone CS presentation')
    name= 'Freezing during each tone';
    title(name,'fontsize',12,'interpreter','none')
    % save
    if par.save
        SD_save(name,par.saveDir)
    end
end
