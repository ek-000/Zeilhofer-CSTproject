function mean_motion= plot_motion_path(data,stim,par)

for imouse= stim.mice
    % plot each session mouse centroid position over time
    if par.plot_path
        figure('position', [50 50 900 800]);
        for isession= par.session
            dat= data(imouse,isession).motion.centroid; % get centroid position
            if length(par.session)==4
                subplot(length(par.session)/2,length(par.session)/2,isession);
            elseif length(par.session)==3
                subplot(1,length(par.session),isession);
            end
            scatter(dat(1,:),dat(2,:),10,'.','k'); hold on % plot
            % apperance
            SD_figure_appearance;
            axis tight; axis off;

            %% calculate time in corners and center
            % split are into 3x3 grid (corners and center)
            gridsize= 3;
            xl= xlim; xrange= xl(2)-xl(1); xedges= xl(1) : xrange/gridsize : xl(1) + xrange;
            yl= ylim; yrange= yl(2)-yl(1); yedges= yl(1) : yrange/gridsize : yl(1) + yrange;
            clear xydatLenght
            for iregion= 1:5 % 4 corners + center
                if iregion==1 % BL corner
                    cornerXedges= [xedges(1) xedges(2)]; cornerYedges= [yedges(1) yedges(2)];
                elseif iregion==2 % UL corner
                    cornerXedges= [xedges(1) xedges(2)]; cornerYedges= [yedges(end-1) yedges(end)];
                elseif iregion==3 % UR corner
                    cornerXedges= [xedges(end-1) xedges(end)]; cornerYedges= [yedges(end-1) yedges(end)];
                elseif iregion==4 % BR corner
                    cornerXedges= [xedges(end-1) xedges(end)]; cornerYedges= [yedges(1) yedges(2)];
                elseif iregion==5 % center
                    cornerXedges= [xedges(2) xedges(3)]; cornerYedges= [yedges(2) yedges(3)];
                end
                xdat= find(dat(1,:) > cornerXedges(1) & dat(1,:) < cornerXedges(2));
                xydatLenght(iregion)= sum(dat(2,xdat) > cornerYedges(1) & dat(2,xdat) < cornerYedges(2));
            end

            % calculate total and mean motion
            motion= data(imouse,isession).motion.rs_motion;
            mean_motion(imouse,isession)= (sum(motion)/ length(motion))* stim.fr; % convert to mean cm/s

            % average corners
            xydatLenght= [mean(xydatLenght(1:4)) xydatLenght(end)]; % number of datapoints in corner and center
            % ratio time spent in center over corner
            center_corner_ratio(imouse,isession)= xydatLenght(2) / xydatLenght(1);

            %%
            clear name; name{1}= ['session: ' stim.session.session_labels{isession}];
            name{2}= [' center_corner_ratio= ' num2str(round(center_corner_ratio(imouse,isession),2))];
            name{3}= [num2str(round(mean_motion(imouse,isession),1)) ' cm per sec'];
            title(name,'interpreter','none');
        end
        name= [stim.groupName ' mouse ' num2str(imouse) ' centroid position over 25 min'];
        subtitle(name);
        % par.save
        if par.save
            SD_save(name, par.saveDir)
        end
    end
end

%% plot center_corner_ratio
if par.plot_center_corner_ratio
    figure;
    if length(par.session)==4
        plotdat= {center_corner_ratio(:,1),center_corner_ratio(:,2),center_corner_ratio(:,3),center_corner_ratio(:,4)}; % one bar per session
    elseif length(par.session)==3
        plotdat= {center_corner_ratio(:,1),center_corner_ratio(:,2),center_corner_ratio(:,3)}; % one bar per session
    elseif length(par.session)==5
        plotdat= {center_corner_ratio(:,1),center_corner_ratio(:,2),center_corner_ratio(:,3),center_corner_ratio(:,4),center_corner_ratio(:,5)}; % one bar per session
    end
    boxplots(plotdat,'mean','color', stim.session.sessioncols,'line','scatter','marker_alpha',0.5);
    SD_figure_appearance
    xticklabels(stim.session.session_labels);
    ylabel('ratio time in center / corners')
    % statistics
    clear name; name{1}= 'center_corner_ratio';
    [str,~,p,~,~,~,mmssstr]= SD_anovan(plotdat,'BC');
    name{2}= str;
    name{3}= ['P= ' num2str(round(p,3))];
    name{4}= mmssstr;
    % compare session 1 and 3
    str= SD_ttest(plotdat{1},plotdat{3});
    name{5}= ['session 1 vs 3: ' str{2}];
    title(name,'fontsize',12,'interpreter','none'); % update title
    if par.save
        SD_save(name{1}, par.saveDir)
    end
end




    




%
% %%
% range= 20500:21500;
% scatter(dat(1,:),dat(2,:),10,'.','w'); hold on % plot
% scatter(dat(1,range),dat(2,range),10,'.','k'); hold on % plot
%
% %%
% figure;
% plot(data(imouse,isession).motion.rs_motion)