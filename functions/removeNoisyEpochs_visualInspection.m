function removeNoisyEpochs_visualInspection(datafiles, datapath, ...
                                            remove_mode,...
                                            amplitudeToDisplay, ...
                                            numOfEpochsToDisplay, ...
                                            clean_signal_max_amplitude)


    toSavePath = fullfile(datapath, sprintf('NoisyEpochsRejected_visualInspection_%s', remove_mode)); mkdir(toSavePath);
    line_colors_and_styles = {};
    for p = 1:length(datafiles)
        if strfind(datafiles{p}, '.set')
            EEG = pop_loadset('filename',datafiles(p),'filepath',datapath);
            cprintf([0,1,1], 'Processing file: %s \n', datafiles{p})
            % display some infos
            cprintf([0,1,1], 'List of events in the data:\n')
            for event =  unique({EEG.event.type})
                cprintf([0,1,1], strcat('\t\t -', event{1}, '\n'))
            end
            
            %% prepare EEG.events to display with FFT
            try 
            fftToPlot = EEG.fft.fft_absolutePower_all(:, 1:ceil(size(EEG.fft.fft_absolutePower_all, 2)/4), :);
            x= EEG.pnts / size(fftToPlot,2);
            fftEvents = EEG.event;
            for i = 1:length(fftEvents)
                fftEvents(i).latency = fftEvents(i).latency / x;
            end   
             eegplot(abs(fftToPlot),  'eloc_file',EEG.fft.channels,...
                                   'butlabel','Reject', ...
                                   'wincolor', [1, 0.7, 0.7],...
                                   'spacing',   amplitudeToDisplay*2, ...
                                   'winlength', numOfEpochsToDisplay,...
                                   'events', fftEvents)
            end


            if isequal(remove_mode, 'single_channel')
                EEG = removeEpochs_singleChannel(EEG, 'plotEvents', true, ...
                    'line_colors_and_styles', line_colors_and_styles, ...
                    'clean_signal_max_amplitude', clean_signal_max_amplitude);
                EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), '| Visual inspection. Removed data at individual channels per epoch.'];  

            elseif isequal(remove_mode, 'entire_epoch')
                cmd = ['disp(1)'];
                eegplot(EEG.data,  'eloc_file',EEG.chanlocs,...
                               'butlabel','Reject', ...
                               'command', cmd,...
                               'wincolor', [1, 0.7, 0.7],...
                               'spacing',   amplitudeToDisplay, ...
                               'winlength', numOfEpochsToDisplay,...
                               'events', EEG.event, ...
                               'srate', EEG.srate);
                uiwait(gcf)
                try
                    tmprej = eegplot2trial(evalin('base', 'TMPREJ'), EEG.pnts, EEG.trials);
                catch
                    tmprej = [];
                end
                % toExclude = find(tmprej);
                % for i = 1:length(toExclude)
                %     EEG.data(:, :, toExclude(i)) = NaN(EEG.nbchan, EEG.pnts);
                % end
                EEG = pop_rejepoch(EEG, tmprej ,0);
                EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), '| Visual inspection. Removed entire epochs.'];  

            end

%             EEG.badEpochs = tmprej;     

            % Count non-nan epochs for each sleep phase
            EEG.epochNum = countEpochs(EEG, EEG.sleepPhases);
            % 
            EEG = eeg_checkset( EEG );
            EEG = pop_saveset( EEG, 'filename', datafiles{p},'filepath',toSavePath);
            cprintf([0,1,0], "Cleaned EEG saved to:%s \n", fullfile(toSavePath, datafiles{p}))    
        end
    end
end