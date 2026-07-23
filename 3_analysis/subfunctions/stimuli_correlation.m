function [pcCorespCat, ma, mi]= stimuli_correlation(stim,par)

sessions= stim.session.(par.session);

for isession= sessions
    tests= stim.side{strcmp(par.side,stim.labels)}; % only one side
    tests= tests-1; % remove spontaneous
    
    % get data
    respIds= stim.traces.(par.session).respCellIds(isession,tests); % get responsive cells inds
    % turn to binary
    clear binary
    for itest=1:length(respIds)
        binaryTest= false(1,stim.session.ncell(isession)); % pre-allocate
        binaryTest(respIds{itest})= true;
        binary(:,itest)= binaryTest;
    end
    
    % calcultate responsive cells overlap between tests
    for itest= 1:length(respIds)
        for iitest= 1:length(respIds)
            test1_or_2= sum( binary(:,itest) |  binary(:,iitest)); % percent cells responsive to test 1 or 2
            test1_and_2= sum( binary(:,itest) &  binary(:,iitest)); % percent cells responsive to test 1 and 2
            pcCoresp(itest,iitest)= (test1_and_2 / length(binary(:,itest)) )*100;
            if itest==iitest
                pcCoresp(itest,iitest)= 0; % we are not interested in that
            end
        end
    end
    pcCoresp(pcCoresp==100 | pcCoresp==0)= 0; % remove self-correlation
    pcCorespMin(isession)= min(pcCoresp(:)); % collect min for plot
    pcCorespMax(isession)= max(pcCoresp(:)); % collect maximum for plot
     % output
    pcCorespCat{isession}= pcCoresp;
end
    

%% plot
% difference post minus pre CCI
if par.diff 
    pcCorespCat{isession+1}= pcCorespCat{isession} - pcCorespCat{isession-1};
    pcCorespMin(isession+1)= min(pcCorespCat{isession+1}(:)); % collect min for plot
    pcCorespMax(isession+1)= max(pcCorespCat{isession+1}(:)); % collect maximum for plot
    sessions=isession+1;
end
ma= max(pcCorespMax); mi= min(pcCorespMin(pcCorespMin~=0)); % get min and max overlaps over sessions


% plot for each session
for isession= sessions
    figure; imagesc(tril(pcCorespCat{isession}))
    % appearance
    SD_figure_appearance
    if par.diff
        colormap(redblue)
    else
        colormap(flipud(gray))
    end
    % set colormap lims
    if strcmp(par.cax,'zero-max')
        caxis([0 ma])
    elseif strcmp(par.cax,'min-max')
        caxis([mi ma])
    elseif strcmp(par.cax,'user-defined')
        caxis(par.caxi)
    end
    
    % plot name
    name{1}= [stim.groupName  'stimuli_correlation session' num2str(isession) ' ' par.side];
    name{2}= 'based on neuron mean responsiveness per test (binary)';
    c= colorbar;
    c.Label.String = {'% Co-responsive cells', '(% cells responsive to test 1 + 2 / all cells)'};
    xticks(1:size(pcCorespCat{isession},2))
    xticklabels(stim.names(tests))
    xtickangle(45)
    yticks(1:size(pcCorespCat{isession},2))
    yticklabels(stim.names(tests))
    title(name,'interpreter','none')
    axis tight
    
    if par.save % save
        SD_save(par.name,par.saveDir)
    end
end
