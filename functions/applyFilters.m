function applyFilters(datafiles, datapath, highpass_cutoff, highpassorder, lowpass_cutoff, lowpassorder)

toSavePath = fullfile(datapath, sprintf('Filter_%g_%g', highpass_cutoff, lowpass_cutoff));
mkdir(toSavePath);

    
for p = 1:length(datafiles)
    if strfind(datafiles{p}, '.set')
        cprintf([0,1,0], "Filtering file %s \n", fullfile(datapath, datafiles{p}))    

        EEG = pop_loadset('filename',datafiles(p),'filepath',datapath);
    
        if ~isempty(lowpass_cutoff)
            try
                EEG  = pop_basicfilter(EEG,[1:size(EEG.data,1)], ...
                                       'Filter','lowpass', ...
                                       'Design','butter', ...
                                       'Cutoff',lowpass_cutoff,...
                                       'Order',lowpassorder, ...
                                       'RemoveDC', 'off');
            catch
                EEG  = pop_eegfiltnew(EEG, [],lowpass_cutoff,320,0,[],0);
            end
        end

        if ~isempty(highpass_cutoff)
            try
                EEG  = pop_basicfilter(EEG,[1:size(EEG.data,1)], ...
                                       'Filter','highpass', ...
                                       'Design','butter', ...
                                       'Cutoff',highpass_cutoff,...
                                       'Order',highpassorder, ...
                                       'RemoveDC', 'off');
            catch
                EEG  = pop_eegfiltnew(EEG, highpass_cutoff,[],846,0,[],0);
            end
        end

        if ~isfield(EEG, 'information')
            EEG.information = {};
        end
        EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), sprintf('| Filter_%g_%g', highpass_cutoff, lowpass_cutoff)];  
        EEG = eeg_checkset( EEG );
        EEG = pop_saveset( EEG, 'filename',datafiles{p},'filepath',toSavePath);
        cprintf([0,1,0], "Filtered EEG saved to:%s \n", fullfile(toSavePath, datafiles{p}))    

    end

end
end
