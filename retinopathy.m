% Retinopathy
% Implicit Categorization Task, with Feedback
% C. Hassall
% November, 2017

close all; clear variables;

% Make sure we don't get the same sequence of random numbers each time
rng('shuffle');

% Set to 1 in order to run in windowed mode (command window visible)
% Set to 0 during actual testing
justTesting = 0;
useDatapixx = 1;

if useDatapixx
    Datapixx('Open');
    Datapixx('StopAllSchedules');
    
    % We'll make sure that all the TTL digital outputs are low before we start
    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    
    % Configure digital input system for monitoring button box
    Datapixx('EnableDinDebounce');                          % Debounce button presses
    Datapixx('SetDinLog');                                  % Log button presses to default address
    Datapixx('StartDinLog');                                % Turn on logging
    Datapixx('RegWrRd');
end

% Define control keys
KbName('UnifyKeyNames');
ExitKey = KbName('ESCAPE');
left_kb_key	= KbName('s'); % Left choice
right_kb_key = KbName('k'); % Right choice

% Get participant info
if justTesting
    p_number = '99';
    rundate = datestr(now, 'yyyymmdd-HHMMSS');
    filename = strcat('retinopathyict_', rundate, '_', p_number, '.txt');
    tripletFileName = strcat('retinopathyict_', rundate, '_', p_number, '_triplets.mat');
else
    % Make a record of this computer's name
    !hostname > hostname.txt
    while 1
        clc;
        p_number = input('Enter the participant number:\n','s');  % get the subject name/number
        rundate = datestr(now, 'yyyymmdd-HHMMSS');
        filename = strcat('retinopathyict_', rundate, '_', p_number, '.txt');
        tripletFileName = strcat('retinopathyict_', rundate, '_', p_number, '_triplets.mat');
        checker1 = ~exist(filename,'file');
        checker2 = isnumeric(str2double(p_number)) && ~isnan(str2double(p_number));
        if checker1 && checker2
            break;
        else
            disp('Invalid number, or filename already exists.');
            WaitSecs(1);
        end
    end
    sex = input('Sex (M/F): ','s');
    age = input('Age: ');
    handedness = input('Handedness (L/R): ','s');
end

% Task Parameters
numBlocks = 10;
trialsPerBlock = 25;
% usedImages = 1:500;
usedImages = [1:50 101:150 201:250 301:350 401:450];
participant_data = [];
trialData = [];

% Store this participant's info in participant_info.txt
run_line = [num2str(p_number) ', ' datestr(now) ', ' sex ', ' handedness ', ' num2str(age)];
dlmwrite('retinopathyictparticipants.txt',run_line,'delimiter','', '-append');

normal_font_colour = [255 255 255]; % White
normal_font_size = 18; % Block messages
normal_font = 'Arial'; % Block messages
text_size = 40;

% Physical display properties (TODO: YOU WILL NEED TO CHANGE THESE)
viewingDistance = 850; % mm, approximately
screenWidth = 598; % mm
screenHeight = 338; % mm
horizontalResolution = 2560; % Pixels
verticalResolution = 1440; % Pixels
screenRes = [2560, 1440];
displayDimensions = [598, 338];

stimDeg = 4*[640/426, 1]; % height (y), width (x)
stimPx = degtopx(displayDimensions,screenRes,viewingDistance,stimDeg);

fbDeg = [1.5 1.5];
fbPx = degtopx(displayDimensions,screenRes,viewingDistance,fbDeg);

instructions{1} = 'In this experiment you will diagnose retinopathy using retina images\nOn each trial, you will be shown one TARGET image in the center of the display, surrounded by several REFERENCE images.\nYour task is to select the REFERENCE image that most closely resembles the TARGET image\nAfter each selection you will receive feedback indicating whether or not you selected an image of the same diagnosis\n (checkmark = same diagnosis, x = different diagnosis)\nThis will continue until you select a retina with the same diagnosis\nOnce you have made a correct choice, you will be shown a new set of images';
instructions{2} = ['Please try to minimize eye and head movements\nAfter choosing a reference image, remain fixated on it until feedback appears\nYou will be doing ' num2str(numBlocks) ' rounds, each with ' num2str(trialsPerBlock) ' diagnoses\nYou will be given a rest break at the end of each round\nPlease use this opportunity to rest your eyes, as needed'];

try
    
    ListenChar(2);
    
    % Set up a PTB window
    background_colour = [0 0 0];
    if justTesting
        [win, rec] = Screen('OpenWindow', 0, background_colour, [0 0 1200 1000],32,2); % Windowed, for testing
        % [win, rec] = Screen('OpenWindow', 0, background_colour); % Full screen, for experiment
    else
        [win, rec] = Screen('OpenWindow', 0, background_colour); % Full screen, for experiment
    end
    Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % Load feedback images
    [xImage, xMap, xAlpha] = imread('./otherimages/cross-mark-304374_640.png');
    [checkImage, checkMap, checkAlpha] = imread('./otherimages/check-42926_640.png');
    xImage(:,:,4) = xAlpha;
    checkImage(:,:,4) = checkAlpha;
    loseTexture = Screen('MakeTexture', win, xImage);
    winTexture = Screen('MakeTexture', win, checkImage);
    
    % Stimuli locations
    [xmid, ymid] = RectCenter(rec); % Midpoint of display
    displayWidth = rec(3);
    displayHeight = rec(4);
    xGap = round(displayWidth/5);
    yGap = round(displayHeight/4);
    stimLoc = [xmid - stimPx(1)/2 ymid - stimPx(2)/2 xmid + stimPx(1)/2 ymid + stimPx(2)/2];
    Screen('TextSize',win,normal_font_size);
    Screen('TextFont',win,normal_font_size);
    DrawFormattedText(win,[instructions{1} '\n\n(loading images - please wait)'],'center','center',[255 255 255]);
    Screen('Flip',win);
    
    imageNumbers = [];
    textures = [];
    allImDims = nan(numBlocks*trialsPerBlock,2);
    
    % Load image file names and labels
    trainLabels = importdata('./checkedimages/checkedimages.csv',',');
    fileNames = trainLabels.textdata;
    labels = trainLabels.data;
    
    % Shuffle image order
    thisOrder = Shuffle(usedImages);
    
    for i = 1:length(fileNames)
        thisImage = imread(['./checkedimages/' fileNames{i} '.jpg']);
        % [thisH, thisW,~] = size(thisImage);
        %sfx = stimPx(1)/thisW;
        %sfy = stimPx(2)/thisH;
        % allImDims(i,:) = stimPx;
        textures(i) = Screen('MakeTexture', win, thisImage);
    end
    
    % Shuffle images/labels
    textures = textures(thisOrder);
    labels = labels(thisOrder);
    
    allImLocs = round([xmid - stimPx(1)/2 ymid - stimPx(2)/2 xmid + stimPx(1)/2 ymid + stimPx(2)/2]);
    allFbLocs = round([xmid - fbPx(1)/2 ymid - fbPx(2)/2 xmid + fbPx(1)/2 ymid + fbPx(2)/2]);
    % targetOffset = [0 -100 0 -100];
    targetOffset = [0 0 0 0]; % Where does the target appear, relative to center of display?
    %     offsets = [-400 200 -400 200;...
    %         -200 200 -200 200;...
    %         0 200 0 200;...
    %         200 200 200 200;...
    %         400 200 400 200;...
    %         -400 400 -400 400;...
    %         -200 400 -200 400;...
    %         0 400 0 400;...
    %         200 400 200 400;...
    %         400 400 400 400];
    
    
    offsets = [-1.5*xGap -yGap -1.5*xGap -yGap;...
        -0.5*xGap -yGap -0.5*xGap -yGap;...
        0.5*xGap -yGap 0.5*xGap -yGap;...
        1.5*xGap -yGap 1.5*xGap -yGap;...
        1.5*xGap 0 1.5*xGap 0;...
        1.5*xGap yGap 1.5*xGap yGap;...
        0.5*xGap yGap 0.5*xGap yGap;...
        -0.5*xGap yGap -0.5*xGap yGap;...
        -1.5*xGap yGap -1.5*xGap yGap;...
        -1.5*xGap 0 -1.5*xGap 0];
    
    % Compute the image centers, which will be used to determine which
    % image is selected
    xCenters = xmid + offsets(:,1);
    yCenters = ymid + offsets(:,2);
    
    Screen('TextSize',win,normal_font_size);
    DrawFormattedText(win,[instructions{1} '\n\n(press any key to continue)'],'center','center',[255 255 255]);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    DrawFormattedText(win,[instructions{2} '\n\n(press any key to begin)'],'center','center',[255 255 255]);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1); 
    
    % Block loop
    for b = 1:numBlocks
        
        % Trial loop
        for t = 1:trialsPerBlock
            
            thisImageIndex = (b-1)*trialsPerBlock + t; % 1,2,3,4,...
            thisLabel = labels(thisImageIndex);
            thisTexture = textures(thisImageIndex);
            
            % Determine reference images (TODO: fix)
%             referenceImages = nan(1,10);
%             referenceLabels = nan(1,10);
%             referenceTextures = nan(1,10);
%             for i = 1:5
%                 theseImages = thisOrder(find(labels == i-1));
%                 theseImages = theseImages(theseImages ~= thisOrder(thisImageIndex)); % Exclude target image
%                 theseImages = Shuffle(theseImages);
%                 theseImages = theseImages(1:2);
%                 referenceImages((i-1)*2+1:i*2) = theseImages;
%                 referenceLabels((i-1)*2+1:i*2) = [i-1 i-1];
%                 referenceTextures((i-1)*2+1) = textures(find(thisOrder == referenceImages((i-1)*2+1)));
%                 referenceTextures(i*2) = textures(find(thisOrder == referenceImages(i*2)));
%             end
            optimizedImages = [41 2 73 79 121 146 167 159 243 207]; % Go from 1 to 250 - conversion below
            offset = [0 0 50 50 100 100 150 150 200 200];
            startingImage = [0 0 100 100 200 200 300 300 400 400];
            referenceImages = optimizedImages - offset + startingImage;
            referenceLabels = [0 0 1 1 2 2 3 3 4 4];
            referenceTextures = nan(1,10);
            for i = 1:10
                referenceTextures(i) = textures(find(thisOrder == referenceImages(i)));
            end
            
            referenceOrder = randperm(10);
            referenceImages = referenceImages(referenceOrder);
            referenceLabels = referenceLabels(referenceOrder);
            referenceTextures = referenceTextures(referenceOrder);
            
            % Feedback loop
            respondedCorrectly = 0;
            fbDisplayed = [0 0 0 0 0 0 0 0 0 0];
            responseCounter = 0;
            thisMarker = 255;
            while ~respondedCorrectly
                responseCounter = responseCounter + 1;
                
                % Draw target image
                Screen('DrawTexture', win, thisTexture,[],allImLocs+targetOffset);
                
                % Draw reference images
                for i = 1:10
                    Screen('DrawTexture', win, referenceTextures(i),[],allImLocs+offsets(i,:));
                    % For images 2-10 (the choices) optionally overlay
                    % feedback
                    if fbDisplayed(i)
                        Screen('DrawTexture', win, fbDisplayed(i),[],allFbLocs+offsets(i,:));
                    end
                end

                flipandmark(win,thisMarker,useDatapixx);
                WaitSecs(1);
                Beeper(400,0.4,0.05); % 400 Hz sine tone for 150 ms
                
                validClick = 0;
                
                % Wait until participant selects a retina image
                startTime = GetSecs();
                while ~validClick
                    [clicks,x,y,whichButton] = GetClicks(win);
                    myDistances = sqrt((x - xCenters).^2 + (y - yCenters).^2);
                    [myMin, closest] = min(myDistances);
                    validClick = myMin < 200; % Participant must get within 100 pixels of center
                end
                ellapsedTime = GetSecs() - startTime;
                sendmarker(closest,useDatapixx); % Response marker 
                
                correctResponses = referenceLabels == thisLabel;
                correctResponse = correctResponses(closest);
                
                % Testing - Pick Correct Answer Automatically
                %             closest = find(referenceLabels == thisLabel,1);
                
                % Record triplet data
                notPicked = referenceImages(referenceImages ~= referenceImages(closest) & ~fbDisplayed);
                for i = 1:length(notPicked)
                    trialData = [trialData; thisOrder(thisImageIndex) referenceImages(closest) notPicked(i)];
                end
                
                respondedCorrectly = thisLabel==referenceLabels(closest);
                
                this_data_line = [b t responseCounter thisImageIndex thisOrder(thisImageIndex) thisLabel referenceLabels(closest) respondedCorrectly ellapsedTime];
                dlmwrite(filename,this_data_line,'delimiter', '\t', '-append');
                participant_data = [participant_data; this_data_line]; % Not necessary, just an extra copy of the data
                
                [~, ~, keyCode] = KbCheck(-1);
                if keyCode(ExitKey)
                    error('Session ended!');
                end
                
                % Wait 400 - 600 ms before feedback
                WaitSecs(.4 + rand()*2);
                
                if respondedCorrectly
                    fbDisplayed(closest) = winTexture; % Display feedback for this choice
                    
                    Screen('DrawTexture', win, thisTexture,[],allImLocs+targetOffset);
                    
                    % Draw reference images
                    for i = 1:10
                        Screen('DrawTexture', win, referenceTextures(i),[],allImLocs+offsets(i,:));
                        % For images 2-10 (the choices) optionally overlay
                        % feedback
                        if fbDisplayed(i)
                            Screen('DrawTexture', win, fbDisplayed(i),[],allFbLocs+offsets(i,:));
                        end
                    end
                    
                    flipandmark(win,20 + closest,useDatapixx); % Win marker
                    WaitSecs(2); % Leave win feedback up for 2 seconds
                else
                    fbDisplayed(closest) = loseTexture; % Display feedback for this choice
                    thisMarker = 10 + closest; % Lose marker
                end
                
            end
        end
        
        % Rest break
        Screen(win,'TextFont',normal_font);
        Screen(win,'TextSize',normal_font_size);
        DrawFormattedText(win, ['Rest break\n' 'You have completed ' num2str(b) ' of ' num2str(numBlocks) ' blocks\n\n(press any key to continue)'], 'center', 'center', [255 255 255]);
        Screen('Flip',win);
        KbReleaseWait(-1);
        KbPressWait(-1);
        
    end
    
    % Save triplets
    save(tripletFileName,'trialData','trainLabels');
    
catch e
    % Close the Psychtoolbox window and bring back the cursor and keyboard
    save(tripletFileName,'trialData','trainLabels');
    Screen('CloseAll');
    ListenChar(0);
    ShowCursor();
    rethrow(e);
    
    % Close the DataPixx2
    if useDatapixx
        Datapixx('Close');
    end
    
end

% Close the Psychtoolbox window and bring back the cursor and keyboard
Screen('CloseAll');
ListenChar(0);
ShowCursor();

% Close the DataPixx2
if useDatapixx
    Datapixx('Close');
end
