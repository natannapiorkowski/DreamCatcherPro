function EEG = log_transform_fft(EEG)

	sleepPhases  = EEG.sleepPhases;

    EEG.fft.fft_absolutePower_all = log(EEG.fft.fft_absolutePower_all);
    
    for i = 1:length(sleepPhases)
        EEG.fft.(sleepPhases{i}).absolutePower = log(EEG.fft.(sleepPhases{i}).absolutePower);
        EEG.fft.(sleepPhases{i}).relativePower = log(EEG.fft.(sleepPhases{i}).relativePower);
        EEG.fft.(sleepPhases{i}).slow_to_fast  = log( EEG.fft.(sleepPhases{i}).slow_to_fast);

    end
end