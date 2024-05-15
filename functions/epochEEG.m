function epochEEG(datafiles, datapath, EEGevents,epochLen)



toSavePath = fullfile(datapath, 'Segmented'); mkdir(toSavePath);


for p = 1:length(datafiles)
    if strfind(datafiles{p}, '.set')
        cprintf([0,1,0], "Segmenting file::%s \n", fullfile(datapath, datafiles{p}))    

        EEG = pop_loadset('filename',datafiles(p),'filepath',datapath);
        if ismember('N4', unique({EEG.event.type}))
            for i=1:length({EEG.event.type})
                if isequal(EEG.event(i).type, 'N4')
                    EEG.event(i).type = 'N3';
                end
            end
        end
                
%         EEG = pop_epoch( EEG, SETTINGS.sleepPhases, [-SETTINGS.epochLen 0], 'epochinfo', 'yes');
        EEG = pop_epoch( EEG, EEGevents, [0, epochLen], 'epochinfo', 'yes');
        EEG.sleepPhases = EEGevents;
        
        
        % events are every 30s, so one epoch contains two events (1st 0 and 30s). Reject first event
        % in each epoch:
        EEG.event = EEG.event(2:2:end);

        % Count epochs for each sleep phase
        EEG.epochNum = countEpochs(EEG, EEGevents);
        

        if ~isfield(EEG, 'information')
            EEG.information = {};
        end
        EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), '| Segmented'];  

        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',datafiles{p},'filepath',toSavePath);
        cprintf([0,1,0], "Segmented EEG saved to:%s \n", fullfile(toSavePath, datafiles{p}))    

    end
end

end
