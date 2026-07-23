function [Icat,global_cells]= find_global(neuron,sessions,sessioncols,opt,saveDir)

% if several session save directory, save in the last session folder
if iscell(saveDir)
    saveDir=saveDir{end};
end

if length(sessions)>1 % does not make sense otherwise
    saveDir_contour= fullfile(saveDir,'contours'); mkdir(saveDir_contour) % create contour folder
    
    %% get neuron contours for each session and plot
    im={};
    mag= 3; % magnification image
    for isession= sessions
        dims= size(neuron(isession).Cn)*mag; % contours image pixel dimensions
        % add final contours
        figure('color','w','position',[100 100 100+dims(2) 100+dims(1)]); hold on
        xlim([0 dims(2)])
        ylim([0 dims(1)])
        for i=1:length(neuron(isession).Coor) % loop through each contour
            cont= neuron(isession).Coor{i};
            y=cont(2,:)*mag; x=cont(1,:)*mag;
            plot(x,y,'LineStyle','none');
            h= fill(x,y,sessioncols{isession}); % fill contours
            set(h,'facealpha',0.5) % tranparency
        end
        set(gca,'ydir','reverse')
        axis off; box off
        imtemp= frame2im(getframe); % keep image
        im{isession}= imresize(imtemp,dims); % keep image
        %         close(gcf)
    end
    im(cellfun(@isempty,im))=[]; % remove empty sessions
    
    
    %% register sessions contours
    [optimizer,metric]= imregconfig('multimodal'); % set parameters
    for isession = sessions(1:end-1)
        % register next session to current session
        [~,~, tform{isession}]= imregister2(rgb2gray(im{isession+1}), rgb2gray(im{isession}), 'rigid', optimizer, metric);
        Rfixed = imref2d(size(im{isession})); % reference
        imreg= imwarp(im{isession+1}, tform{isession}, 'OutputView', Rfixed); % apply tform
        % overlay sessions
        imtemp= imfuse(im{isession},imreg,'falsecolor','Scaling','joint','ColorChannels',[1 2 1]);
        imtemp= imresize(imtemp, dims);
        I= cat(4,im{isession},imreg,imtemp); % stack: both sessions + fused
        Icat{isession}= I; % store for each session
    end
    
    %% collect overlap between last session and first session contours
    clear contOverlapPc
    isession= 1;
    for icont1 =1:length(neuron(isession).Coor) % loop through each contour first session
        
        x= neuron(isession).Coor{icont1}(1,:);
        y= neuron(isession).Coor{icont1}(2,:);
        cont1= polyshape(x,y);
        
        for icont2= 1:length(neuron(isession+1).Coor) % loop through each contour last session
            
            x= neuron(isession+1).Coor{icont2}(1,:);
            y= neuron(isession+1).Coor{icont2}(2,:);
            cont2= polyshape(x,y);
            
            % apply tform
            T= tform{isession}.T; % tform
            cont2= translate(cont2,T(3,1), T(3,2)); % x y translation
            cont2= rotate(cont2,acos(T(2,2))); % rotation
            
            % measure pairwise overlap between contours
            contOverlap= intersect(cont1,cont2);
            contOverlapPc(icont1,icont2)=  polyarea(contOverlap.Vertices(:,1), contOverlap.Vertices(:,2)) / polyarea(cont2.Vertices(:,1), cont2.Vertices(:,2));
        end
    end
    
    %% find cell inds with large overlap between session
    par.SpatialOverlapThresh= 0.6; % if overlap covers more that this proportion of the latest session contour
    
    M= max(contOverlapPc,[],1); % for each cell contour in second session, maximum overlap in first session
    % find correponding cell inds from first session
    clear overlap
    for i= 1:size(contOverlapPc,2)
        if M(i) > par.SpatialOverlapThresh % if overlap
            [~,temp]= ismember(M(i),contOverlapPc(:,i));
            if length(temp)==1 % only if one region overlaps more than the others
                overlap(i)= temp;
            else
                overlap(i)= nan;
            end
        else
            overlap(i)= nan;
        end
    end
    
    
    
    %% plot overlapping contours
    mag= 3; % magnification image
    dims= size(neuron(isession).Cn)*mag; % contours image pixel dimensions
    % add final contours
    figure('color','w','position',[100 100 100+dims(2) 100+dims(1)]); hold on
    xlim([0 dims(2)])
    ylim([0 dims(1)])
    for icont= 1:length(neuron(isession).Coor) % loop through each contour
        x= neuron(isession).Coor{icont}(1,:)*mag;
        y= neuron(isession).Coor{icont}(2,:)*mag;
        cont1= polyshape(x,y);
        plot(cont1,'FaceColor','green');
    end
    
     for icont= 1:length(neuron(isession+1).Coor) % loop through each contour
        x= neuron(isession+1).Coor{icont}(1,:)*mag;
        y= neuron(isession+1).Coor{icont}(2,:)*mag;
        cont2= polyshape(x,y);
        
        % apply tform
        T= tform{isession}.T; % tform
        cont2= translate(cont2,T(3,1)*mag, T(3,2)*mag); % x y translation
        cont2= rotate(cont2,acos(T(2,2))); % rotation
        
        plot(cont2,'FaceColor','magenta');
        end
        
    
    set(gca,'ydir','reverse')
    axis off; box off
    
    %%
    
    
    %     %% plot overlapping contours
    %     %         im={};
    %     mag= 3; % magnification image
    %     %     for isession= sessions
    %     dims= size(neuron(isession).Cn)*mag; % contours image pixel dimensions
    %     % add final contours
    %     figure('color','w','position',[100 100 100+dims(2) 100+dims(1)]); hold on
    %     xlim([0 dims(2)])
    %     ylim([0 dims(1)])
    %     for i=1:length(neuron(isession).Coor) % loop through each contour
    %
    %         cont= neuron(isession).Coor{i};
    %         x=cont(1,:)*mag;
    %         y=cont(2,:)*mag;
    %         plot(x,y,'LineStyle','none');
    %         h= fill(x,y,sessioncols{isession}); % fill contours
    %         set(h,'facealpha',0.5) % tranparency
    %
    %         cont= neuron(isession+1).Coor{i};
    %         x=cont(1,:)*mag;
    %         y=cont(2,:)*mag;
    %         plot(x,y,'LineStyle','none');
    %         h= fill(x,y,sessioncols{isession+1}); % fill contours
    %         set(h,'facealpha',0.5) % tranparency
    %
    %     end
    %     set(gca,'ydir','reverse')
    %     axis off; box off
    %         imtemp= frame2im(getframe); % keep image
    %         im{isession}= imresize(imtemp,dims); % keep image
    %         close(gcf)
    %     end
    %     im(cellfun(@isempty,im))=[]; % remove empty session
    
    
end


% x= neuron(isession).Coor{icont1}(1,:)*mag;
% y= neuron(isession).Coor{icont1}(2,:)*mag;
% cont1= polyshape(x,y);
%
% figure('color','w','position',[100 100 100+dims(2) 100+dims(1)]); hold on
% xlim([0 dims(2)])
% ylim([0 dims(1)]); hold on
% plot(cont1)
% cont1ini= frame2im(getframe); % keep image
% close(gcf)
% imshow(cont1ini,[])

%     cont1reg= imwarp(cont1ini, tform{isession}, 'OutputView', Rfixed); % apply tform
%         imshow(cont1reg,[])
%         imOverlap= imfuse(cont1ini,cont1reg,'falsecolor','Scaling','joint','ColorChannels',[1 2 1]);
%         imshow(imOverlap,[])
