function [CS,US]= Venn_CS_US_response_stability(stim,par,folder)

% careful tiple overlap is wrong

% collect data CS
ncell= stim.session.ncell(1);
CS.d1Ids= stim.traces.CS.respCellIds{1};
CS.d2Ids= stim.traces.CS.respCellIds{2};
CS.d3Ids= stim.traces.CS.respCellIds{3};
CS.anyIds= unique([CS.d1Ids; CS.d2Ids; CS.d3Ids]);
% overlap CS
CS.d12Ids= intersect(CS.d1Ids,CS.d2Ids);
CS.d13Ids= intersect(CS.d1Ids,CS.d3Ids);
CS.d23Ids= intersect(CS.d2Ids,CS.d3Ids);
CS.d123Ids= intersect(CS.d12Ids,CS.d23Ids);

% collect data US
US.d2Ids= stim.traces.US.respCellIds{2};
if ~contains(folder.parentDir{stim.group},'fullcond')
US.d3Ids= stim.traces.US.respCellIds{3};
US.d4Ids= stim.traces.US.respCellIds{4};
US.anyIds= unique([US.d2Ids; US.d3Ids; US.d4Ids]);
% overlap US
US.d23Ids= intersect(US.d2Ids,US.d3Ids);
US.d24Ids= intersect(US.d2Ids,US.d4Ids);
US.d34Ids= intersect(US.d3Ids,US.d4Ids);
US.d234Ids= intersect(US.d23Ids,US.d34Ids);
else
    US.anyIds= US.d2Ids;
end
% overlap CSUS
CSUS.CSd1=              CS.d1Ids;
CSUS.CSd3Ids=           CS.d3Ids; 
CSUS.CSd13Ids=            CS.d13Ids;
CSUS.USd2=              US.d2Ids; 
CSUS.CSd1USd2Ids=       intersect(CS.d1Ids,US.d2Ids);
CSUS.CSd3USd2Ids=       intersect(CS.d3Ids,US.d2Ids);
CSUS.CSd1CSd3USd2Ids=   intersect(CSUS.CSd1USd2Ids,CSUS.CSd3USd2Ids);


if ~contains(folder.parentDir{stim.group},'fullcond')
    figure('position',[50 50 1200 800]); % Venn diagram
    plots= 1:3;
% plot CS
subplot(2,3,1)
venn([length(CS.d1Ids) length(CS.d2Ids) length(CS.d3Ids)],... % venn([c1 c2 c3],...
    [length(CS.d12Ids) length(CS.d13Ids) length(CS.d23Ids) length(CS.d123Ids)]);  % [i12 i13 i23 i123])
hold on
% plot US
subplot(2,3,2)
venn([length(US.d2Ids) length(US.d3Ids) length(US.d4Ids)],... % venn([c1 c2 c3],...
    [length(US.d23Ids) length(US.d24Ids) length(US.d34Ids) length(US.d234Ids)]);  % [i12 i13 i23 i123])
% plot CSUS
subplot(2,3,3)
else
    figure('position',[50 50 400 800]); % Venn diagram
    subplot(2,1,1)
    plots= 3;
end
venn([length(CS.d1Ids) length(US.d2Ids) length(CS.d3Ids)],... % venn([c1 c2 c3],...
    [length(CSUS.CSd1USd2Ids) length(CS.d13Ids) length(CSUS.CSd3USd2Ids) length(CSUS.CSd1CSd3USd2Ids)]);  % [i12 i13 i23 i123])

% appearance
for iplot= plots
    clear name T
    % circles properties
    if ~contains(folder.parentDir{stim.group},'fullcond')
        subplot(2,3,iplot)
    else
        subplot(2,1,1)
    end
    ax= gca; tr= par.transparency;
    [ax.Children(:).FaceAlpha]= deal(tr(1),tr(2),tr(3)); % transparency
    if iplot==1 % CS
        par.cols= stim.session.sessioncols(1:3);
        % text numbers
        f= fieldnames(CS);
        for ifield= 1:length(f)
            n= length(CS.(f{ifield})) / ncell *100;
            T{ifield}= [f{ifield} ': ' num2str(round(n,1)) ' %'];
        end
        T{ifield+1}= [num2str(length(CS.anyIds)) '/' num2str(ncell) ' (' num2str(round(length(CS.anyIds)/ncell,1)*100) '%) CS-responsive cells on any day'];
    elseif iplot==2 % US
        par.cols= stim.session.sessioncols(2:4);
        % text numbers
        f= fieldnames(US);
        for ifield= 1:length(f)
            n= length(US.(f{ifield})) / ncell *100;
            T{ifield}= [f{ifield} ': ' num2str(round(n,1)) ' %'];
        end
        T{ifield+1}= [num2str(length(US.anyIds)) '/' num2str(ncell) ' (' num2str(round(length(US.anyIds)/ncell,1)*100) '%) US-responsive cells on any day'];
   
    elseif iplot==3 % CSUS
        par.cols= stim.session.sessioncols(1:3);
        % text numbers
        f= fieldnames(CSUS);
        for ifield= 1:length(f)
            n= length(CSUS.(f{ifield})) / ncell *100;
            T{ifield}= [f{ifield} ': ' num2str(round(n,1)) ' %'];
        end
        T{ifield+1}= [num2str(length(US.anyIds)) '/' num2str(ncell) ' (' num2str(round(length(US.anyIds)/ncell,1)*100) '%) US-responsive cells on any day'];
    end
    % appearance
    [ax.Children(:).FaceColor]= deal(par.cols{3},par.cols{2},par.cols{1}); % color
    SD_figure_appearance; axis off
    % name
    name{1}= ' ';
    name{2}= ' ';
    name{3}= 'green: hab; orange: cond; red: ret';
    title(name,'fontsize',10); % title
    % add text
    if ~contains(folder.parentDir{stim.group},'fullcond')
      subplot(2,1,2)  
    else
        subplot(2,3,iplot+2)
    end
    axis off
    text(0.05,0.9,T,'interpreter','none','fontsize',10.5);
end

name= 'CS and US responsive cells stability over days';
subtitle(name);

if par.save
    SD_save(name,par.saveDir);
end