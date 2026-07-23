function [neuron,del_ids_shape]= remove_inactive_neurons(neuron,opt,saveDir)


% find inactive
if opt.curation.remove_inactive
    del_ids_ina= mean(neuron.C_raw,2)' < opt.curation.thr_act;
else
    del_ids_ina= false(1,size(neuron.A,2));
end
% find oddsize
if opt.curation.remove_oddsize
    del_ids_size= full(sum(neuron.A,1)) < opt.curation.thr_size(1) | full(sum(neuron.A,1))> opt.curation.thr_size(2);
else
    del_ids_size= false(1,size(neuron.A,2));
end
% find odd shape
if opt.curation.remove_oddshape
    % get neuron contours circularity
    circularity=[];
    for i= 1:size(neuron.A,2)
        I=reshape(neuron.A(:,i), size(neuron.Cn));
        stats = regionprops(imbinarize(full(I)), 'all');
        circularity(i) = stats(1).MaxFeretDiameter/stats(1).MinFeretDiameter;
    end
    del_ids_shape = circularity > opt.curation.thr_shape;
else
    del_ids_shape= false(1,size(neuron.A,2));
end
% combine neurons to delete
del_ids= del_ids_ina | del_ids_size | del_ids_shape; % inds for deletion

% plot contours of deleted neurons
figure('color','w','position',[100 100 800 800])
imagesc(neuron.Cn); hold on
colormap('gray'), axis off
% show all neurons contours
for i=1:length(neuron.Coor)
    cont=neuron.Coor{i};
    plot(cont(1,:),cont(2,:),'color','r','linewidth',1)
end
% show inactive neurons
for i=find(del_ids_ina)
    cont=neuron.Coor{i};
    plot(cont(1,:),cont(2,:),'color','y','linewidth',2)
end
% show odd size neurons
for i=find(del_ids_size)
    cont=neuron.Coor{i};
    plot(cont(1,:),cont(2,:),'color','g','linewidth',2)
end
% show odd shape neurons
for i=find(del_ids_shape)
    cont=neuron.Coor{i};
    plot(cont(1,:),cont(2,:),'color','b','linewidth',2)
end
title(  {[num2str(sum(del_ids_size)) ' odds size (g), '],
    [num2str(sum(del_ids_ina)) ' inactive (y), '],
    [num2str(sum(del_ids_shape)) ' odd shape (b) deleted '],
    [num2str(length(neuron.Coor)-sum(del_ids)) ' remaining']}, 'fontsize', 16)

% ask user to choose neurons
prompt = ['\ndelete the following neurons? (y/n)\n'  num2str(find(del_ids)) '\n'];
yesno= input(prompt,'s');
% apply deletion
if strcmp(yesno,'y')
    % update neuron
    neuron.A(:,del_ids)=[];
    neuron.C(del_ids,:)=[];
    neuron.C_raw(del_ids,:)=[];
    neuron.S(del_ids,:)=[];
    neuron.ids(del_ids)=[];
    neuron.Coor(del_ids)=[];
    fprintf(['\n' num2str(sum(del_ids)) ' deleted neurons, ' num2str(length(neuron.ids)) ' remaining\n'])
    savefig(saveDir,'3 deleted neurons contours') % save figure
    close(gcf)
end