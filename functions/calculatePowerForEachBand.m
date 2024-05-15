function EEG = calculatePowerForEachBand(EEG, sleepPhases, bands)

    bandsNames   = fieldnames(bands);
    for i = 1:length(sleepPhases)
        for band = 1:length(bandsNames)
            freqRange = bands.(bandsNames{band});
            freqs1 = EEG.fft.fft_freqs >= freqRange(1);
            freqs2 = EEG.fft.fft_freqs < freqRange(2);
            bandFreqsIndx = find(freqs1 .* freqs2);
            
            % save mean absolute power values
            p_absolute = EEG.fft.(sleepPhases{i}).absolutePower;
            if ~isempty(p_absolute)
                meanPowerWithinBand = mean(p_absolute(:,bandFreqsIndx),2);
                maxPowerWithinBand  = max(p_absolute(:,bandFreqsIndx),[], 2);
                
                EEG.fft.(sleepPhases{i}).absolute_meanPower.(bandsNames{band}) = meanPowerWithinBand;
                EEG.fft.(sleepPhases{i}).absolute_maxPower.(bandsNames{band}) = maxPowerWithinBand;
            else
                EEG.fft.(sleepPhases{i}).absolute_meanPower.(bandsNames{band}) = [];
                EEG.fft.(sleepPhases{i}).absolute_maxPower.(bandsNames{band}) = [];
            end
            
            % save mean relative power values
            p_relative = EEG.fft.(sleepPhases{i}).relativePower;
            if ~isempty(p_relative)
                meanPowerWithinBand = mean(p_relative(:,bandFreqsIndx),2);
                maxPowerWithinBand  = max(p_relative(:,bandFreqsIndx),[], 2);
                
                EEG.fft.(sleepPhases{i}).relative_meanPower.(bandsNames{band}) = meanPowerWithinBand;
                EEG.fft.(sleepPhases{i}).relative_maxPower.(bandsNames{band}) = maxPowerWithinBand;
            else
                EEG.fft.(sleepPhases{i}).relative_meanPower.(bandsNames{band}) = [];
                EEG.fft.(sleepPhases{i}).relative_maxPower.(bandsNames{band}) = [];
            end
                
        end
    end
end