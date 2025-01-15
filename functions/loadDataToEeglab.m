function loadDataToEeglab(datafolders, datapath, channels_to_load)

% DATA_PATH = uigetdir(pwd, 'Select a directory containing EEG data files');
toSavePath = uigetdir(pwd, 'Select or create a directory to save eeglab compatibile data');


%%


for p = 1:length(datafolders)
    % list all files belonging to the current participant
    datafiles = dir(fullfile(datapath, datafolders{p}));
    if contains(datafolders(p), '.zip')
        continue
    end

    %% Load EEG data
    cprintf([0,1,0], "Step 1: Loading EEG data from: %s \n", fullfile(datapath, datafolders{p}))    
    EEG = eeg_emptyset();
    containsAllowedChannels = cellfun(@(file) any(contains(file, channels_to_load)), {datafiles.name});
    matchingFiles = datafiles(containsAllowedChannels);
    
    for f = {matchingFiles.name}
        % Use cellfun to check if each channel is contained in the input string
        chanlabel = channels_to_load(cellfun(@(channel) contains(f, channel), channels_to_load));
        chanlabel = chanlabel{1};

        EEG = addEEGData(EEG, fullfile(datapath, datafolders{p}, f{1}), chanlabel);
    end


    %% Merge all events into a single csv file:
    cprintf([0,1,0], "Step 2: Exporting EEG events from txt to a csv file\n", datapath)  
    allowed_event_files = {"Flow Events", "Klassifizierte Arousal", "Körperlage", "PLM Events", "Schlafprofil", "Schnarchen Events"};
    for event_file_type = allowed_event_files
        f = cellfun(@(name) contains(name, event_file_type{1}), {datafiles.name});
        
        % Check if given event file exists. If not, print an error and skip
        % loop iteration
        if ~any(f)
            cprintf([1,0,0], "\tERROR! Could not find an events file: '%s'\n", event_file_type{1})
            continue
        end

        events_file = fullfile(datafiles(f).folder, datafiles(f).name);
        if isfile(events_file)
            cprintf([0,1,0], "\tExporting '%s' events to csv\n", event_file_type{1})
            exportEventsToCsv(EEG, events_file, datafiles(f).folder)
        end
    end

    %% Load events to the EEG struct
    cprintf([0,1,0], "Step 3: Merging EEG data with the events\n")  
    
    try 
        EEG = pop_importevent(EEG, 'event', fullfile(datapath, datafolders{p}, 'Events.csv'),'fields',{'latency' 'type' 'duration'},'skipline',1,'timeunit',1);
        cprintf([0,1,0], "\t Yay! Added events to the EEG struct\n")
    catch
        cprintf([1,0,0], "\tFailed to load Events.csv! \n")
    end

    %% save EEGLAB set
    EEG = eeg_checkset( EEG );
    if ~isfield(EEG, 'information')
        EEG.information = {};
    end
    EEG.information{end+1} = [datestr(now, 'yyyy-mm-dd HH:MM:SS'), '| Data loaded from txt files to eeglab from ', fullfile(datapath, datafolders{p})];
    EEG = pop_saveset( EEG, 'filename', datafolders{p},'filepath', toSavePath);
    clear('EEG')
    cprintf([0,1,0], "Done! EEG datafile was saved to: %s\n\n\n", fullfile(toSavePath, strcat(datafolders{p}, ".set")))

end


