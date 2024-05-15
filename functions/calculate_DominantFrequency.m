function EEG = calculate_DominantFrequency(EEG, sleepPhases)

for i = 1:length(sleepPhases)
    power_abs = EEG.fft.(sleepPhases{i}).absolutePower;
    power_relat = EEG.fft.(sleepPhases{i}).relativePower;

    % calculate df
    [val, indx] = max(power_abs,[], 2, 'omitnan');
    EEG.fft.(sleepPhases{i}).DF_absolute  = EEG.fft.fft_freqs(indx);

    [val, indx] = max(power_relat,[], 2, 'omitnan');
    EEG.fft.(sleepPhases{i}).DF_relative  = EEG.fft.fft_freqs(indx);


end
end
