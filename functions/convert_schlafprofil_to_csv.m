function convert_schlafprofil_to_csv(datapath)
    datafiles = dir(datapath);
    datafiles = datafiles(~ismember({datafiles.name}, {'.', '..'}));

    % Get EEG recording begin
    recording_start = get_recording_begin(datafiles(1).name);
    
    
    % % Load schlafprofil
    schlafprofil_path = fullfile(datapath, dir(fullfile(datapath, '*chlafprofil*.txt')).name);
    if isempty(dir(fullfile(datapath, '*chlafprofil*.txt')))
        fprintf('MISSING: %s\n', schlafprofil_path);
    else
        schlafprofil = load_schlafprofil(schlafprofil_path, recording_start);
    end
    
    % % Load spindles
    spindles_path = fullfile(datapath, dir(fullfile(datapath, '*pindles*.txt')).name);
    if isempty(dir(fullfile(datapath, '*pindles*.txt')))
        fprintf('MISSING: %s\n', spindles_path);
    else
        spindles = load_spindles(spindles_path, recording_start);
    end
    % 
    % events = [schlafprofil; spindles];
    % events = sortrows(events, 'latency');
    % writetable(events, fullfile(p, subj, 'Events_from_matlab.csv'));
    % 
end

function recording_start = get_recording_begin(eeg_datafile_path)
    fid = fopen(eeg_datafile_path, 'r');
    head = textscan(fid, '%s', 10, 'Delimiter', '\n');
    fclose(fid);

    for i = 1:numel(head{1})
        if contains(head{1}{i}, 'Start Time')
            start_time_str = regexp(head{1}{i}, '(\d+\.\d+\.\d+\s\d+:\d+:\d+,?\d*)', 'match');
            start_time = datetime(start_time_str{1}, 'InputFormat', 'dd.MM.yyyy HH:mm:ss');
            break;
        end
    end

    recording_start = start_time;
end

function schlafprofil = load_schlafprofil(schlafprofil_path, recording_start)
    data = readcell(schlafprofil_path, 'FileType', 'text', 'DatetimeType', 'text');

    dates = data(7:end, 1);
    times = strrep(data(7:end, 2), ';', '');
    events = data(7:end, 3);

    schlafprofil = table();
    schlafprofil.date = dates;
    schlafprofil.time = times;
    schlafprofil.type = events;
    schlafprofil.duration = repmat({30}, size(dates));

    schlafprofil.latency = datetime(strcat(dates, {' '}, times), 'InputFormat', 'dd.MM.yyyy HH:mm:ss,SSS') - recording_start;
    schlafprofil.latency = seconds(schlafprofil.latency);
    schlafprofil = schlafprofil(schlafprofil.latency > 0, :);
end

function spindles = load_spindles(spindles_path, recording_start)
    data = readcell(spindles_path, 'FileType', 'text');

    dates = data(7:end, 1);
    times_begin = data(7:end, 2);
    times_end = data(7:end, 3);
    events = data(7:end, 4);

    spindles = table();
    spindles.date = dates;
    spindles.time_begin = times_begin;
    spindles.time_end = times_end;
    spindles.type = events;
    spindles.duration = repmat({30}, size(dates));

    spindles.time_begin = datetime(strcat(dates, {' '}, times_begin), 'InputFormat', 'dd.MM.yyyy HH:mm:ss,SSS');
    spindles.time_end = datetime(strcat(dates, {' '}, times_end), 'InputFormat', 'dd.MM.yyyy HH:mm:ss,SSS');
    spindles.duration = seconds(spindles.time_end - spindles.time_begin);
    spindles.latency = seconds(spindles.time_begin - recording_start);

    spindles = spindles(spindles.latency > 0, :);
end


