classdef proj_final_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        AudioFilterApplicationUIFigure  matlab.ui.Figure
        CustomWeightsEditField          matlab.ui.control.EditField
        CustomWeightsEditFieldLabel     matlab.ui.control.Label
        ResetButton                     matlab.ui.control.Button
        Image                           matlab.ui.control.Image
        LBYCPA4EQ1Group7RAGUDOJude11917121TAYAMENCzanina11820543Label  matlab.ui.control.Label
        Label_3                         matlab.ui.control.Label
        Label_2                         matlab.ui.control.Label
        HelpButton                      matlab.ui.control.Button
        CutoffFrequencyHzLabel          matlab.ui.control.Label
        CutoffFrequencyHzSlider         matlab.ui.control.RangeSlider
        FilterOrderSlider               matlab.ui.control.Slider
        FilterOrderLabel                matlab.ui.control.Label
        PauseAudioButton                matlab.ui.control.Button
        PlayAudioButton                 matlab.ui.control.Button
        ApplyFIRFilterButton            matlab.ui.control.Button
        ApplyIIRFilterButton            matlab.ui.control.Button
        FilterTypeDropDown              matlab.ui.control.DropDown
        FilterTypeDropDownLabel         matlab.ui.control.Label
        LoadAudioFileButton             matlab.ui.control.Button
        UIAxes_3                        matlab.ui.control.UIAxes
        UIAxes_2                        matlab.ui.control.UIAxes
        UIAxes2                         matlab.ui.control.UIAxes
        UIAxes                          matlab.ui.control.UIAxes
    end

    
    % Private properties to store app data
    properties (Access = private)
        AudioData % Original audio data
        SampleRate % Sampling rate of the audio
        Player % Audio player object
        FilteredAudioData % Processed (filtered) audio data
        IsFiltered = false % Flag to check if audio is filtered
        CustomWeights = []; % Weights for custom FIR filter
    end
    
    % Callback methods for user interaction
    methods (Access = private)
        
        function PlotFrequencyDomain(app)
            % Check if audio data is loaded
            if isempty(app.AudioData)
                uialert(app.AudioFilterApplicationUIFigure, ...
                    ['No audio data loaded. Please load an audio ' ...
                    'file first.'], ...
                    'Error');
                return;
            end

            % Compute frequency and FFT of the audio data
            N = length(app.AudioData);
            f = (0:N-1)*(app.SampleRate/N);
            fftSignal = fft(app.AudioData);
            magnitude = abs(fftSignal)/N;

            % Plot frequency domain (only positive frequencies)
            plot(app.UIAxes2, f(1:floor(N/2)), magnitude(1:floor(N/2)), ...
                'Color', [0.1, 0.5, 0.8]);
            title(app.UIAxes2, 'Frequency Domain');
            xlabel(app.UIAxes2, 'Frequency (Hz)');
            ylabel(app.UIAxes2, 'Magnitude');
        end

        function PlotMagnitudeResponse(app, b, a)
            % Compute and plot the magnitude response of the filter
            [h, w] = freqz(b, a, 1024, app.SampleRate);
            plot(app.UIAxes_2, w, abs(h), 'Color', [0.1, 0.5, 0.8]);
            title(app.UIAxes_2, 'Magnitude Response');
            xlabel(app.UIAxes_2, 'Frequency (Hz)');
            ylabel(app.UIAxes_2, 'Magnitude');
        end

        function PlotPhaseResponse(app, b, a)
            % Compute and plot the phase response of the filter
            [h, w] = freqz(b, a, 1024, app.SampleRate);
            plot(app.UIAxes_3, w, unwrap(angle(h)) * (180/pi), ...
                'Color', [0.1, 0.5, 0.8]);
            title(app.UIAxes_3, 'Phase Response');
            xlabel(app.UIAxes_3, 'Frequency (Hz)');
            ylabel(app.UIAxes_3, 'Phase (degrees)');
        end

    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Callback function: LoadAudioFileButton, UIAxes
        function LoadAudioButtonPushed(app, ~)
            % Prompt user to select a .wav audio file
            [file, path] = uigetfile('*.wav', 'Select an Audio File');
            if isequal(file, 0)
                disp('User canceled file selection');
            else
                % Load and preprocess the audio file 
                % (convert to mono if needed)
                [audio, fs] = audioread(fullfile(path, file));
                if size(audio, 2) > 1
                    audio = mean(audio, 2);
                end

                % Update app properties with audio data and sampling rate
                app.AudioData = audio;
                app.SampleRate = fs;
                app.FilteredAudioData = [];
                app.IsFiltered = false;

                % Plot time domain signal
                t = (0:length(audio)-1) / fs;
                plot(app.UIAxes, t, audio, 'Color', [0.1, 0.5, 0.8]);
                title(app.UIAxes, 'Time Domain Signal');
                xlabel(app.UIAxes, 'Time (s)');
                ylabel(app.UIAxes, 'Amplitude');
                
                % Plot frequency domain
                PlotFrequencyDomain(app);
            end
        end

        % Button pushed function: ApplyFIRFilterButton
        function ApplyFIRFilterButtonPushed(app, ~)
            % Check if audio data is loaded
            if isempty(app.AudioData)
                uialert(app.AudioFilterApplicationUIFigure, ...
                    'No audio file loaded.', 'Error');
                return;
            end

            % Retrieve filter parameters from UI components
            filterType = app.FilterTypeDropDown.Value;
            cutoff = app.CutoffFrequencyHzSlider.Value / (app. ...
                SampleRate / 2);
            order = round(app.FilterOrderSlider.Value);
            
            % Use custom weights if provided; otherwise, design FIR filter
            if ~isempty(app.CustomWeights)
                b = app.CustomWeights; % Use custom weights
            else
                switch filterType
                    case 'Lowpass'
                        b = fir1(order, cutoff(1), 'low');
                    case 'Highpass'
                        b = fir1(order, cutoff(1), 'high');
                    case 'Bandpass'
                        b = fir1(order, cutoff, 'bandpass');
                    case 'Bandstop'
                        b = fir1(order, cutoff, 'stop');
                    otherwise
                        uialert(app.AudioFilterApplicationUIFigure, ...
                            'Invalid filter type.', 'Error');
                        return;
                end
            end

            % Apply the FIR filter and update app state
            filteredAudio = filter(b, 1, app.AudioData);
            app.FilteredAudioData = filteredAudio;
            app.IsFiltered = true;

            % Plot filtered signal in time domain
            t = (0:length(filteredAudio)-1) / app.SampleRate;
            plot(app.UIAxes, t, filteredAudio, 'Color', [0.1, 0.5, 0.8]);
            title(app.UIAxes, 'Filtered Signal (Time Domain)');
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Amplitude');

            % Plot filter responses
            PlotMagnitudeResponse(app, b, 1);
            PlotPhaseResponse(app, b, 1);
        end

        % Button pushed function: ApplyIIRFilterButton
        function ApplyIIRFilterButtonPushed(app, ~)
            % Check if audio data is loaded
            if isempty(app.AudioData)
                uialert(app.AudioFilterApplicationUIFigure, ...
                    'No audio file loaded.', 'Error');
                return;
            end

            % Ensure no custom weights are used for IIR filters
            if ~isempty(app.CustomWeights)
                uialert(app.AudioFilterApplicationUIFigure, ...
                    ['Custom weights detected. Please use the ' ...
                    '"Apply FIR Filter" button instead.'], 'Error');
                return;
            end

            % Retrieve filter parameters from UI components
            filterType = app.FilterTypeDropDown.Value;
            cutoff = app.CutoffFrequencyHzSlider.Value / (app. ...
                SampleRate / 2); 
            order = round(app.FilterOrderSlider.Value);

            % Design the IIR filter
            try
                switch filterType
                    case 'Lowpass'
                        [b, a] = butter(order, cutoff(1), 'low');
                    case 'Highpass'
                        [b, a] = butter(order, cutoff(1), 'high');
                    case 'Bandpass'
                        [b, a] = butter(order, cutoff, 'bandpass');
                    case 'Bandstop'
                        [b, a] = butter(order, cutoff, 'stop');
                    otherwise
                        uialert(app.AudioFilterApplicationUIFigure, ...
                            'Invalid filter type.', 'Error');
                        return;
                end
            catch
                uialert(app.AudioFilterApplicationUIFigure, ...
                    ['Filter design failed. Check the filter ' ...
                    'parameters.'], 'Error');
                return;
            end

            % Apply the IIR filter and update app state
            filteredAudio = filter(b, a, app.AudioData);
            app.FilteredAudioData = filteredAudio;
            app.IsFiltered = true;

            % Plot filtered signal in time domain
            t = (0:length(filteredAudio)-1) / app.SampleRate;
            plot(app.UIAxes, t, filteredAudio, 'Color', [0.1, 0.5, 0.8]);
            title(app.UIAxes, 'Filtered Signal (Time Domain)');
            xlabel(app.UIAxes, 'Time (s)');
            ylabel(app.UIAxes, 'Amplitude');

            % Plot filter responses
            PlotMagnitudeResponse(app, b, a);
            PlotPhaseResponse(app, b, a);
        end

        % Button pushed function: PlayAudioButton
        function PlayAudioButtonPushed(app, ~)
            % Check if audio data is loaded
            if isempty(app.AudioData)
                uialert(app.AudioFilterApplicationUIFigure, ...
                    'No audio file loaded.', 'Error');
                return;
            end
            
            % Decide whether to play filtered or unfiltered audio
            if app.IsFiltered && ~isempty(app.FilteredAudioData)
                audioToPlay = app.FilteredAudioData;
            else
                audioToPlay = app.AudioData;
            end
            
            % Check if the audioplayer is empty or not already playing
            if isempty(app.Player) || ~isplaying(app.Player)
                app.Player = audioplayer(audioToPlay, app.SampleRate);
                play(app.Player);
            end
        end

        % Button pushed function: PauseAudioButton
        function PauseAudioButtonPushed(app, ~)
            % Check if audio data is loaded
            if isempty(app.AudioData)
                uialert(app.AudioFilterApplicationUIFigure, ...
                    'No audio file loaded.', 'Error');
                return;
            end
            
            % Pause playback if audio is currently playing
            if ~isempty(app.Player) && isplaying(app.Player)
                pause(app.Player);
            end
        end

        % Button pushed function: HelpButton
        function HelpButtonPushed(~, ~)
            % Custom figure for help dialog
            helpFig = figure('Name', 'Help', 'NumberTitle', 'off', ...
                             'MenuBar', 'none', 'ToolBar', 'none', ...
                             'Resize', 'on', 'Position', [100, 100, 400, 380]);
        
            % Text box for the message
            uicontrol('Style', 'text', ...
                      'Parent', helpFig, ...
                      'String', {'Audio Filter Application Guide:', ...
                      '', ...
                      ['1. Load a short audio file (.wav) using the ' ...
                      '"Load Audio" button.'], ...
                      '', ...
                      '2. Choose the filter type from the dropdown.', ...
                      '', ...
                      '3. Set the cutoff frequency and filter order.', ...
                      '', ...
                      ['4. Enter custom weights for FIR filters if ' ...
                      'desired (values must be separated by commas).'], ...
                      '', ...
                      ['5. Apply either an FIR filter (if ' ...
                      'custom weights are added) or IIR filter to ' ...
                      'the audio.'], ...
                      '', ...
                      ['6. Use the "Play" and "Pause" buttons to ' ...
                      'control unfiltered or filtered audio ' ...
                      'playback.'], ...
                      '', ...
                      ['7. Press the reset button to restart the app ' ...
                      'to its initial state (recommended after each ' ...
                      'use).']}, ...
                      'FontSize', 10.5, ...
                      'HorizontalAlignment', 'left', ...
                      'Position', [20, 20, 360, 350]);
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, ~)
            % Stop any playing audio
            if ~isempty(app.Player) && isplaying(app.Player)
                stop(app.Player);
            end
            
            % Clear audio data and related variables
            app.AudioData = [];
            app.FilteredAudioData = [];
            app.SampleRate = [];
            app.Player = [];
            app.IsFiltered = false;
            
            % Reset custom weights
            app.CustomWeightsEditField.Value = '';
            app.CustomWeights = [];
            
            % Clear all axes
            cla(app.UIAxes);
            cla(app.UIAxes2);
            cla(app.UIAxes_2);
            cla(app.UIAxes_3);
                
            % Reset titles of all axes
            title(app.UIAxes, '');
            title(app.UIAxes2, '');
            title(app.UIAxes_2, '');
            title(app.UIAxes_3, '');
            
            % Reset sliders and dropdowns to their default values
            app.CutoffFrequencyHzSlider.Value = ...
            [app.CutoffFrequencyHzSlider.Limits(1), ...
            app.CutoffFrequencyHzSlider.Limits(2)];
            app.FilterOrderSlider.Value = app.FilterOrderSlider.Limits(1);
            app.FilterTypeDropDown.Value = app.FilterTypeDropDown.Items{1};
            
            % Notify the user that the reset is complete
            uialert(app.AudioFilterApplicationUIFigure, ['The ' ...
                'application has been reset.'], 'Reset Complete');
        end

        % Value changed function: CustomWeightsEditField
        function CustomWeightsEditFieldValueChanged(app, ~)
            % Get the custom weights as a string from the input field
            weightString = app.CustomWeightsEditField.Value;
        
            % Validate and convert the weights to a numeric array
            try
                weights = str2num(weightString);
                % Check if weights are valid (e.g., not NaN, Inf, or empty)
                if ~isempty(weights) && ~any(isnan(weights)) && ...
                    ~any(isinf(weights))
                        app.CustomWeights = weights;
                else
                    % Handle invalid input (e.g., display an error message)
                    uialert(app.AudioFilterApplicationUIFigure, ...
                        'Invalid weights. Please enter valid numbers.', ...
                        'Error');
                    app.CustomWeights = [];
                end
            catch
                % Handle errors during conversion (e.g., non-numeric input)
                uialert(app.AudioFilterApplicationUIFigure, ...
                    ['Invalid input. Please enter comma-separated ' ...
                    'numbers.'], 'Error');
                app.CustomWeights = [];
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create AudioFilterApplicationUIFigure and hide until all components are created
            app.AudioFilterApplicationUIFigure = uifigure('Visible', 'off');
            app.AudioFilterApplicationUIFigure.Position = [100 100 702 568];
            app.AudioFilterApplicationUIFigure.Name = 'Audio Filter Application';

            % Create UIAxes
            app.UIAxes = uiaxes(app.AudioFilterApplicationUIFigure);
            title(app.UIAxes, 'Time Domain')
            xlabel(app.UIAxes, 'Time (s)')
            ylabel(app.UIAxes, 'Amplitude')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.ButtonDownFcn = createCallbackFcn(app, @LoadAudioButtonPushed, true);
            app.UIAxes.Position = [28 185 288 171];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.AudioFilterApplicationUIFigure);
            title(app.UIAxes2, 'Frequency Domain')
            xlabel(app.UIAxes2, 'Frequency (Hz)')
            ylabel(app.UIAxes2, 'Magnitude')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.Position = [393 187 284 170];

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.AudioFilterApplicationUIFigure);
            title(app.UIAxes_2, 'Magnitude Response')
            xlabel(app.UIAxes_2, 'Frequency (Hz)')
            ylabel(app.UIAxes_2, 'Magnitude')
            zlabel(app.UIAxes_2, 'Z')
            app.UIAxes_2.Position = [28 11 286 168];

            % Create UIAxes_3
            app.UIAxes_3 = uiaxes(app.AudioFilterApplicationUIFigure);
            title(app.UIAxes_3, 'Phase Response')
            xlabel(app.UIAxes_3, 'Frequency (Hz)')
            ylabel(app.UIAxes_3, 'Phase (degrees)')
            zlabel(app.UIAxes_3, 'Z')
            app.UIAxes_3.Position = [395 13 286 168];

            % Create LoadAudioFileButton
            app.LoadAudioFileButton = uibutton(app.AudioFilterApplicationUIFigure, 'push');
            app.LoadAudioFileButton.ButtonPushedFcn = createCallbackFcn(app, @LoadAudioButtonPushed, true);
            app.LoadAudioFileButton.Position = [21 507 104 23];
            app.LoadAudioFileButton.Text = 'Load Audio File';

            % Create FilterTypeDropDownLabel
            app.FilterTypeDropDownLabel = uilabel(app.AudioFilterApplicationUIFigure);
            app.FilterTypeDropDownLabel.HorizontalAlignment = 'right';
            app.FilterTypeDropDownLabel.Position = [21 429 69 22];
            app.FilterTypeDropDownLabel.Text = 'Filter Type';

            % Create FilterTypeDropDown
            app.FilterTypeDropDown = uidropdown(app.AudioFilterApplicationUIFigure);
            app.FilterTypeDropDown.Items = {'Lowpass', 'Highpass', 'Bandpass', 'Bandstop'};
            app.FilterTypeDropDown.Placeholder = 'Choose Filter';
            app.FilterTypeDropDown.Position = [97 429 100 22];
            app.FilterTypeDropDown.Value = 'Lowpass';

            % Create ApplyIIRFilterButton
            app.ApplyIIRFilterButton = uibutton(app.AudioFilterApplicationUIFigure, 'push');
            app.ApplyIIRFilterButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyIIRFilterButtonPushed, true);
            app.ApplyIIRFilterButton.Position = [375 376 100 23];
            app.ApplyIIRFilterButton.Text = 'Apply IIR Filter';

            % Create ApplyFIRFilterButton
            app.ApplyFIRFilterButton = uibutton(app.AudioFilterApplicationUIFigure, 'push');
            app.ApplyFIRFilterButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyFIRFilterButtonPushed, true);
            app.ApplyFIRFilterButton.Position = [268 376 100 23];
            app.ApplyFIRFilterButton.Text = 'Apply FIR Filter';

            % Create PlayAudioButton
            app.PlayAudioButton = uibutton(app.AudioFilterApplicationUIFigure, 'push');
            app.PlayAudioButton.ButtonPushedFcn = createCallbackFcn(app, @PlayAudioButtonPushed, true);
            app.PlayAudioButton.Position = [21 475 77 23];
            app.PlayAudioButton.Text = 'Play Audio';

            % Create PauseAudioButton
            app.PauseAudioButton = uibutton(app.AudioFilterApplicationUIFigure, 'push');
            app.PauseAudioButton.ButtonPushedFcn = createCallbackFcn(app, @PauseAudioButtonPushed, true);
            app.PauseAudioButton.Position = [103 475 87 23];
            app.PauseAudioButton.Text = 'Pause Audio';

            % Create FilterOrderLabel
            app.FilterOrderLabel = uilabel(app.AudioFilterApplicationUIFigure);
            app.FilterOrderLabel.HorizontalAlignment = 'right';
            app.FilterOrderLabel.Position = [471 424 36 30];
            app.FilterOrderLabel.Text = {'Filter '; 'Order'};

            % Create FilterOrderSlider
            app.FilterOrderSlider = uislider(app.AudioFilterApplicationUIFigure);
            app.FilterOrderSlider.Limits = [1 100];
            app.FilterOrderSlider.MajorTicks = [1 25 50 75 100];
            app.FilterOrderSlider.Position = [528 441 150 3];
            app.FilterOrderSlider.Value = 1;

            % Create CutoffFrequencyHzSlider
            app.CutoffFrequencyHzSlider = uislider(app.AudioFilterApplicationUIFigure, 'range');
            app.CutoffFrequencyHzSlider.Limits = [1 10000];
            app.CutoffFrequencyHzSlider.MajorTicks = [1 2500 5000 7500 10000];
            app.CutoffFrequencyHzSlider.MajorTickLabels = {'1', '2500', '5000', '7500', '10000'};
            app.CutoffFrequencyHzSlider.Position = [295 441 150 3];
            app.CutoffFrequencyHzSlider.Value = [1 5000];

            % Create CutoffFrequencyHzLabel
            app.CutoffFrequencyHzLabel = uilabel(app.AudioFilterApplicationUIFigure);
            app.CutoffFrequencyHzLabel.HorizontalAlignment = 'right';
            app.CutoffFrequencyHzLabel.Position = [208 410 65 44];
            app.CutoffFrequencyHzLabel.Text = {'Cutoff '; 'Frequency '; '(Hz)'};

            % Create HelpButton
            app.HelpButton = uibutton(app.AudioFilterApplicationUIFigure, 'push');
            app.HelpButton.ButtonPushedFcn = createCallbackFcn(app, @HelpButtonPushed, true);
            app.HelpButton.Position = [22 539 43 23];
            app.HelpButton.Text = 'Help';

            % Create Label_2
            app.Label_2 = uilabel(app.AudioFilterApplicationUIFigure);
            app.Label_2.Position = [2 354 701 22];
            app.Label_2.Text = '====================================================================================================';

            % Create Label_3
            app.Label_3 = uilabel(app.AudioFilterApplicationUIFigure);
            app.Label_3.Position = [2 452 701 22];
            app.Label_3.Text = '====================================================================================================';

            % Create LBYCPA4EQ1Group7RAGUDOJude11917121TAYAMENCzanina11820543Label
            app.LBYCPA4EQ1Group7RAGUDOJude11917121TAYAMENCzanina11820543Label = uilabel(app.AudioFilterApplicationUIFigure);
            app.LBYCPA4EQ1Group7RAGUDOJude11917121TAYAMENCzanina11820543Label.HorizontalAlignment = 'right';
            app.LBYCPA4EQ1Group7RAGUDOJude11917121TAYAMENCzanina11820543Label.FontSize = 9;
            app.LBYCPA4EQ1Group7RAGUDOJude11917121TAYAMENCzanina11820543Label.FontAngle = 'italic';
            app.LBYCPA4EQ1Group7RAGUDOJude11917121TAYAMENCzanina11820543Label.Position = [557 477 132 78];
            app.LBYCPA4EQ1Group7RAGUDOJude11917121TAYAMENCzanina11820543Label.Text = {'LBYCPA4 - EQ1'; ''; '(Group 7)'; 'RAGUDO, Jude - 11917121'; 'TAYAMEN, Czanina - 11820543'};

            % Create Image
            app.Image = uiimage(app.AudioFilterApplicationUIFigure);
            app.Image.Position = [323 475 94 89];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'logo.png');

            % Create ResetButton
            app.ResetButton = uibutton(app.AudioFilterApplicationUIFigure, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.Position = [130 508 57 22];
            app.ResetButton.Text = 'Reset';

            % Create CustomWeightsEditFieldLabel
            app.CustomWeightsEditFieldLabel = uilabel(app.AudioFilterApplicationUIFigure);
            app.CustomWeightsEditFieldLabel.HorizontalAlignment = 'right';
            app.CustomWeightsEditFieldLabel.Position = [22 376 101 22];
            app.CustomWeightsEditFieldLabel.Text = 'Custom Weights';

            % Create CustomWeightsEditField
            app.CustomWeightsEditField = uieditfield(app.AudioFilterApplicationUIFigure, 'text');
            app.CustomWeightsEditField.ValueChangedFcn = createCallbackFcn(app, @CustomWeightsEditFieldValueChanged, true);
            app.CustomWeightsEditField.Position = [130 376 100 22];

            % Show the figure after all components are created
            app.AudioFilterApplicationUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = proj_final_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.AudioFilterApplicationUIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.AudioFilterApplicationUIFigure)
        end
    end
end