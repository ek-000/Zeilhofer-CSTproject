function [global_cells,Icat,name]= find_global(neuron,sessions,sessioncols,par,saveDir)

% % output
%     global_cells{isess}= [first2last ; last2first]; % for each session, matched cells inds of current and next session

for isess= sessions(1:end-1)

    saveDir_contour= fullfile(saveDir{1},'contours'); mkdir(saveDir_contour) % create contour save folder in first session folder

    %% get neuron contours for each session and plot
    clear im
    for isession= isess:isess+1
        dims= size(neuron(isession).Cn); % contours image pixel dimensions
        % add final contours
        figure('color','w','position',[100 100 100+dims(2) 100+dims(1)]); hold on
        xlim([0 dims(2)])
        ylim([0 dims(1)])
        for icont= 1:length(neuron(isession).Coor) % loop through each contour
            cont= neuron(isession).Coor{icont};
            y=cont(2,:); x=cont(1,:);
            plot(x,y,'LineStyle','none');
            h= fill(x,y,sessioncols{isession}); % fill contours
            set(h,'facealpha',0.5) % tranparency
        end
        set(gca,'ydir','reverse')
        axis off; box off
        imtemp= frame2im(getframe); % capture current contours
        im{isession}= imresize(imtemp,dims); % store capture for registration
    end
    im(cellfun(@isempty,im))=[]; % remove empty sessions


    %% register sessions contours
    % what is happening here is that we register the captured image of the
    % cell countours from previous section. The output is the tform to be applied to individual
    % contours in next section
    [optimizer,metric]= imregconfig(par.reg_mode); % set parameters

    % register next session to current session
    Rfixed = imref2d(size(im{1}));
    if strcmp(par.reg_tform,'imregister2')
        [~,~, tform]= imregister2(rgb2gray(im{2}), rgb2gray(im{1}), par.reg_transfo, optimizer, metric); % rigid, translation
    elseif strcmp(par.reg_tform,'imregtform')
        tform = imregtform(rgb2gray(im{2}), rgb2gray(im{1}), par.reg_transfo, optimizer, metric); % same thing
    end
    imreg= imwarp(im{2}, tform, 'OutputView', Rfixed); % apply tform
    % overlay sessions
    imtemp= imfuse(im{1},imreg,'falsecolor','Scaling','joint','ColorChannels',[1 2 1]);
    imtemp= imresize(imtemp, dims);
    I= cat(4,im{1},imreg,imtemp); % stack: both sessions + fused
    Icat{isess}= I; % store for each session: 1: ref session, 2: reg session, 3: overlap sessions, just to check
    %     figure; imshow(Icat{isess}(:,:,:,3),[]) % check from capture regsitration

    %% plot and save registered contours
    % here we apply the tform from the previous session to individual
    % contours and save them to check overlap between sessions
    mag= 3; % image magnification
    close all, clear contours
    dims= size(neuron(isess).Cn)*mag; % contours image pixel dimensions

    figure('color','w','position',[100 100 100+dims(2) 100+dims(1)]); hold on
    xlim([0 dims(2)]); ylim([0 dims(1)])

    % plot first session contours
    for icont= 1:length(neuron(isess).Coor) % loop through each contour
        x= neuron(isess).Coor{icont}(1,:)*mag;
        y= dims(1)-neuron(isess).Coor{icont}(2,:)*mag;
        cont1= polyshape(x,y);
        plot(cont1,'FaceColor','green');
        contours{1,icont}= cont1; % store contours
    end

    %  plot registered session contours
    for icont= 1:length(neuron(isess+1).Coor) % loop through each contour
        x= neuron(isess+1).Coor{icont}(1,:)*mag;
        y= dims(1)-neuron(isess+1).Coor{icont}(2,:)*mag;
        cont2= polyshape(x,y);

        % apply tform
        T= tform.T; % get tform

        if ~strcmp(par.reg_transfo,'translation') && isempty(par.angle) && par.angle_session~=isess
            % get angle (arcos always returns positive angle, need angle (radiant) direction from angle sinus)
            if T(1,2) > 0
                angle= -rad2deg(acos(T(2,2)));
            elseif T(1,2) < 0
                angle= rad2deg(acos(T(2,2)));
            end
            cont2= rotate(cont2, angle, [0 dims(1)]); % apply rotation
        end
        % apply rotation of choice because algo sucks
        if ~isempty(par.angle) && par.angle_session==isess
            cont2= rotate(cont2, par.angle, [0 dims(1)]); % apply rotation
        end

        % apply tranlation of choice because algo sucks
        if ~isempty(par.tranlation) && par.tranlation_session==isess
            cont2= translate(cont2, [par.tranlation(1) par.tranlation(2)]); % apply translation
        else
            cont2= translate(cont2, [T(3,1)*mag -T(3,2)*mag]); % apply translation
        end
        plot(cont2,'FaceColor','magenta');
        contours{2,icont}= cont2; % store contours
    end
    axis off; box off
    title(['First session (green) ' num2str(length(neuron(isess).Coor)) ' cells, ' 'Second session (magenta) ' num2str(length(neuron(isess+1).Coor)) ' cells'] ,'fontsize',16)

    if par.save
        saveas(gcf, fullfile(saveDir_contour, ['contours registered session ' num2str(isess) ' ' num2str(isess+1)]), 'png') ; % save a .png
    end
    % figure; imshow(Icat{1}(:,:,:,3),[]) % check from capture regsitration
    % that things look the same

    %% get overlap between last session and first session contours
    clear contOverlapPc
    for icont1= 1:length(neuron(isess).Coor) % loop through each contour first session
        cont1= contours{1,icont1};
        for icont2= 1:length(neuron(isess+1).Coor) % loop through each contour last session
            cont2= contours{2,icont2};
            % measure pairwise contours overlap between sessions
            contOverlap= intersect(cont1,cont2);
            contOverlapPc(icont1,icont2)=  polyarea(contOverlap.Vertices(:,1), contOverlap.Vertices(:,2)) / polyarea(cont2.Vertices(:,1), cont2.Vertices(:,2));
        end
    end


    %% find cell inds with large overlap between session
    maxOverlap= max(contOverlapPc,[],1); % for each cell contour in second session, maximum overlap in first session
    % find correponding cell inds from first session
    clear last2firstContourOverlapIds
    for icont= 1:size(contOverlapPc,2)
        if maxOverlap(icont) > par.SpatialOverlapThresh % if overlap
            [~,temp]= ismember(maxOverlap(icont),contOverlapPc(:,icont));
            if length(temp)==1 % only if one region overlaps more than the others
                first2last(icont)= temp;
            else
                first2last(icont)= nan;
            end
        else
            first2last(icont)= nan;
        end
    end
    last2first= find(~(isnan(first2last))); % get corresponding first session cell contours ids
    first2last(isnan(first2last))=[]; % remove nans

    


    %% plot overlaping contours
    % add final contours
    figure('color','w','position',[100 100 100+dims(2) 100+dims(1)]); hold on
    xlim([0 dims(2)])
    ylim([0 dims(1)])

    % plot first session contours
    for icont= first2last % loop through each contour
        if ~isempty(contours{1,icont})
            plot(contours{1,icont},'FaceColor','green'); hold on
        end
    end

    % plot regitered session contours
    for icont= last2first % loop through each contour
        if ~isempty(contours{2,icont})
            plot(contours{2,icont},'FaceColor','magenta'); hold on
%         else error('stop')
        end
    end
    axis off; box off

    % remove empty contours
    del_ids= find(cellfun(@isempty,contours(2,last2first)));
    last2first(del_ids)=[]; first2last(del_ids)=[];


    % title
    name= ['First session (green) ' num2str(length(first2last)) ' (' num2str(round(100* length(first2last) / length(neuron(isess).Coor))) '%) cells, ' ...
        ' Second session (magenta) ' num2str(length(last2first)) ' (' num2str(round(100* length(last2first) / length(neuron(isess+1).Coor))) '%) cells'];
    title(name ,'fontsize',16)

    % output
    global_cells{isess}= [first2last ; last2first]; % for each session, matched cells inds of current and next session

    if par.save
        saveas(gcf, fullfile(saveDir_contour, ['contours overlap session ' num2str(isess) ' ' num2str(isess+1)]), 'png') ; % save a .png
    end
end

