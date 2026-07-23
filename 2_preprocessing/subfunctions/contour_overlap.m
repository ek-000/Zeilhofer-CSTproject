function Icat= contour_overlap(neuron,sessions,sessioncols,opt,saveDir)

if length(sessions)>1 % does not make sense otherwise
    saveDir_contour= fullfile(saveDir,'contours'); mkdir(saveDir_contour) % create contour folder
    dims= [650 650]; % contours image pixel dimensions
    
    %% get neuron contours for each session
    im={};
    for isession= sessions
        % add final contours
        figure('color','w','position',[50 50 850 850]); hold on
        xlim([0 size(neuron(isession).Cn,1)])
        ylim([0 size(neuron(isession).Cn,2)])
        for i=1:length(neuron(isession).Coor)
            cont= neuron(isession).Coor{i};
            x=cont(1,:); y=cont(2,:);
            plot(x,y,'LineStyle','none');
            h= fill(x,y,sessioncols{isession});
            set(h,'facealpha',0.5)
        end
        set(gca,'ydir','reverse')
        axis off; box off
        imtemp= frame2im(getframe);
        im{isession}= imresize(imtemp,dims);
        close(gcf)
    end
    im(cellfun(@isempty,im))=[]; % remove empty sessions
    
    %% register sessions
    [optimizer,metric]= imregconfig('multimodal'); % set parameters
    for isession = sessions(1:end-1)
        % register next session to current session
        [~,~, tform{isession}]= imregister2(rgb2gray(im{isession+1}), rgb2gray(im{isession}), 'affine', optimizer, metric);
        Rfixed = imref2d(size(im{isession})); % reference
        imreg= imwarp(im{isession+1}, tform{isession}, 'OutputView', Rfixed); % apply tform
        % overlay sessions
        imtemp= imfuse(im{isession},imreg,'falsecolor','Scaling','joint','ColorChannels',[1 2 1]);
        imtemp= imresize(imtemp, dims);
        I= cat(4,im{isession},imreg,imtemp); % stack: both sessions + fused
        Icat{isession}= I; % store for each session
    end
    
    %% add neuron numbers to session overlap
    for isession=1:length(Icat)
        figure('color','w','position',[50 50 850 850]);
        imshow(Icat{isession}(:,:,:,end)); hold on % show overlap image session + next session overlap
        % get picture dimensions for rescale
        xl= get(gca,'xlim'); yl= get(gca,'ylim');
        ylf=(xl(2)-xl(1))/size(neuron(isession).Cn,1);
        xlf=(yl(2)-yl(1))/size(neuron(isession).Cn,2);
        % add neuron numbers to overlap image for each session
        for i= [isession isession+1]
            data= neuron(i).A;
            ncell= size(data,2); % reset
            for icell= 1:ncell
                shape= full(reshape(data(:,icell),[sqrt(length(data(:,icell))) sqrt(length(data(:,icell)))])); % get neuron shape
                [x,y]= find(shape==maxN(shape)); % find maximum intensity: center position of neuron
                
                
                % rescale position (take mean in case several pixels have same max intensity)
                x= round(mean(x))*xlf;
                y= round(mean(y))*ylf;
                
%                 % apply tform to shifted session
%                 if i==isession+1
%                     [x,y]= transformPointsInverse(tform{isession},x,y);
%                 end
                
                % plot
                plot(y,x,'.','MarkerSize',10,'color','k'); % dot cell center
                text(round(mean(y))-2,round(mean(x)),num2str(icell),'color',sessioncols{i},'fontsize',12); % indicate neuron number
            end
        end
        name= ['Contours session ' num2str(isession) ' (green) vs session ' num2str(isession+1) ' (magenta) '];
        title(name,'fontsize',16)
        % add overlap image with markers to Icat
        imtemp= imresize(frame2im(getframe),dims);
        Icat{isession}(:,:,:,4)= imtemp;
        % save
        if opt.save
            opt.color=true;
            saveastiff(Icat{isession},fullfile(saveDir_contour,[name '.tif']),opt);
            SD_save(name,saveDir_contour)
        end
    end
end