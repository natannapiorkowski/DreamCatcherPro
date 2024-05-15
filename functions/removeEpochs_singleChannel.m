% function EEG = removeEpochs_singleChannel(EEG, varargin)
% % TODO
% % dodać opcje zmiany skali amplitudy sygnalu  - amplitudeScale
% 
% p = inputParser;
% p.addRequired('EEG');
% p.addParameter('channelsToPlot', {EEG.chanlocs.labels});
% p.addParameter('channelsOfInterest','0');
% p.addParameter('timeRangeToDisplay',15);
% p.addParameter('colorOfChannelsInterest',[0, 1, 0]);
% p.addParameter('defaultColor',[0, 0, 0]);
% p.addParameter('whatToPlot','data');
% p.addParameter('fft_freq_range',[1 30]);
% 
% p.parse(EEG, varargin{:});
% 
% channelsToPlot = 1:length(p.Results.channelsToPlot);
% channelsLabels = p.Results.channelsToPlot;
% channelsOfInterest = p.Results.channelsOfInterest;
% colorOfInterest = p.Results.colorOfChannelsInterest;
% defaultColor = p.Results.defaultColor;
% howManyEpochsToDisplay = p.Results.timeRangeToDisplay;
% if isequal(p.Results.whatToPlot, 'data')
%     dataToPlot = EEG.(p.Results.whatToPlot)*-1;
%     Fs = EEG.srate;
% 
% elseif isequal(p.Results.whatToPlot, 'fft')
%     dataToPlot = abs(EEG.fft.fft_absolutePower_all)*-1;
%     freqs1 = EEG.fft.fft_freqs >= p.Results.fft_freq_range(1);
%     freqs2 = EEG.fft.fft_freqs < p.Results.fft_freq_range(2);
%     dataToPlot = dataToPlot(:, find(freqs1 .* freqs2), :);
%     Fs = EEG.srate*size(dataToPlot, 2)/EEG.pnts;
% end
% 
% trialLength = size(dataToPlot, 2);
% amplitudeScale = 0.1;
% 
% 
% xLim = [1, howManyEpochsToDisplay*trialLength/EEG.srate]; % seconds
% isEpoched = 1;
% 
% % initialize some variables
% events = {EEG.event.type};
% xtickPositions=[];
% xLabels = {};
% selectedEpoch = [];
% selectedChannel = [];
% screen = 1;
% winrej = nan(EEG.nbchan, EEG.trials);
% scroll_length = howManyEpochsToDisplay*trialLength/EEG.srate;
% modifiedData = nan(size(EEG.data));
% 
% %%
% signalFigure = createFigureToPlotSignal();
% set(signalFigure, 'WindowButtonDownFcn', @ButtonDownFcnCallback)
% %% Add buttons
% h1=uicontrol('Style', 'pushbutton' , 'Max', 0,'Tag', '2',...
%            'String', 'REMOVE','Units', 'normalized',...
%            'Position', [0.35 0 0.3 0.07],'BackgroundColor', [0.5, 0.5, 0.5],...
%            'Callback', {@REMOVE});  
% h2=uicontrol('Style', 'pushbutton' , 'Max', 0,'Tag', '3',...
%            'String', '<<','Units', 'normalized',...
%            'Position', [0.248 0 0.1 0.07],'BackgroundColor', [0.3, 0.3, 0.3],...
%            'Callback', {@SCROLL_PLOT});  
% 
% h3=uicontrol('Style', 'pushbutton' , 'Max', 0,'Tag', '4',...
%            'String', '>>','Units', 'normalized',...
%            'Position', [0.652 0 0.1 0.07],'BackgroundColor', [0.3, 0.3, 0.3],...
%            'Callback', {@SCROLL_PLOT}); 
% uiwait(signalFigure)
% 
% function signalFigure = createFigureToPlotSignal()  
%         signalFigure= figure();
%         axes('position',[0.03 0.1 0.96 0.9]) % [left, bottom, width, height]
%         
%         % setting up channels labels and y=ticks positions
%         ytickPositions=zeros(1,length(channelsToPlot));
%         for i=1:length(channelsToPlot)
%             if ismember(i, channelsOfInterest)
%                 plot(dataToPlot(channelsToPlot(i), 1:xLim(2)*Fs)*amplitudeScale+i*50, 'color', colorOfInterest,'LineWidth', 2)
%             else
%                 plot(dataToPlot(channelsToPlot(i), 1:xLim(2)*Fs)*amplitudeScale+i*50, 'color', defaultColor,'LineWidth', 1)
%             end
%             hold on;       
%             ytickPositions(i)=i*50;
%             ylim([0, i*50+50])
%             xlim(xLim*Fs)
%             
%         end
%         
%         % if data is epoched xlabel refers to epoch. If not xlabel refers to secs
%         if isEpoched
% %             xtickPositions = 1 : size(EEG.data, 2) : xLim(2)*Fs;            
% %             xLabels = events(ceil(xLim(1)/(EEG.pnts/EEG.srate)):xLim(2)/(EEG.pnts/EEG.srate)); %repmat({'trial'}, size(xtickPositions, 2));          
%             xtickPositions =1 : size(EEG.data, 2)/2 : xLim(2)*Fs;      
%             xLabels = repmat({'0'}, 1, size(xtickPositions, 2));
%             ev = events(ceil(xLim(1)/(size(dataToPlot, 2)/Fs)):xLim(2)/(size(dataToPlot, 2)/Fs));            
%             for i =1:length(ev)
%                 xLabels{i*2-1} = ev{i};
%                 xLabels{i*2} = round(xtickPositions(i*2)/size(EEG.data, 2));
%             end
%         else    
%             xtickPositions = 1 : Fs: (xLim(2)+1)*Fs;
%             xLabels = xLim(1):xLim(2);
%         end
%         
%         % display vertical lines on the plot:
%         for j= 1 :2: size(xtickPositions, 2)
%             line([xtickPositions(j) xtickPositions(j)], [1 i*50+50], 'LineStyle', '--', 'Color', [0 0 0])
%         end 
%         
%         set(gca,'yTick', ytickPositions, 'yTickLabel', channelsLabels );
%         set(gca,'xTick', xtickPositions, 'xTickLabel', xLabels);
%         set(gca, 'FontWeight', 'bold', 'FontSize', 12)
%         set( gca, 'YDir', 'reverse' )
% end
% function plot_signal()
%         figure(signalFigure)    
%         cla
%         % setting up channels labels and y=ticks positions
%         for i=1:length(channelsToPlot)
%             if ismember(i, channelsOfInterest)
%                 plot(dataToPlot(channelsToPlot(i), xLim(1)*Fs+1:xLim(2)*Fs)*amplitudeScale+i*50, 'color', colorOfInterest,'LineWidth', 2)
%             else
%                 plot(dataToPlot(channelsToPlot(i), xLim(1)*Fs+1:xLim(2)*Fs)*amplitudeScale+i*50, 'color', defaultColor,'LineWidth', 1)
%             end
%             hold on;       
%         end
%         
%          % if data is epoched xlabel refers to epoch. If not xlabel refers to secs
%         if isEpoched            
%             xtickPositions =1 : size(EEG.data, 2)/2 : xLim(2)*Fs;      
%             xLabels = repmat({'0'}, 1, size(xtickPositions, 2));
%             ev = events(ceil(xLim(1)/(size(dataToPlot, 2)/Fs)):xLim(2)/(size(dataToPlot, 2)/Fs));            
%             for i =1:length(ev)
%                 xLabels{i*2-1} = ev{i};
%                 xLabels{i*2} = (screen-1)*15+round(xtickPositions(i*2)/size(EEG.data, 2));
%             end            
%         else    
%             xtickPositions = 1 : Fs: (xLim(2)+1)*Fs;
%             xLabels = xLim(1):xLim(2);
%         end
% %         
%         % display vertical lines on the plot:
%         for j= 1 : 2: size(xtickPositions, 2)
%             line([xtickPositions(j) xtickPositions(j)], [1 i*50+50], 'LineStyle', '--', 'Color', [0 0 0])
%         end         
%         set(gca,'xTick', xtickPositions, 'xTickLabel', xLabels);
%         plot_modifiedSignal()
% end
% function plot_modifiedSignal()
%         figure(signalFigure) 
%         % setting up channels labels and y=ticks positions
%         for i=1:length(channelsToPlot)
%             if sum(~isnan(modifiedData(channelsToPlot(i),xLim(1)*Fs:xLim(2)*Fs))) > 0
%                 plot(modifiedData(channelsToPlot(i),xLim(1)*Fs:xLim(2)*Fs)*amplitudeScale+i*50, 'r') ;           
%                 hold on;                   
%             end
%         end
% end
% function SCROLL_PLOT(hObj, event)
%         tag=get(hObj, 'Tag');        
%         if tag=='3'
%             if xLim(1)>1
%                 xLim=xLim-scroll_length;
%                 screen = screen-1;
%             else
%                 beep
%             end            
%         elseif tag=='4'
%             if (xLim(2)+scroll_length)*Fs < size(EEG.data,2)*size(EEG.data, 3)
%                 xLim=xLim+scroll_length;
%                 screen = screen+1;
%             else
%                 beep
%             end
%         end
%         cla
%         plot_signal()
%         plot_modifiedSignal()
%         
% end
% function REMOVE(hObj, event)
%         winrej(isnan(winrej)) = 0;
% 
%         for chan = 1:EEG.nbchan            
%            EEG.data(chan, :,  find(winrej(chan, :))) = NaN;
%            if isfield(EEG, 'fft')
%                 EEG.fft.fft_absolutePower_all(chan, :,  find(winrej(chan, :))) = NaN;
%            end
%         end        
%         close(signalFigure)
%         
% end
% function ButtonDownFcnCallback(x, ~)
%     C = get(gca, 'CurrentPoint');
%     x = C(1,1);
%     y = C(1,2);
%     
%     % get clicked trial and channel
%     sec = round(x/Fs);    
%     if screen > 1
%         sec =  round(x/Fs) + (screen-1)*450;
%     end
%     
%     selectedEpoch = ceil(sec/(trialLength/EEG.srate));
%     selectedChannel = ceil((y-25)/50);
%     
%     % update array defining which trials should be excluded
%     if isnan(winrej(selectedChannel, selectedEpoch))
%         winrej(selectedChannel, selectedEpoch) = 1;
%         modifiedData(selectedChannel, :, selectedEpoch) = EEG.data(selectedChannel, :, selectedEpoch);
%     else
%         winrej(selectedChannel, selectedEpoch) = NaN;
%         modifiedData(selectedChannel, :, selectedEpoch) = nan(1, EEG.pnts);
%     end
%     
%     plot_signal()
% end
% 
% 
% 
% end

function EEG = removeEpochs_singleChannel(EEG, varargin)
% TODO
% dodać opcje zmiany skali amplitudy sygnalu  - amplitudeScale

p = inputParser;
p.addRequired('EEG');
p.addParameter('channelsToPlot', {EEG.chanlocs.labels});
p.addParameter('channelsOfInterest','0');
p.addParameter('howManyEpochsToDisplay',15);
p.addParameter('colorOfChannelsInterest',[0, 1, 0]);
p.addParameter('defaultColor',[0, 0, 0]);
p.addParameter('whatToPlot','data');
p.addParameter('amplitudeScale',0.1);
p.addParameter('fft_freq_range',[1 30]);
p.addParameter('plotEvents', false);
p.addParameter('line_colors_and_styles', {});
p.addParameter('clean_signal_max_amplitude', [0, 0]);
p.parse(EEG, varargin{:});

channelsToPlot          = 1:length(p.Results.channelsToPlot);
channelsLabels          = p.Results.channelsToPlot;
channelsOfInterest      = p.Results.channelsOfInterest;
colorOfInterest         = p.Results.colorOfChannelsInterest;
defaultColor            = p.Results.defaultColor;
howManyEpochsToDisplay  = p.Results.howManyEpochsToDisplay;
amplitudeScale          = p.Results.amplitudeScale;
plotEvents              = p.Results.plotEvents;
line_colors_and_styles  = p.Results.line_colors_and_styles;
clean_signal_max_amplitude = p.Results.clean_signal_max_amplitude;

events                  = {EEG.event.type};
xtickPositions          = [];
xLabels                 = {};
selectedEpoch           = [];
selectedChannel         = [];
screen                  = 1;
winrej                  = nan(EEG.nbchan, EEG.trials);
modifiedData            = nan(size(EEG.data));


if isequal(p.Results.whatToPlot, 'data')
    dataToPlot = EEG.(p.Results.whatToPlot)*-1;
    Fs = EEG.srate;
    
elseif isequal(p.Results.whatToPlot, 'fft')
    dataToPlot = abs(EEG.fft.fft_absolutePower_all)*-1;
    freqs1 = EEG.fft.fft_freqs >= p.Results.fft_freq_range(1);
    freqs2 = EEG.fft.fft_freqs < p.Results.fft_freq_range(2);
    dataToPlot = dataToPlot(:, find(freqs1 .* freqs2), :);
    Fs = EEG.srate*size(dataToPlot, 2)/EEG.pnts;
end
epochLength = size(dataToPlot, 2);
xLim = [1, howManyEpochsToDisplay*epochLength]; 
scroll_length  = howManyEpochsToDisplay*epochLength;
EEG_event_types = {EEG.event.type};
EEG_event_latency = {EEG.event.latency};

%% CREATE THE FIGURE
signalFigure = createFigureToPlotSignal();
set(signalFigure, 'WindowButtonDownFcn', @ButtonDownFcnCallback)

plot_signal()

%% Add buttons

uiwait(signalFigure)

function signalFigure = createFigureToPlotSignal()  
        signalFigure= figure();
        h1=uicontrol('Style', 'pushbutton' , 'Max', 0,'Tag', '2',...
           'String', 'REMOVE','Units', 'normalized',...
           'Position', [0.35 0 0.3 0.07],'BackgroundColor', [0.5, 0.5, 0.5],...
           'Callback', {@REMOVE});  
        h2=uicontrol('Style', 'pushbutton' , 'Max', 0,'Tag', '3',...
           'String', '<<','Units', 'normalized',...
           'Position', [0.248 0 0.1 0.07],'BackgroundColor', [0.3, 0.3, 0.3],...
           'Callback', {@SCROLL_PLOT});  

        h3=uicontrol('Style', 'pushbutton' , 'Max', 0,'Tag', '4',...
           'String', '>>','Units', 'normalized',...
           'Position', [0.652 0 0.1 0.07],'BackgroundColor', [0.3, 0.3, 0.3],...
           'Callback', {@SCROLL_PLOT}); 
       
        axes('position',[0.03 0.1 0.96 0.9]) % [left, bottom, width, height]
                
        % setting up channels labels and ticks positions
        ytickPositions = 50* (1:length(channelsToPlot)); 
        ylim([ytickPositions(1)-50, ytickPositions(end)+50]);

        set(gca,'yTick', ytickPositions, 'yTickLabel', channelsLabels);
        set(gca, 'FontWeight', 'bold', 'FontSize', 12)
        set( gca, 'YDir', 'reverse' )
end
function plot_signal()
        figure(signalFigure)    
        cla      
        
        % Draw signal
        for i=1:length(channelsToPlot)
            hold on;
            if ismember(i, channelsOfInterest)
                plot(dataToPlot(channelsToPlot(i), xLim(1):xLim(2))*amplitudeScale+i*50, 'color', colorOfInterest,'LineWidth', 2)
            else
                plot(dataToPlot(channelsToPlot(i), xLim(1):xLim(2))*amplitudeScale+i*50, 'color', defaultColor,'LineWidth', 1)
            end    
        end        
        
                    
        % Display horizontal line of the maximal signal amplitude (to
        % detect noise easier)
        for i=1:length(channelsToPlot)
            if clean_signal_max_amplitude(1) < 0
                line_location = clean_signal_max_amplitude(1) * amplitudeScale+i*50 ;
                line(get(gca, 'XLim'), [line_location, line_location], 'LineStyle', '--', 'Color', [0.8 0.8 0.8])
            end
            if clean_signal_max_amplitude(2) > 0
                line_location = clean_signal_max_amplitude(2) * amplitudeScale+i*50 ;
                line(get(gca, 'XLim'), [line_location, line_location], 'LineStyle', '--', 'Color', [1 0 0])
            end
        end
            
        xtickPositions = 1 : epochLength/2 : scroll_length;
        xLabels = repmat({'0'}, 1, size(xtickPositions, 2));
        for i =1:howManyEpochsToDisplay
%             xLabels{i*2-1} = events{ceil(xLim(1) / epochLength):xLim(2) / epochLength};
            xLabels{i*2-1} = '';
            xLabels{i*2} = i+round(xLim(1) / epochLength);
        end  
        % display vertical lines on the plot:
        for j= 1 : 2: size(xtickPositions, 2)
            line([xtickPositions(j) xtickPositions(j)], get(gca, 'YLim'), 'LineStyle', '--', 'Color', [0 0 0])
        end
        set(gca,'xTick', xtickPositions, 'xTickLabel', xLabels);

        % Display events
        if plotEvents
            ylim = get(gca, 'YLim');
            for e = 1:length(EEG_event_types)
                if (EEG_event_latency{e} >= xLim(1)) && (EEG_event_latency{e} <= xLim(2))
                    event_line_xpos = EEG_event_latency{e} - xLim(1);
                    if isfield(line_colors_and_styles, EEG_event_types{e})
                        linestyle = line_colors_and_styles.(EEG_event_types{e}).linestyle;
                        color = line_colors_and_styles.(EEG_event_types{e}).color;
                    else
                        linestyle = '-';
                        color = [0 0 0];
                    end
                    line([event_line_xpos event_line_xpos], ylim, 'LineStyle', linestyle, 'Color', color)
                    text(event_line_xpos, ylim(2)*0.1, EEG_event_types{e});
                end
            end
        end

        
        
        plot_modifiedSignal()
end
function plot_modifiedSignal()
        figure(signalFigure) 
        % setting up channels labels and y=ticks positions
        for i=1:length(channelsToPlot)
            if sum(~isnan(modifiedData(channelsToPlot(i),xLim(1):xLim(2)))) > 0
                plot(modifiedData(channelsToPlot(i),xLim(1):xLim(2))*amplitudeScale+i*50, 'r') ;           
                hold on;                   
            end
        end
end
function SCROLL_PLOT(hObj, event)
        tag=get(hObj, 'Tag');        
        if tag=='3'
            if xLim(1)>1
                xLim=xLim-scroll_length;
%                 screen = screen-1;
            else
                beep
            end            
        elseif tag=='4'
            if (xLim(2)+scroll_length) <= size(dataToPlot,2)*size(dataToPlot, 3)
                xLim=xLim+scroll_length;
%                 screen = screen+1;
            else
                beep
            end
        end
        cla
        plot_signal()
%         plot_modifiedSignal()
        
end
function REMOVE(hObj, event)
        winrej(isnan(winrej)) = 0;

        for chan = 1:EEG.nbchan            
           EEG.data(chan, :,  find(winrej(chan, :))) = NaN;
           if isfield(EEG, 'fft')
                EEG.fft.fft_absolutePower_all(chan, :,  find(winrej(chan, :))) = NaN;
           end
        end        
        close(signalFigure)
        
end
function ButtonDownFcnCallback(x, ~)
    C = get(gca, 'CurrentPoint');
    x = C(1,1);
    y = C(1,2);
    
    % get clicked trial and channel
    sec = round(x);    
    selectedEpoch = ceil(sec / epochLength)+ ceil(xLim(1) / epochLength)-1;
    selectedChannel = ceil((y-25)/50);
    
    % update array defining which trials should be excluded
    if isnan(winrej(selectedChannel, selectedEpoch))
        winrej(selectedChannel, selectedEpoch) = 1;
        modifiedData(selectedChannel, :, selectedEpoch) = dataToPlot(selectedChannel, :, selectedEpoch);
    else
        winrej(selectedChannel, selectedEpoch) = NaN;
        modifiedData(selectedChannel, :, selectedEpoch) = nan(1, EEG.pnts);
    end
    plot_signal()
end



end

