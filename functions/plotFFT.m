function plotFFT(datapath, ...
                 filenames,...
                 plotType, ...
                 fontsize, ...
                 absoluteOrRelative, ...
                 overlayBands)

% Some hardcoded settings
subplotPos_x = [0.05, 0.5];
subplotPos_y =  linspace( 0.65, 0.085, 3); %[0.6, 0.3];
subplotSize = [0.4, 0.2];

toSavePath = fullfile(datapath, "EEG_spectrum_figures");
mkdir(toSavePath);

    

for p = 1:length(filenames)
    if ~isfile(fullfile(datapath, filenames{p}))
        sprintf('File %s not found', fullfile(datapath, filenames{p}))
        continue
    end
    if strfind(filenames{p}, '.set') 
        cprintf([0,1,1], 'Participant: %s \n', filenames{p})
        EEG = pop_loadset('filename',filenames{p},'filepath',datapath);
        % toSavePath_tmp = fullfile(toSavePath, strrep(EEG.filename, '.set','')); mkdir(toSavePath_tmp);
              
        plotPower(EEG, ...
                  fontsize, ...
                  absoluteOrRelative, ...
                  plotType,...
                  subplotPos_x, ...
                  subplotPos_y, ...
                  subplotSize, ...
                  overlayBands, ...
                  toSavePath)
        
    end
end




function plotPower(EEG, ...
                   fontsize, ...
                   absoluteOrRelative, ...
                   plotType, ...
                   subplotPos_x, ...
                   subplotPos_y, ...
                   subplotSize, ...
                   overlayBands, ...
                   toSavePath_tmp)
    % Prepare settngs for the figure
     if isequal(absoluteOrRelative, 'relative')
        ylimit = 'auto'; %[0, 25];
        ylimit_dB = 'auto'; %[-50,50];
        scale = '%';
    elseif isequal(absoluteOrRelative, 'absolute')
        ylimit = 'auto';%[0, 100];
        ylimit_dB = 'auto';
        scale = '{uV}^2';
    end



    participantName = strrep(EEG.filename, '.set','');
    channels = {EEG.chanlocs.labels};
    sleepPhases = EEG.sleepPhases';
    % C = colormap('jet');
    % colors = C(round(linspace(1, size(colormap, 1), length(sleepPhases))), :);
    FrequencyBands = EEG.frequency_bands;    
    Xlim = [min(cellfun(@(x) min(x), struct2cell(FrequencyBands))), 
            max(cellfun(@(x) max(x), struct2cell(FrequencyBands)))];
   
    
    % Create the figure
    f = figure();
    colormap('jet')
    set(f, 'color', 'white');
    hold on

    % add title
    str = char(absoluteOrRelative);
    figtitle = sprintf('%s power spectrum density \nSubject: %s \nScale: %s', ...
                        strcat(upper(str(1)), str(2:end)), ...
                        participantName, ...
                        scale);
    

    try % Introduced in R2018b
        if strcmp(plotType, 'PSD')    
            t = sgtitle(figtitle); 
            set(t,'FontSize', fontsize*1.5); 
            set(t,'Interpreter', 'Tex'); 
        elseif strcmp(plotType, 'dB')
            t = sgtitle(figtitle); 
            set(t,'FontSize', fontsize*1.5);     
        end
    catch % older matlab version
        if strcmp(plotType, 'PSD')    
            t = suptitle(figtitle); 
            set(t,'FontSize', fontsize*1.5); 
            set(t,'Interpreter', 'Tex'); 
        elseif strcmp(plotType, 'dB')
            t = suptitle(figtitle); 
            set(t,'FontSize', fontsize*1.5);     
        end
    end

    legendLabels = {};
    
    for chan_label = channels
    %     prepare subplots
        chan = find(ismember(EEG.fft.channels, chan_label));
        if isequal(chan_label{1}, 'F3')
            subplot(3,2,1);hold on
            title('F3', 'FontSize', fontsize*1.2 , 'FontWeight', 'bold')  
            position = [subplotPos_x(1) subplotPos_y(1) subplotSize(1) subplotSize(2)];
            showBandsLabels = 1;
            showLegend = 0;

        elseif isequal(chan_label{1}, 'F4')
            subplot(3,2,2);hold on
            title('F4', 'FontSize', fontsize*1.2 , 'FontWeight', 'bold')
            position = [subplotPos_x(2) subplotPos_y(1) subplotSize(1) subplotSize(2)];
            showBandsLabels  =1;
            showLegend = 1;

        elseif isequal(chan_label{1}, 'C3')
            subplot(3,2,3);hold on
            title('C3', 'FontSize', fontsize*1.2 , 'FontWeight', 'bold')
            position = [subplotPos_x(1) subplotPos_y(2) subplotSize(1) subplotSize(2)];
            showBandsLabels = 0; 
            showLegend = 0;

        elseif isequal(chan_label{1}, 'C4')
            subplot(3,2,4);hold on
            title('C4', 'FontSize', fontsize*1.2 , 'FontWeight', 'bold')
            position = [subplotPos_x(2) subplotPos_y(2) subplotSize(1) subplotSize(2)];
            showBandsLabels = 0;
            showLegend = 1;

        elseif isequal(chan_label{1}, 'O1')
            subplot(3,2,5);hold on
            title('O1', 'FontSize', fontsize*1.2 , 'FontWeight', 'bold')
            position = [subplotPos_x(1) subplotPos_y(3) subplotSize(1) subplotSize(2)];
            xlabel('Frequency [Hz]','FontSize', fontsize);
            showBandsLabels = 0;
            showLegend = 0;

        elseif isequal(chan_label{1}, 'O2')
            subplot(3,2,6);hold on
            title('O2', 'FontSize', fontsize*1.2, 'FontWeight', 'bold')
            position = [subplotPos_x(2) subplotPos_y(3) subplotSize(1) subplotSize(2)];
            xlabel('Frequency [Hz]','FontSize', fontsize);
            showBandsLabels = 0;
            showLegend = 1;
        else
            cprintf([1,0,0], 'Cannot plot channel %s. Not implemented yet! \n', chan_label{1})
            continue
           
        end
        
        % plot power
        plotLines = [];
        for e = 1:length(sleepPhases)
            toPlot = EEG.fft.(sleepPhases{e}).(sprintf('%sPower',absoluteOrRelative));
            
            if ~isempty(toPlot)
                if strcmp(plotType, 'dB')
                    pl = plot(EEG.fft.fft_freqs, ...
                              db(toPlot(chan, :)), ...
                              'LineWidth', 3);
                    ylim(ylimit_dB)
                elseif strcmp(plotType, 'PSD')
                    pl = plot(EEG.fft.fft_freqs, ...
                              toPlot(chan, :), ...
                              'LineWidth', 3);
                    ylim(ylimit)
                              
                end
                plotLines(end+1) = pl;
                legendLabels{end+1} = sleepPhases{e};
            end
        end

        % overlay frequerncy power bands rqanges
        if overlayBands
           bandsNames   = fieldnames(FrequencyBands);
           C = colormap('jet');
           colors_bands = C(round(linspace(1, size(colormap, 1), length(fieldnames(FrequencyBands)))), :);
           Xticks = [];
           XticksLabels = {};

           for band = 1:length(bandsNames)
               Ylim = get(gca, 'Ylim');
%                fill([FrequencyBands.(bandsNames{band}), fliplr(FrequencyBands.(bandsNames{band}))], ...
%                    [Ylim(1), Ylim(1), Ylim(2), Ylim(2)], ...
%                    colors_bands(band, :),'facealpha',.1) 
               Xticks(end+1) = mean(FrequencyBands.(bandsNames{band}));
               Xticks(end+1) = FrequencyBands.(bandsNames{band})(2);
               XticksLabels{end+1} = bandsNames{band};
               XticksLabels{end+1} = '';
%                line(FrequencyBands.(bandsNames{band}),[max(Ylim),max(Ylim)], 'color', colors_bands(band, :), 'LineWidth', 5)
               line([FrequencyBands.(bandsNames{band})(1),FrequencyBands.(bandsNames{band})(1)], Ylim, 'color', 'black', 'LineStyle', '--');
           end

           if showBandsLabels
              set(gca, ...
                  'XTick',Xticks, ...
                  'XTickLabel', XticksLabels)
           end

           if showLegend
              legend(plotLines, legendLabels, 'Box', 'off', 'Location','EastOutside','color','none')
           end

        end
    % Set up given subplot
    set(gca, 'Position', position)
    set(gca, 'FontSize', fontsize)
    set(gca, 'color', 'white');
    xlim(Xlim)
    end
    


    figurename = sprintf('PowerSpectrum_%s_%s_%s', ...
                         participantName, ...
                         plotType, ...
                         absoluteOrRelative);
    save_figure(f, toSavePath_tmp, figurename)
    close all
end

function save_figure(figure, toSavePath_tmp, figurename)
    jFrame = get(handle(gcf),'JavaFrame'); 
    jFrame.setMaximized(true);
    % pause(3)
    saveas(figure, fullfile(toSavePath_tmp, figurename), 'png');

%     export_fig( figure, ...            % figure handle
%           fullfile(toSavePath_tmp, figurename),...
%                 '-zbuffer', ...      % renderer
%                 '-png', ...         % file format
%                 '-r100');           % resolution in dpi
% %     set(gcf,'PaperPositionMode','auto');
% %     print(figure, ...
% %           '-dpng',...
% %           fullfile(toSavePath, strrep(EEG.filename, '.set', sprintf('_%s_%s', plotType,absoluteOrRelative))),...
% %           '-r200', ...
% %           '-zbuffer')
%     pause(3)
    close all
end

end
