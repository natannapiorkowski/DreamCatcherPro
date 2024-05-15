function EEG = addEEGData(EEG, ASCIIfile, channelLabel)
file = fopen(ASCIIfile, 'r');

%% Get infos from the header
l = fgetl(file);
continueLoop = 1;
i=0;
while continueLoop
    if strfind(l, 'Sample Rate')
        l_regexp = regexp(l, ':', 'split');
        srate = str2double(l_regexp{2});
    elseif strfind(l, 'Length')
        l_regexp = regexp(l, ':', 'split');
        pnts = str2double(l_regexp{2});
    elseif strfind(l, 'Start Time')
        l_regexp = regexp(l, ': ', 'split');
        start_time = datetime(l_regexp{2}, 'Format','dd.MM.yyyy HH:mm:ss');
    elseif strfind(l, 'Data')
        continueLoop = 0;
    end
    l = fgetl(file);
    i=i+1;
end


%% read data that come after the header
data = dlmread(ASCIIfile, ';', 7, 1);

if length(data) ~= pnts
    cprintf([1,0,0], 'Length of the data differs from length in the header!!! \n')
end
fclose(file);
cprintf([0,1,0], '\tChannel %s added to EEG \n', channelLabel)


%% add new data to EEG
EEG.data(end+1, :) = data;


% add all kind of information to the EEG struct
if EEG.srate == 1
    EEG.srate = srate;
else
    if EEG.srate ~= srate;
        cprintf(['1,0,0'], 'EEG.srate mismatch!!!! \n')
    end
end

if EEG.pnts == 0
    EEG.pnts =pnts;
else 
    if EEG.pnts ~= pnts
         cprintf(['1,0,0'], 'EEG.pnts mismatch!!!! \n')
    end
end       

if isfield(EEG, 'start_time')
    EEG.start_time.(channelLabel) = datevec(start_time);
else
    EEG.start_time = {};
    EEG.start_time.(channelLabel) = datevec(start_time);
end

%% Check if all start times are the same and raise an error if not.
starttimes_labels = fieldnames(EEG.start_time);
starttimes = zeros(length(starttimes_labels), 6); 
for i = 1:length(starttimes_labels)
    starttimes(i, :) = EEG.start_time.(starttimes_labels{i});
end

if size(starttimes, 1) > 1
    if sum(min(starttimes) < max(starttimes)) > 0
        disp(min(starttimes))
        error("Start times are not even!")
        return
    else
        EEG.first_sample_time = datevec(start_time);
    end
end

%%


EEG.nbchan = size(EEG.data, 1);

EEG.chanlocs(end+1).labels = channelLabel;
end
