function FFT_Welch(datafiles, datapath, ...
                   FFT_winlen, ...
                   freq_bands)


toSavePath = fullfile(datapath, 'EEG_power');
mkdir(toSavePath);
   
    
for p = 1:length(datafiles)
    if strfind(datafiles{p}, '.set')
        cprintf([0,1,0], "Computing power for: %s \n", fullfile(datapath, datafiles{p}))    
        EEG = pop_loadset('filename',datafiles(p),'filepath',datapath);
        if ~isfield(EEG, 'sleepPhases')
            errmsg = sprintf('Cannot compute power. Run EEG segmentation first. (Tab: "Segment") \n Subject: %s ', datafiles{p});
            uiwait(errordlg(errmsg))
            continue
        end
        channels = {EEG.chanlocs.labels};
        if isfield(EEG, 'sleepPhases')
            msg = sprintf('The EEG data is missing sleep phases! Maybe the segmentation was not performed?\n Subject: %s', datafiles{p});
            errordlg(msg)
            uiwait;
            return
        end
        sleepPhases = EEG.sleepPhases;
        EEG.frequency_bands = freq_bands;
        %%
        EEG.fft = {};
        [pow,freqs] = pwelch(EEG.data(1, :, 1), ceil(FFT_winlen*EEG.srate), [], [], EEG.srate, 'psd');
        EEG.fft.fft_absolutePower_all = nan(length(channels)+9, length(pow), size(EEG.data, 3));
        EEG.fft.channels = {};        
        % === calculate FFT for each channel and each epoch
        for chan = 1:length(channels)
            chan_label = channels{chan};
            cprintf([0,1,1], '-- Channel %s \n', chan_label)
            chan_num = find(ismember({EEG.chanlocs.labels}, chan_label));
            EEG.fft.channels{chan} = chan_label;
        
            for epoch = 1:size(EEG.data, 3)
                if isempty(chan_num)
                    power = nan(size(pow));
                else
                    if sum(isnan(EEG.data(chan_num, :, epoch))) == EEG.pnts
                        power = nan(size(pow));
                   else
                    [power,freqs] = pwelch(EEG.data(chan_num, :, epoch), ceil(FFT_winlen*EEG.srate), [], [], EEG.srate, 'psd');
                    end
                end
                EEG.fft.fft_absolutePower_all(chan, :, epoch) = power; 
            end
        end
        EEG.fft.fft_freqs = freqs;
        EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), sprintf('| FFT Welch method with window length of %g sec', FFT_winlen)];  
        
        %% === calculate channels averaged over left and right hemisphere
        
        cprintf([0,1,1], '-- Avearaging left/right channels  \n')
        EEG.fft.fft_absolutePower_all(length(channels)+1, :, :) = mean(EEG.fft.fft_absolutePower_all(...
                                                find(ismember(EEG.fft.channels, {'C3', 'C4'})), :, :));
        EEG.fft.channels{end+1} = 'meanC3C4';
        EEG.fft.fft_absolutePower_all(length(channels)+2, :, :) = mean(EEG.fft.fft_absolutePower_all(...
                                                find(ismember(EEG.fft.channels, {'F3', 'F4'})), :, :));
        EEG.fft.channels{end+1} = 'meanF3F4';
        
        EEG.fft.fft_absolutePower_all(length(channels)+3, :, :) = mean(EEG.fft.fft_absolutePower_all(...
                                                find(ismember(EEG.fft.channels, {'O1', 'O2'})), :, :));
        EEG.fft.channels{end+1} = 'meanO1O2'; 
        EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), sprintf('| Averaged power across left and right channels.')];  

        %% === calculate channels divided by sides
        cprintf([0,1,1], '-- Calculatig left over right ratio\n')
        c3 = EEG.fft.fft_absolutePower_all(find(ismember(EEG.fft.channels, {'C3'})), :, :);
        c4 = EEG.fft.fft_absolutePower_all(find(ismember(EEG.fft.channels, {'C4'})), :, :);
        
        f3 = EEG.fft.fft_absolutePower_all(find(ismember(EEG.fft.channels, {'F3'})), :, :);
        f4 = EEG.fft.fft_absolutePower_all(find(ismember(EEG.fft.channels, {'F4'})), :, :);
        
        o1 = EEG.fft.fft_absolutePower_all(find(ismember(EEG.fft.channels, {'O1'})), :, :);
        o2 = EEG.fft.fft_absolutePower_all(find(ismember(EEG.fft.channels, {'O2'})), :, :);
        
        
        EEG.fft.fft_absolutePower_all(length(channels)+4, :, :) = c3./c4 ;
        EEG.fft.channels{end+1} = 'C3overC4';
        EEG.fft.fft_absolutePower_all(length(channels)+5, :, :) = c4./c3 ;
        EEG.fft.channels{end+1} = 'C4overC3';
        
        EEG.fft.fft_absolutePower_all(length(channels)+6, :, :) = f3./f4 ;
        EEG.fft.channels{end+1} = 'F3overF4';
        EEG.fft.fft_absolutePower_all(length(channels)+7, :, :) = f4./f3 ;
        EEG.fft.channels{end+1} = 'F4overF3';

        EEG.fft.fft_absolutePower_all(length(channels)+8, :, :) = o1./o2 ;
        EEG.fft.channels{end+1} = 'O1overO2';
        EEG.fft.fft_absolutePower_all(length(channels)+9, :, :) = o2./o1 ;
        EEG.fft.channels{end+1} = 'O2overO1';
        EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), sprintf('| Calculated left-over-right channels ratio')];  

        %% === Calculate slow-to-fast ratio([delta + theta]/[ alpha + beta])
        cprintf([0,1,1], '-- Calculating slow-to-fast ratio ([delta + theta]/[ alpha + beta]) \n')
                    
        delta_indx = find((EEG.fft.fft_freqs > freq_bands.delta(1)) .* (EEG.fft.fft_freqs <= freq_bands.delta(2)));
        theta_indx = find((EEG.fft.fft_freqs > freq_bands.theta(1)) .* (EEG.fft.fft_freqs <= freq_bands.theta(2)));
        alpha_indx = find((EEG.fft.fft_freqs > freq_bands.alpha(1)) .* (EEG.fft.fft_freqs <= freq_bands.alpha(2)));
        beta_indx  = find((EEG.fft.fft_freqs > freq_bands.beta(1))  .* (EEG.fft.fft_freqs <= freq_bands.beta(2)));
        
        slow = mean(EEG.fft.fft_absolutePower_all(:, delta_indx, :), 2) + ...
               mean(EEG.fft.fft_absolutePower_all(:, theta_indx, :), 2);

        fast = mean(EEG.fft.fft_absolutePower_all(:, alpha_indx, :), 2) + ...
               mean(EEG.fft.fft_absolutePower_all(:, beta_indx, :), 2);
        EEG.fft.slow_to_fast =     slow ./ fast;
        EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), sprintf('|Calculated slow-to-fast ratio ([delta + theta]/[ alpha + beta])')];  
        
        %% === average FFT for each sleep phase separatelEEG.epochNum.(phase{1})(channel)y
        cprintf([0,1,1], '-- Averaging power for each sleep phase \n')
        EEG = averageFFT(EEG, sleepPhases);
        EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), sprintf('| Averaged power in each sleep phase')];  

       
        %% === calculate relative power - power/sum(power) for each sleep phase
        cprintf([0,1,1], '-- Calculating relative power [%%] \n')
        EEG = calculateRelativePower(EEG, sleepPhases);
        EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), sprintf('| Calculated relative power')];  

        %% === log-transform
        cprintf([0,1,1], '-- Calculating log transform \n')
        EEG = log_transform_fft(EEG);
        EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), sprintf('| Calculated log(power)')];  


        
        %% === Calculate dominant frequency (DF) for each channel
        cprintf([0,1,1], '-- Calculating dominant frequency\n')
        EEG = calculate_DominantFrequency(EEG, sleepPhases);
        EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), sprintf('| Calculated dominant frequency')];  

        %% === calculate mean and max power for each frequency band
        cprintf([0,1,1], '-- Calculating power for each frequency band\n')
        EEG = calculatePowerForEachBand(EEG, sleepPhases, freq_bands);
        EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), sprintf('| Calculated power in each frequency band')];  

        %% === Save the dataset
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',datafiles{p},'filepath',toSavePath);
        cprintf([0,1,0], "EEG power saved to:%s \n", fullfile(toSavePath, datafiles{p}))    

    
    end
end
end