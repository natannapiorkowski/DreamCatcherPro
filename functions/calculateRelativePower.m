function EEG = calculateRelativePower(EEG, sleepPhases)
% calculate power/sum(power) for each channel


    for e=1:length(sleepPhases)
        p = EEG.fft.(sleepPhases{e}).absolutePower;

        for i=1:size(p, 1)
            p(i,:) =  100*p(i,:) ./ sum(p(i,:));
        end
        EEG.fft.(sleepPhases{e}).relativePower = p;


    end
end