function EEG = averageFFT(EEG, sleepPhases)


for i = 1:length(sleepPhases)
    epochsToInclude = zeros(1, EEG.trials);
    for t = 1:EEG.trials
        if isequal(EEG.epoch(t).eventtype{1}, sleepPhases{i})
            epochsToInclude(t) = 1;
        end
    end
    
    if sum(epochsToInclude) == 0
        fft_av = [];
    else
        fft_av          = mean(EEG.fft.fft_absolutePower_all(:,:, find(epochsToInclude)), 3, 'omitnan');
        slow_to_fast_av = mean(EEG.fft.slow_to_fast(:,:, find(epochsToInclude)), 3, 'omitnan');
    end
    EEG.fft.(sleepPhases{i}).absolutePower = fft_av;
    EEG.fft.(sleepPhases{i}).slow_to_fast  = slow_to_fast_av;
    
    % calculate df
    [val, indx] = max(fft_av,[],2, 'omitnan');
    EEG.fft.(sleepPhases{i}).DF_absolute  = EEG.fft.fft_freqs(indx);
end




end