function [R,P,PcFreez,binnedMotion,binnedSpikes]= get_activity_motion_corr(data,stim,par)

for imouse= par.mice
    for isession= stim.session.conditioning
        % get data
        dim1= data(imouse,isession).motion.binnedMotion(1:stim.durationTarget);
        dim2= data(imouse,isession).binnedSpikes(1:stim.durationTarget);
        
        if strcmp(par.freez,'all')
            % get % freezing
            PcFreezi= data(imouse,isession).behavior.freezing.PcFreez;
        elseif strcmp(par.freez,'CS')
            % get % freezing during tone
            PcFreezi= data(imouse,isession).behavior.freezing.PcFreezCS;
        end
        
        % plot
        figure('position',[100 100 600 500]);
        % plot scatter
        scatter(dim1,dim2); hold on
        % linear regression
        coef = polyfit(dim1,dim2,1);
        X =  get(gca,'xlim');
        Y = [coef(1)*X(1)+coef(2) coef(1)*X(2)+coef(2)] ;
        [Ri,Pi] = corrcoef(dim1,dim2);
        Ri = Ri(1,2); Pi = Pi(1,2);
        % plot linear regression
        plot([X(1),X(2)],[Y(1),Y(2)],'color','k','linewidth',1);
        % appearance
        SD_figure_appearance
        xl= get(gca,'xlim'); xlim([-3 xl(2)])
        yl= get(gca,'ylim'); ylim([-3 yl(2)])
        xlabel('binned motion (a.u, 1 sec bins)')
        ylabel('binned spike number (1 sec bins)')
        name=  [stim.groupName ' mouse ' num2str(imouse) ', session ' num2str(isession) ';   R = ' num2str(round(Ri,3)),...
            ';   P = ' num2str(round((Pi),4)) ';   ' num2str(round(PcFreezi,1)) '% freezing'];
        title(name);
        if ~par.plot
            close(gcf)
        end
        % output
        R(imouse,isession)= Ri;
        P(imouse,isession)= Pi;
        PcFreez(imouse,isession)= PcFreezi;
        binnedMotion(imouse,isession,:)= dim1;
        binnedSpikes(imouse,isession,:)= dim2;
    end
end