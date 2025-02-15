function epochNum = countEpochs(EEG, EEGevents)
    channels = {EEG.chanlocs.labels};
    epochNum = {}; 
%     events = {EEG.event.type};
    events = {};

    for i = {EEG.epoch.eventtype}
        if ~isempty(i{1})
            if ischar(i{1})
                events{end+1} = i{1};
            else
                events{end+1} = i{1}{1};
            end
        end
    end


    for phase = 1:length(EEG.sleepPhases)
        currPhase = find(ismember(events, EEGevents{phase}));
        % count not nan epochs for each channel separately
        
        for chan=channels
            chan_num = find(ismember({EEG.chanlocs.labels}, chan));
            if isempty(chan_num)
                epochNum.(EEGevents{phase}).(chan{1}) = 0;
            else
                epochNum.(EEGevents{phase}).(chan{1}) = sum(~isnan(EEG.data(chan_num, 1, currPhase)), 3)';
            end
        end
%         epochNum.(SETTINGS.sleepPhases{phase}) = length(currPhase);
    end
    
    
end
