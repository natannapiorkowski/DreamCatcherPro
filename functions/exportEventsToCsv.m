function exportEventsToCsv(EEG, events_file, csv_ouput_path)


%%%%%%
    %% First get the beginning of the EEG recording
    EEG_starttimes_labels = fieldnames(EEG.start_time);
    EEG_beginTime = datetime(EEG.start_time.(EEG_starttimes_labels{1}));


    VariableNames = {'latency', 'type', 'duration'};
    
    start_time_pattern = '(\d{2}.\d{2}.\d{4} \d{2}:\d{2}:\d{2})';
    datetime_format = 'dd.MM.yyyy HH:mm:ss,SSS';
    
    % If csv file exist, open it, if not - create a new one
    if isfile(fullfile(csv_ouput_path, "Events.csv"))
        output_df = readtable(fullfile(csv_ouput_path, "Events.csv"));
    else
        output_df = table([], [], [], 'VariableNames', VariableNames);
    end
    
    
    if contains(events_file, 'Flow Events')
        pattern = '(\d{2}.\d{2}.\d{4} \d{2}:\d{2}:\d{2},\d{3})-(\d{2}:\d{2}:\d{2},\d{3}); (\d+);(.*)';
    elseif contains(events_file, 'Klassifizierte Arousal')
        pattern = '(\d{2}.\d{2}.\d{4} \d{2}:\d{2}:\d{2},\d{3})-(\d{2}:\d{2}:\d{2},\d{3}); (\d+);(.*)';
    elseif contains(events_file, "Körperlage")
        pattern = '^(\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}:\d{2},\d{3});\s*(.*)';
    elseif contains(events_file, "PLM Events")
        pattern = '(\d{2}.\d{2}.\d{4} \d{2}:\d{2}:\d{2},\d{3})-(\d{2}:\d{2}:\d{2},\d{3}); (\d+);(.*)';
    elseif contains(events_file, "Schlafprofil")
        pattern = '^(\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}:\d{2},\d{3});\s*(.*)';
    elseif contains(events_file, "Schnarchen Events")
        pattern = '(\d{2}.\d{2}.\d{4} \d{2}:\d{2}:\d{2},\d{3})-(\d{2}:\d{2}:\d{2},\d{3}); (\d+);(.*)';
    end
    
    fileContent = fileread(events_file);
    % Split the content into lines
    lines = strsplit(fileContent, '\n');
    for j = 1:numel(lines)
        if contains(lines{j}, "Start Time")
            matches = regexp(lines{j}, start_time_pattern, 'tokens');
            recordingBeginDateTime= datetime(matches{1}{1});

            % if there is a mismatch between recording begginign in EEG
            % data and in events, calculate a lag
            lag = seconds(recordingBeginDateTime - EEG_beginTime);            
        end
        if ~contains(lines{j}, ";")
            continue
        end
    
        % Use regular expression to match the pattern in the input line
        matches = regexp(lines{j}, pattern, 'tokens');
        % Extract the parsed values
        date = matches{1}{1};
        % Split dateBegin into "date" and "beginTime"
        [date, beginTime] = strtok(date);
        beginTime = strcat(date, beginTime);
        if length(matches{1}) == 2
            event_label = strtrim(matches{1}{2});
            endTime = beginTime;
        else
            endTime = strcat(date, " ",  matches{1}{2});
            event_num = str2double(matches{1}{3});
            event_label = strtrim(matches{1}{4});
        end
        event_label = strrep(event_label, " ", "");
        latency = datetime(beginTime, "InputFormat",datetime_format) - recordingBeginDateTime;
        latency = seconds(latency) + lag;
        duration = datetime(endTime, "InputFormat",datetime_format) - datetime(beginTime, "InputFormat",datetime_format);
        duration = seconds(duration);
        
        row = cell2table({latency, event_label, duration}, 'VariableNames', VariableNames);
        output_df = [output_df; row];
    end
    
    % drop duplicates
    output_df  = unique(output_df,'rows');
    
    
    % Save table to csv
    writetable(output_df, fullfile(csv_ouput_path, "Events.csv"), "WriteMode", "overwrite");
end