function saveBandsPowerToFile_wideFormat(datapath, ...
                              mean_or_max, ...
                              absoluteOrRelative)

    toSavePath = fullfile(datapath, sprintf('RESULTS_%s_power_%s_wideFormat.csv', mean_or_max, absoluteOrRelative));
    filenames = dir(fullfile(datapath, '*.set'));
    datatable = table();
   
   
    %%  Fill the datatable    
    for p = 1:length(filenames)
        if strfind(filenames(p).name, '.set')
            if ismember('filename', datatable.Properties.VariableNames)
                datatable.filename(end+1) = {filenames(p).name};
            else
                datatable = addvars(datatable, {filenames(p).name}, 'NewVariableNames', 'filename');
            end
            cprintf([0,1,1], 'Participant: %s \n', filenames(p).name)
            EEG = pop_loadset('filename',filenames(p).name,'filepath', datapath);
            channel_names = EEG.fft.channels;
            sleepPhases = EEG.sleepPhases;
            bands = fieldnames(EEG.frequency_bands);
            

            
            % write power values
            for phase = sleepPhases
                for band = bands'
                    power = EEG.fft.(phase{1}).(sprintf('%s_%sPower',absoluteOrRelative, mean_or_max)).(band{1});
                    for chan = 1:length(channel_names)
                        colname = sprintf('Power_%s_%s_%s_%s', phase{1}, band{1}, channel_names{chan}, absoluteOrRelative);
                        if ismember(colname, datatable.Properties.VariableNames)
                            datatable.(colname)(end) = power(chan);
                        else
                            datatable = addvars(datatable, power(chan), 'NewVariableNames', colname);          
                        end
                    end
                end
            end
            
            % write number of used epochs
            for phase = sleepPhases
                for chan = 1:length(channel_names)
                    chan_num = find(ismember({EEG.chanlocs.labels}, channel_names(chan)));
                    if ~isempty(chan_num)
                        colname = sprintf('NumEpochsIncluded_%s_%s', phase{1}, channel_names{chan});
                        if ismember(colname, datatable.Properties.VariableNames)
                            datatable.(colname)(end) = EEG.epochNum.(phase{1}).(channel_names{chan});
                        else
                            datatable = addvars(datatable, EEG.epochNum.(phase{1}).(channel_names{chan}), 'NewVariableNames', colname);    
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
