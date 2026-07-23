function save_before_after_contours(neuron,directory,filename,Coor_prev,saveDir,imouse,isession)

proj= loadtiff(fullfile(directory.parentDir,directory.mouse_list{imouse},directory.session_list{isession},filename.ca_movie_projection));
% stack max projection + contours
figure('color','w')
imshow(proj,[]);
truesize([850 850]);
im1= getframe(gcf);
truesize,hold on

% add initial contours
for i=1:length(Coor_prev)
    cont= Coor_prev{i};
    plot(cont(1,:),cont(2,:),'color','r','linewidth',1.5);
end

truesize([850 850]);
im2= getframe(gcf);  hold on
pause(1);
imshow(proj,[]);


% add final contours
for i=1:length(neuron.Coor)
    cont=neuron.Coor{i};
    plot(cont(1,:),cont(2,:),'color','g','linewidth',1.5);
end

im3= getframe(gcf); 
pause(1)
I= cat(4,im1.cdata, im2.cdata, im3.cdata);
opt.color= true; opt.overwrite=true;
saveastiff(I,fullfile(saveDir,'countours.tif'),opt);

close(gcf)