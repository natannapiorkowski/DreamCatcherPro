function reference_data(datafiles, datapath, reference_channels)


    toSavePath = fullfile(datapath, sprintf('Rereferenced_to_%s', strjoin(reference_channels)));
    mkdir(toSavePath);

    
    for p = 1:length(datafiles)
        if strfind(datafiles{p}, '.set')
            cprintf([0,1,0], "Loading EEG data from: %s \n", fullfile(datapath, datafiles{p}))    

            EEG = pop_loadset('filename',datafiles{p},'filepath',datapath);
            EEG = pop_reref( EEG, reference_channels);
    
            if ~isfield(EEG, 'information')
                EEG.information = {};
            end
            EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), sprintf('| Rereferenced to %s',  strjoin(reference_channels))]; 
            EEG = eeg_checkset( EEG );
            EEG = pop_saveset( EEG, 'filename',datafiles{p},'filepath',toSavePath);
            cprintf([0,1,0], "Re-referenced EEG saved to:%s \n", fullfile(toSavePath, datafiles{p}))    
        end
    end
end

