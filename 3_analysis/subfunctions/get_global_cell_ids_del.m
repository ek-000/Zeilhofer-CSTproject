function  stim= get_global_cell_ids(stim,data,folder)

globIdsSum=0; % sum of all global cell ids

for imouse= stim.mice
    % collect overlapping cells ids between sessions
    ov12= data(imouse,1).info.global_cells';
    ov23= data(imouse,2).info.global_cells';
    if size(data,2)==4
    ov34= data(imouse,3).info.global_cells';
    end

    % find ids of cells present in session 2 that overlap with session 1 and 3
    temp= cat(1,ov12(:,2), ov23(:,1)); % concatenate of overlapping ids of session with 2 other sessions
    out= [unique(temp), histc(temp(:),unique(temp))]; % count number of cell ids occurence
    out(out(:,2)==1,:)=[]; % remove cells that only over la with one session
    id2= out(:,1); % cell ids that overlap with other sessions

    % same for session 3 (overlap with 2 and 4)
    temp= cat(1,ov23(:,2), ov34(:,1));
    out= [unique(temp),histc(temp(:),unique(temp))]; % count number of cell ids occurence for each mouse\
    out(out(:,2)==1,:)=[];
    id3= out(:,1);

    % find position of cell ids that overap with other sessions
    [~,pos2]= ismember(id2, ov23(:,1));
    [~,pos3]= ismember(id3, ov23(:,2));
    % find common ids to session 2 and 3 (which also overlap with session 1 and
    % 4): if we match these cells, we have the position of the cells that
    % overlap between session 2 and 3 AND 1 and 4, respectively, i.e, global cells. Therefore,
    % look for cell ids at the same position
    temp= cat(1,pos2, pos3);
    out= [unique(temp),histc(temp(:),unique(temp))]; % count number of cell ids occurence for each mouse\
    out(out(:,2)==1,:)=[];
    samepos23= out(:,1); % ov23 positions to keep, with corresponding ids in session 1 and 4

    glob2= ov23(samepos23,1); % find cell ids corresponding to position
    glob3= ov23(samepos23,2); % find cell ids corresponding to position

    % find cell ids session 1 corresponding to global cell session 2
    [p,pos1]= ismember(glob2, ov12(:,2));
    delId= find(pos1==0); % weird having to do that
    pos1(delId)=[];
    glob1= ov12(pos1,1);

    % find cell ids session 4 corresponding to global cell session 3
    [~,pos4]= ismember(glob3, ov34(:,1));
    glob4= ov34(pos4,2);

    glob2(delId)=[]; glob3(delId)=[]; glob4(delId)=[];  % weird having to do that

    globIds= [glob1 glob2 glob3 glob4]; % concatenate this mess
    globalCellsIds{imouse}= globIds; % global cells
    globIdsSum= globIdsSum + length(globIds); % total number og global cells
end

    stim.session.globalCellsIds= globalCellsIds; % append
    stim.session.globIdsSum= globIdsSum; % append

% 
% %% create a matrix: global cells ids x session
% clear matched_cell_id
% for igroup= 1:2
% clear n
% for imouse= groupStim{igroup}.mice
%     for isession=1:4
%         n(imouse,isession)= size(groupData{igroup}(imouse,isession).traces,1);
%     end
% end
% 
% matched_cell_id{igroup}=[];
% for imouse= groupStim{1}.mice
% m= groupStim{igroup}.session.globalCellsIds{imouse}
% m= m + sum(n(1:imouse-1,:),1)
% matched_cell_id{igroup}= cat(1,matched_cell_id{igroup},m)
% end
% end
% 
% matched_cell_id_mat={matched_cell_id{1}, matched_cell_id{2}}
% save('matched_cell_id_mat.mat','matched_cell_id_mat')
