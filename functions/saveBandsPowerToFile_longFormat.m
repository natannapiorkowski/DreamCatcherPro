function saveBandsPowerToFile_longFormat(datapath, ...
                                         mean_or_max, ...
                                         absoluteOrRelative)
    
    
    toSavePath = fullfile(datapath, sprintf('RESULTS_%s_power_%s_longFormat.csv', mean_or_max, absoluteOrRelative));
    filenames = dir(fullfile(datapath, '*.set'));

    columnNames = {'filename', 'channel', 'sleep_stage', 'frequency_band', 'EEG_power'};
    coltypes =    {'string',   'string',  'string'     , 'string',        'double'};
    datatable  = table('Size', [0, numel(columnNames)], 'VariableNames', columnNames, 'VariableTypes', coltypes);


    for p = 1:length(filenames)
        if strfind(filenames(p).name, '.set')
            cprintf([0,1,1], 'Participant: %s \n', filenames(p).name)
            EEG = pop_loadset('filename',filenames(p).name,'filepath',datapath);
            channel_names = EEG.fft.channels;
            sleepPhases = EEG.sleepPhases;
            bands = fieldnames(EEG.frequency_bands);
            for phase = sleepPhases
                for band = bands'
                    for chan = 1:length(channel_names)
                        power_fieldname = sprintf('%s_%sPower', absoluteOrRelative, mean_or_max);
                        if ~isempty(EEG.fft.(phase{1}).(power_fieldname).(band{1}))
                            filename = sprintf('%s', strrep(filenames(p).name, '.set',''));
                            channel = channel_names{chan};
                            sleep_stage = phase{1};
                            frequency_band = band;
                            EEG_power = EEG.fft.(phase{1}).(power_fieldname).(band{1})(chan);

                            newRow = {filename, channel, sleep_stage, frequency_band, EEG_power};

                            datatable = [datatable; newRow];
                        else
                            pass
                            cprintf([1,0,0], 'Empty: phase: %s, band: %s, channel %s\n', phase{1}, bands{band}, channel_names{chan})
                        end
                    end
                end
            end

        end    
    end


%%  Save data to csv file

% Save the table to a CSV file
writetable(datatable, toSavePath);
    
end