function TimeAnalysis
clc;
    import bioma.data.*;

    TimeAnalysisPLSR;
    %plotTP;
end

function plotTP
    DM = rowFilter(getDataMat, 'PC9');

    IDXearly = DM(:,'T (min)') > 0 & DM(:,'T (min)') < 11;
    IDXmid = DM(:,'T (min)') > 11 & DM(:,'T (min)') < 61;
    IDXlate = DM(:,'T (min)') > 61 | DM(:,'T (min)') == 0;

    subplot(3,3,4);
    scatPlot(IDXearly, 'MEKm', 'cJUNm', DM);
    axis([0 1000 0 60]);
    fixPlot('MEK', 'cJUN', 'Early (5 - 10 min)')
    subplot(3,3,5);
    scatPlot(IDXmid, 'MEKm', 'cJUNm', DM);
    axis([0 1000 0 60]);
    fixPlot('MEK', 'cJUN', 'Middle (15 - 60 min)')
    subplot(3,3,6);
    scatPlot(IDXlate, 'MEKm', 'cJUNm', DM);
    axis([0 1000 0 60]);
    fixPlot('MEK', 'cJUN', 'Late (2 - 4 hr)')

    subplot(3,3,7);
    scatPlot(IDXearly, 'ERKm', 'cJUNm', DM);
    axis([0 20 0 60]);
    fixPlot('Erk', 'cJUN', 'Early (5 - 10 min)')
    subplot(3,3,8);
    scatPlot(IDXmid, 'ERKm', 'cJUNm', DM);
    axis([0 20 0 60]);
    fixPlot('Erk', 'cJUN', 'Middle (15 - 60 min)');
    subplot(3,3,9);
    scatPlot(IDXlate, 'ERKm', 'cJUNm', DM);
    axis([0 20 0 60]);
    fixPlot('Erk', 'cJUN', 'Late (2 - 4 hr)');
    
    print2eps('output',gcf);
end

function scatPlot(x, siteOne, siteTwo, DM)
    GFs = {'EGF', 'HRG', 'IGF', 'PDGF', 'FGF', 'HGF', 'None'};
    GFicon = {'o', 'h', 'p', 'd', 's', '<', '>'};

    IDX = find(x);
    
    for ii = 1:length(IDX)
        GF = regexp(DM.RowNames(IDX(ii)),'-','split');
        icc = GFicon(strcmp(GFs, GF{1}(3)));
        
        scatter(DM(IDX(ii),siteOne),DM(IDX(ii),siteTwo),80,DM(IDX(ii),'Viabilitym'),icc{1},'filled');
        
        hold on;
    end
    
end


function TimeAnalysisPLSR
    colFilter = @(dataM, string) dataM(:,not(cellfun('isempty', strfind(dataM.ColNames, string))));

    DM = colFilter(rowFilter(getDataMat, 'PC9'), 'm');
    DM(:,'STAT3m') = [];
    DM(:,'GSKm') = [];
    DM(:,'JNKm') = [];

    GFs = {'EGF', 'HRG', 'IGF', 'PDGF', 'FGF', 'HGF', 'None'};
    Cond = {'Simul', 'No Drug', 'Stagg'};

    rowOut = 1;
    for ii = 1:length(GFs)
        for jj = 1:length(Cond)
            temp = rowFilter(rowFilter(DM,GFs{ii}),Cond{jj});

            if ~isempty(temp)
                longg(rowOut,:) = mean(double(temp(temp(:,'T (min)') > 100,:)),1); %#ok<AGROW>
                aucc(rowOut,:) = trapz(double(temp(:,1)),double(temp),1); %#ok<AGROW>
                namess{rowOut} = [GFs{ii} '-' Cond{jj}]; %#ok<AGROW>
                rowOut = rowOut + 1;
            end
        end
    end

    data = zscore(horzcat(longg(:,2:end), aucc(:,3:end)));
    ColNames = [DM.ColNames(2:end) DM.ColNames(3:end)];

    for jj = 1:4
        ColNames{jj + 1} = [ColNames{jj + 1} ' long'];
        ColNames{jj + 5} = [ColNames{jj + 5} ' AUC'];
    end

    [~,~,~,~,~,PCTVAR] = plsregress(data(:,2:end), data(:,1),3);
    barss(:,1) = cumsum(100*PCTVAR(2,:));

    IDX = [3 4 5 7 8 9];
    [~,~,~,~,~,PCTVAR] = plsregress(data(:,IDX), data(:,1),3);
    barss(:,end+1) = cumsum(100*PCTVAR(2,:));

    IDX = 2:5;
    [~,~,~,~,~,PCTVAR] = plsregress(data(:,IDX), data(:,1),3);
    barss(:,end+1) = cumsum(100*PCTVAR(2,:));
    
    IDX = 3:5;
    [~,~,~,~,~,PCTVAR] = plsregress(data(:,IDX), data(:,1),3);
    barss(:,end+1) = cumsum(100*PCTVAR(2,:));
    
    IDX = 6:9;
    [~,~,~,~,~,PCTVAR] = plsregress(data(:,IDX), data(:,1),3);
    barss(:,end+1) = cumsum(100*PCTVAR(2,:));
    
    IDX = [2 3 4 6 7 8];
    [~,~,~,~,~,PCTVAR] = plsregress(data(:,IDX), data(:,1),3);
    barss(:,end+1) = cumsum(100*PCTVAR(2,:));


    IDX = 2:5;
    [XLA, XLjk, XLS, XSjk] = jackyknife(data(:,IDX),data(:,1),2);
    subplot(3,3,1);
    bar(1:size(barss,1),barss);
    legend('Full', 'Without AKT', 'Just sust', 'Just sust wo Akt', 'Just AUC', 'Without cJun');
    axis([0 size(barss,1)+1 0 100]);
    fixPlot('Components', 'Percent Explained', 'Reduced Models');
    subplot(3,3,2);
    ploterr(XLA(:,1),XLA(:,2),XLjk(:,1),XLjk(:,2),'o');
    text(XLA(:,1),XLA(:,2),ColNames(IDX));
    fixPlot('Principal Component 1', 'Principal Component 2', 'Reduced Model Loading');
    axis([-5 5 -4 4]);
    subplot(3,3,3);
    ploterr(XLS(:,1),XLS(:,2),XSjk(:,1),XSjk(:,2),'o');
    fixPlot('Principal Component 1', 'Principal Component 2', 'Reduced Model Scores');
    text(XLS(:,1),XLS(:,2),namess);
end

function fixPlot(xlab, ylab, ttitle)
    xlabel(xlab);
    ylabel(ylab);
    title(ttitle);
    set(gca, 'FontName', 'Myriad Pro')
    set(gca,'FontSize',16)
    axis square;
    
    set(gcf, 'Position', [500 100 1200 1000])
end

function out = rowFilter(dataM, string)
    out = dataM(not(cellfun('isempty', strfind(dataM.RowNames, string))),:);
end


function [T, data, mmean, sem, auc] = getDataInt(GF, Plan, CellLine, Site, pplot, ccolor)

if nargin < 5
    pplot = 0;
end

if nargin < 6
    ccolor = 'k';
end

[num, txt] = xlsread('FullSet.xls');

colIDX = find(strcmp(txt(1,:), Site)) - 3;

GFIDX = find(strcmp(txt(:,3),GF));
PlanIDX = find(strcmp(txt(:,2),Plan));
CellIDX = find(strcmp(txt(:,1),CellLine));

rowIDX = intersect(intersect(GFIDX, PlanIDX), CellIDX)-1;


data = num(rowIDX, colIDX);


T = num(rowIDX, 1);
mmean = mean(data, 2);
sem = std(data, 0, 2) ./ sqrt(size(data, 2));

mmeanUp = mmean + sem;
mmeanDown = mmean - sem;


for ii = 1:size(data,2)
    auc(ii) = trapz(T, data(:,ii)-data(1,ii));
end

if pplot
    h = fill( [T; flipud(T)],  [mmeanUp; flipud(mmeanDown)], ccolor);
    h.LineWidth = 0.01;
    hold on;
    alpha(0.25);
    plot(T, mmean, ccolor, 'LineWidth', 2);
    axis([min(T) max(T) 0 max(mmeanUp)*1.1]);
    ylabel('FI')
    xlabel('Time (min)');
end

end



function DM = getDataMat

import bioma.data.*;

[num, txt] = xlsread('FullSet.xls');

for ii = 2:size(txt,1)
    txtRow{ii-1} = [txt{ii,1} '-' txt{ii,2} '-' txt{ii,3}]; %#ok<AGROW>
end

DM = DataMatrix(num,txtRow,txt(1,4:end));

sites = {'AKT', 'MEK', 'JNK', 'ERK', 'cJUN', 'STAT3', 'GSK'};

for ii = 1:length(sites)
    neww = DataMatrix([nanmean(double(DM(:,sites{ii})),2), ...
        nanstd(double(DM(:,sites{ii})),0,2)/sqrt(3)], ...
        txtRow,{[sites{ii} 'm'],[sites{ii} 's']});
    DM(:,sites{ii}) = [];
    DM = horzcat(DM, neww); %#ok<AGROW>
end

end









