function removeNoisyEpochs_amplitudeThreshold(datafiles, datapath, ...
                                              amplitudeToDisplay, ...
                                              numOfEpochsToDisplay, ...
                                              lowerAmplitudeLimit, ...
                                              upperAmplitudeLimit)

    toSavePath = fullfile(datapath, 'NoisyEpochsRejected_amplitudeThreshold'); mkdir(toSavePath);
    
    for p = 1:length(datafiles)
        if strfind(datafiles{p}, '.set')
            repeatThresholding = 1;
            EEG = pop_loadset('filename',datafiles(p),'filepath',datapath);
            cprintf([0,1,1], 'Processing file: %s \n', datafiles{p})
            % display some infos
            cprintf([0,1,1], 'List of events in the data:\n')
            for event =  unique({EEG.event.type})
                cprintf([0,1,1], strcat('\t\t -', event{1}, '\n'))
            end
            
                % adds fields to EEG.reject: rejthresh and rejthreshE
%                 trialsToRemove = removeData_amplitudeThreshold(EEG.data,SETTINGS.lowerLimit, SETTINGS.upperLimit, SETTINGS.removeArtifacts_separatelyForEachChannel);
            while repeatThresholding
                EEG = pop_eegthresh(EEG,1,[1:EEG.nbchan], ...
                                    lowerAmplitudeLimit, ...
                                    upperAmplitudeLimit, ...
                                    EEG.xmin,EEG.xmax,1,0);

                cmd = ['disp(1)'];
                eegplot(EEG.data,  'eloc_file',EEG.chanlocs,...
                               'butlabel','Reject', ...
                               'command', cmd,...
                               'wincolor', [1, 0.7, 0.7],...
                               'spacing',   amplitudeToDisplay, ...
                               'winlength', numOfEpochsToDisplay,...
                               'events', EEG.event, ...
                               'srate', EEG.srate, ...
                               'winrej',trial2eegplot(sum(EEG.reject.rejthreshE, 1), EEG.reject.rejthreshE, EEG.pnts, [1,0.5,0.5]));
                uiwait(gcf)       
                [trialrej,elecrej] = eegplot2trial(evalin('base', 'TMPREJ'), EEG.pnts, EEG.trials);           
                EEG.reject.rejthresh = trialrej;
                EEG.reject.rejthreshE = elecrej;

                % EEG.information{end+1} = sprintf('%g noisy epochs rejected based on amplitude threshold', sum(EEG.reject.rejthresh));
                
                %% Show a dialog box asking whether to repeat thresholding
                show_dialog = 1;
                while show_dialog
                    [isanswer, ...
                     new_lowerAmplitudeLimit,...
                     new_upperAmplitudeLimit] = show_dialogbox(trialrej, ...
                                                               lowerAmplitudeLimit, ...
                                                               upperAmplitudeLimit);
                    if ~isanswer
                        show_dialog = 0;
                    else
                        % error handling
                        err = 0;
                        if new_lowerAmplitudeLimit == new_upperAmplitudeLimit
                            err = errordlg(sprintf("Whoops! You provided the same values for lower and upper amplitude threshold!"));
                            uiwait(err)
                            show_dialog = 1;
                        elseif new_lowerAmplitudeLimit > new_upperAmplitudeLimit
                            err = errordlg(sprintf("Whoops! Lower amplitude threshold is larger than upper threshold!"));
                            uiwait(err)
                            show_dialog = 1;
                        elseif isnan(new_lowerAmplitudeLimit ) 
                            err = errordlg(sprintf("Whoops! Lower amplitude threshold field is empty or incorrect!"));
                            uiwait(err)
                            show_dialog = 1;
                        elseif isnan(new_upperAmplitudeLimit ) 
                            err = errordlg(sprintf("Whoops! Lower amplitude threshold field is empty or incorrect!"));                   
                            uiwait(err)
                            show_dialog = 1;
                        else
                            show_dialog = 0;
                        end
                    end
                end

               
                if ~isanswer
                    repeatThresholding = 0;
                elseif (new_lowerAmplitudeLimit == lowerAmplitudeLimit) && (new_upperAmplitudeLimit==upperAmplitudeLimit)
                    repeatThresholding = 0;
                else
                    lowerAmplitudeLimit = new_lowerAmplitudeLimit;
                    upperAmplitudeLimit = new_upperAmplitudeLimit;
                    repeatThresholding = 1;
                end
            end
            
            for chan = 1:size(elecrej, 1)
                for trial = 1:size(elecrej, 2)
                    if elecrej(chan, trial)
                        EEG.data(chan, :, trial) = NaN(1, EEG.pnts);
                    end
                end
            end
            % Count epochs for each sleep phase
            if isfield(EEG ,  'sleepPhases')
                EEG.epochNum = countEpochs(EEG, EEG.sleepPhases);
            end
            

            EEG = eeg_checkset( EEG );
            EEG = pop_saveset( EEG, 'filename', datafiles{p},'filepath',toSavePath);
            cprintf([0,1,0], "Cleaned EEG saved to:%s \n", fullfile(toSavePath, datafiles{p}))    
        end
    end
end




function [isanswer, new_lowerAmplitudeLimit, new_upperAmplitudeLimit] = show_dialogbox(trialrej, lowerAmplitudeLimit, upperAmplitudeLimit)
    
    msg = sprintf( ...
        "Found %d noisy epoch(s) to be rejected using amplitude thresholds: [%d, %d] uV. \n" + ...
        "Do you want to change the thresholds and repeat the data cleaning? \n" + ...
        "If so, provide new thresholds in the fields below. \n" + ...
        "If not press 'Cancel'.", ...
        sum(trialrej), lowerAmplitudeLimit, upperAmplitudeLimit);

    prompt1 = "New lower amplitude threshold [uV]:";
    prompt2 = "New upper amplitude threshold [uV]:";
    
    answer = inputdlg({msg, prompt1, prompt2}, ...
                      "Do you want to repeat cleaning with different amplitude thresholds?", ...
                      [0, 150; 1 150; 1 150],...
                      {'', num2str(lowerAmplitudeLimit), num2str(upperAmplitudeLimit)}, ...
                      'on');
    if isempty(answer)
        isanswer = false;
        new_lowerAmplitudeLimit = nan;
        new_upperAmplitudeLimit = nan;
    else
        isanswer = true;
        new_lowerAmplitudeLimit = str2double(answer{2});
        new_upperAmplitudeLimit = str2double(answer{3});
    end

end
