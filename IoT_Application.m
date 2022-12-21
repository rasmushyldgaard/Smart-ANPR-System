function IoT_Application
% Smart ANPR System is used to detect license plates
% and read them.

% main window
fig = uifigure('Name','Smart ANPR System',...
               'WindowState','maximized');

bp = backgroundPool;    % create a backgroundpool for parallel computing
%I = imread('./webcam_test_images/test4.png');
lprNet = load('lprNet_v3.mat'); % load neural network
                                % pass it to button callback

smartANPR = uilabel(fig,'Position',[622 708 300 150],...
                        'Text','Smart ANPR System',...
                        'FontSize',30,'FontWeight','bold');

% video stream label
vidStreamLbl = uilabel(fig,'Position',[230 715 150 150],...
                        'Text','Video Stream',...
                        'FontSize',24);
                    
% image taken label
imgTakenLbl = uilabel(fig,'Position',[1170 715 150 150],...
                        'Text','Screenshot',...
                        'FontSize',24);

% lp taken label
lpTakenLbl = uilabel(fig,'Position',[1180 220 150 150],...
                     'Text','LP.Image',...
                     'FontSize',24);

% lp text area label
lpTxtAreaLbl = uilabel(fig,'Position',[1185 125 150 150],...
                     'Text','LP.Text',...
                     'FontSize',24);

% brightness spinner label
brightSpinLbl = uilabel(fig,'Position',[10 225 150 150],...
                        'Text','Brightness',...
                        'FontSize',20);

% contrast spinner label
contraSpinLbl = uilabel(fig,'Position',[170 225 150 150],...
                        'Text','Contrast',...
                        'FontSize',20);

% saturation spinner label
satSpinLbl = uilabel(fig,'Position',[330 225 150 150],...
                        'Text','Saturation',...
                        'FontSize',20);

% hue spinner label
hueSpinLbl = uilabel(fig,'Position',[490 225 150 150],...
                        'Text','Hue',...
                        'FontSize',20);

% sharpness spinner label
sharpSpinLbl = uilabel(fig,'Position',[10 150 150 150],...
                        'Text','Sharpness',...
                        'FontSize',20);
                    
% sharpness spinner label
sharpSpinLbl = uilabel(fig,'Position',[10 150 150 150],...
                        'Text','Sharpness',...
                        'FontSize',20);
                    
% gamma spinner label
gamSpinLbl = uilabel(fig,'Position',[170 150 150 150],...
                        'Text','Gamma',...
                        'FontSize',20);
                    
% backlightcompensation spinner label
blcompSpinLbl = uilabel(fig,'Position',[330 150 150 150],...
                        'Text','Backlight',...
                        'FontSize',20);
                    
% exposure spinner label
expoSpinLbl = uilabel(fig,'Position',[490 150 150 150],...
                        'Text','Exposure',...
                        'FontSize',20);
                    
                         
% video stream feed
vidStream = uiimage(fig,'Position',[10 250 600 600]);
camList = webcamlist;
camIdx = find(strcmp(camList, 'Sandberg USB Webcam Pro'));
cam = webcam(camIdx);
cam.Resolution = '1280x960';        % camera resolution
cam.ExposureMode = 'manual';        % set exposure mode to manual
cam.WhiteBalanceMode = 'auto';      % set whitebalance mode to auto
cam.Iris = 0;                       % set iris to 0
cam.FocusMode = 'auto';             % set focus mode to auto

% captured image by camera
imgTaken = uiimage(fig,'Position',[927 250 600 600],...
                'ImageSource','./test.png');

% LP
lpTaken = uiimage(fig,'Position',[1100 225 250 50],...
                'ImageSource','./test2.png');

% LP text area
lpTxtArea = uitextarea(fig,'Position',[1076 120 300 60],...
                    'Editable','off','FontSize',40,...
                    'HorizontalAlignment','center');

% capture image button
capImgBtn = uibutton(fig,'state',...
                'Position',[648 500 240 44],...
                'Text','Capture',...
                'FontSize',24,...
                'ValueChangedFcn', @(capImgBtn,event) ... 
                ImageCaptured(capImgBtn,imgTaken,lpTaken,cam,bp, ...
                lprNet,lpTxtArea));

            
% bright spinner
cam.Brightness = 64;    % initial brightness value
brightSpin = uispinner(fig,'Position',[10 257 120 28],...
                'FontSize',20,...
                'HorizontalAlignment','center',...
                'Limits',[-64 64],'Value',64,...
                'ValueChangedFcn',@(brightSpin,event) ...
                UpdateBrightness(brightSpin,cam));
            

% contra spinner
cam.Contrast = 32;  % initial contrast value
contraSpin = uispinner(fig,'Position',[170 257 120 28],...
                'FontSize',20,...
                'HorizontalAlignment','center',...
                'Limits',[0 64],'Value',32,...
                'ValueChangedFcn',@(contraSpin,event) ...
                UpdateContrast(contraSpin,cam));
            
% saturation spinner
cam.Saturation = 100;   % initial saturation value
satSpin = uispinner(fig,'Position',[330 257 120 28],...
                'FontSize',20,...
                'HorizontalAlignment','center',...
                'Limits',[0 100],'Value',100,...
                'ValueChangedFcn',@(satSpin,event) ...
                UpdateSaturation(satSpin,cam));

% hue spinner
cam.Hue = 0;    % initial hue value
hueSpin = uispinner(fig,'Position',[490 257 120 28],...
                'FontSize',20,...
                'HorizontalAlignment','center',...
                'Limits',[-2000 2000],'Value',0,...
                'ValueChangedFcn',@(hueSpin,event) ...
                UpdateHue(hueSpin,cam));

% sharpness spinner
cam.Sharpness = 7;  % initial sharpness value
sharpSpin = uispinner(fig,'Position',[10 180 120 28],...
                'FontSize',20,...
                'HorizontalAlignment','center',...
                'Limits',[1 7],'Value',7,...
                'ValueChangedFcn',@(sharpSpin,event) ...
                UpdateSharpness(sharpSpin,cam));

% gamma spinner
cam.Gamma = 100;    % initial gamma value
gamSpin = uispinner(fig,'Position',[170 180 120 28],...
                'FontSize',20,...
                'HorizontalAlignment','center',...
                'Limits',[100 300],'Value',100,...
                'ValueChangedFcn',@(gamSpin,event) ...
                UpdateGamma(gamSpin,cam));

% backlightcompensation spinner
cam.BacklightCompensation = 215;   % initial blacklightcomp value
blcompSpin = uispinner(fig,'Position',[330 180 120 28],...
                'FontSize',20,...
                'HorizontalAlignment','center',...
                'Limits',[0 215],'Value',215,...
                'ValueChangedFcn',@(blcompSpin,event) ...
                UpdateBacklightCompensation(blcompSpin,cam));
            
% exposure spinner
cam.Exposure = -6;  % initial exposure value
expoSpin = uispinner(fig,'Position',[490 180 120 28],...
                'FontSize',20,...
                'HorizontalAlignment','center',...
                'Limits',[-11 -2],'Value',-6,...
                'ValueChangedFcn',@(expoSpin,event) ...
                UpdateExposure(expoSpin,cam));


% run video stream of cam
while true
    
    camView = snapshot(cam);
    vidStream.ImageSource = camView;
    
end

% should never get here

end

function ImageCaptured(capImgBtn,imgTaken,lpTaken,cam,bp,lprNet,lpTxtArea)

capImgBtn.Value = true;     % hold state button
capImgBtn.Enable = 'off';   % disable state button so it can't be spammed
img = snapshot(cam);        % take a snapshot of current frame
imgTaken.ImageSource = img; % display the screenshot as separate img

time = datetime;          % get the current time of system
time = string(time);      % make it a string, so we can send to thingspeak

%argon_ble = ble('IoT-ANPR'); % connect to argon BLE to wakeup

% parfeval runs our ANPR function in the background
% bp = backgroundPool, n=2 (2 outputs) 
% img and lprNet as input to ANPR function.
bgProcess = parfeval(bp,@ANPR,2,img,lprNet);

% fetchOutputs is a blocking call - it waits for bgProcess to finish
% then fetches the outputs
try
    [lpTxt, lpImg] = fetchOutputs(bgProcess);

    lpTxtArea.Value = lpTxt;       % put LP text in text area
    lpTaken.ImageSource = lpImg;    % put LP img in img source

    % encrypt lpTxt with Vigenère Cipher
    cryptoTxt = Crypto(lpTxt);

    % write to thingspeak with cryptoTxt and time
    thingSpeakWrite(1917719, [cryptoTxt, time], 'WriteKey', '');
    clear argon_ble;
    argon_ble = ble('IoT-ANPR'); % connect to argon BLE to wakeup
catch
    alertMsg = {'License Plate Recognition Failed!', ... 
                'Try to adjust the camera.'};
    warndlg(alertMsg,'Warning');
end

capImgBtn.Value = false; % release state button to indicate process done
capImgBtn.Enable = 'on'; % enable state button again

end

% callback function to brightness spinner
function UpdateBrightness(brightSpin,cam)
cam.Brightness = brightSpin.Value;
end

% callback function to contrast spinner
function UpdateContrast(contraSpin,cam)
cam.Contrast = contraSpin.Value;
end

% callback function to saturation spinner
function UpdateSaturation(satSpin,cam)
cam.Saturation = satSpin.Value;
end

% callback function to hue spinner
function UpdateHue(hueSpin,cam)
cam.Hue = hueSpin.Value;
end

% callback function to sharpness spinner
function UpdateSharpness(sharpSpin,cam)
cam.Sharpness = sharpSpin.Value;
end

% callback function to gamma spinner
function UpdateGamma(gamSpin,cam)
cam.Gamma = gamSpin.Value;
end

% callback function to backlight compensation spinner
function UpdateBacklightCompensation(blcompSpin,cam)
cam.BacklightCompensation = blcompSpin.Value;
end

% callback function to exposure spinner
function UpdateExposure(expoSpin,cam)
cam.Exposure = expoSpin.Value;
end

% ANPR function
% input: img, lprNet
% outputs: lp_res, imgNP
function [lp_res, imgNP] = ANPR(img,lprNet)
    lp_res = "";    % string to put text of LP in

    % get the characters of the LP and a pic of entire LP
    [lp, NP] = Get_Numberplate(img);

    % uiimage in GUI can only display mxnx3 rgb images
    % NP is grayscale mxn -> so have to expand it to 3 dimensions
    newNP(:,:,3) = NP;
    newNP(:,:,2) = NP;
    newNP(:,:,1) = NP;
    imgNP = newNP;  % return mxnx3 rgb img but same colors as original
    
    % use lprNet to classify every 7 character
    % append every char to lp_res string
    for x = 1:7
        letter = cell2mat(lp(1,x));
        letter_resized = imresize(letter,[56 56]);
        
        % classification by CNN
        label = classify(lprNet.lprNet,letter_resized);
        lp_res = lp_res + append(char(label));
    end
end

% Crypto function
% input: plaintext
% output: ciphertext
function cryptoTxt = Crypto(lpTxt)
% key is 8 letter word, so need to append an extra letter to lpTxt
key = 'SECURITY';                                % secret key      
cipher = append(char(lpTxt),'X') + key;          % lpTxt + key
cipher = cipher(1,:) - 74;                       % -74 to stay within ASCII
cipherTxt = unicode2native(char(cipher), 'UTF-8'); % ThingSpeak uses UTF-8
cryptoTxt = char(cipherTxt);

end

% Get_NumberplateWebcam function
% input: image
% outputs: myNPs, imgNP
function [myNPs,imgNP] = Get_Numberplate(image)
%Get_Numberplate2(image) - Gets cell array of 7 characters, if can find them
%   Detailed explanation goes here
myNPs = cell(1,7); % cell array to hold the numberplate
MINIMAL_NP_HEIGHT = 20; %100 in original try.
NUMBERPLATE_RATIO_MINIMUM = 3.2; % WIDTH TO HEIGHT
NUMBERPLATE_RATIO_MAXIMUM = 4.3; % WIDTH TO HEIGHT
% Billedbehandling/preprocessing på image ----------------------------
% Lave billede om fra 3 lags rgb til gråskala
NP = rgb2gray(image);

%Lave til sort-hvid
NP = im2bw(NP, 120/255);
%NP = imbinarize(NP, 'adaptive'); % ligner ret meget NP_bw = im2bw(NP, 0.5);

% Prøve at fjerne støj med at 'åbne' billedet. (erode -> dilatere)
%Evt bruge størrelsen af billedet til at bestemme hvor stor SE skal være?
SE = ones(floor(MINIMAL_NP_HEIGHT/15));
%NP = imerode(NP, SE);
%NP = imdilate(NP, SE); % Er nu 'åbnet'
NP = imopen(NP, SE);

%Begynde analyse af objekter! --------------------------------------------
% finde antal objekter og label dem!
[NP, NumberOfObjects] = bwlabel(NP);

% Finde features af objekter med regionprops
stats = regionprops(NP, 'Orientation', 'Boundingbox', 'MajorAxisLength', 'MinorAxisLength');

%[851.601084451977,236.562167117483]
%ratio_LtoH = 851.6/236.6 % ca lig med 3.6

%Frasortere objekter baseret på features:
InterestVector = [];
for index = 1:NumberOfObjects
    if (stats(index).MinorAxisLength > MINIMAL_NP_HEIGHT) %prøve at fjerne små objekter
        ratio = stats(index).MajorAxisLength / stats(index).MinorAxisLength;
        if (ratio > NUMBERPLATE_RATIO_MINIMUM && ratio < NUMBERPLATE_RATIO_MAXIMUM)
            if (stats(index).Orientation > -10 && stats(index).Orientation < 10) % prøve at tilføje vinkel
                InterestVector = [InterestVector index]; 
            end
        end
    end 
end


%InterestVectorToBeRemoved = []; % Skal bruges til at sortere i enterestvector.


%Tjek hvad der er i InterestVector. Vis billeder.
% For example, a 2-D bounding box with value [5.5 8.5 11 14] indicates that
%the (x,y) coordinate of the top-left corner of the box is (5.5, 8.5), the 
%horizontal width of the box is 11 pixels, and the vertical height of the box is 14 pixels.
% row1 = ceil(bb(2));
% row2 = row1 + bb(3);
% column1 = ceil(bb(1));
% column2 = column1 + bb(4);
%https://se.mathworks.com/matlabcentral/answers/354984-how-to-find-the-four-coordinates-x-y-of-the-bounding-box
t = 1;  % dummy variable @rasmus
for index = 1:length(InterestVector)
    cutout = image(ceil(stats(InterestVector(index)).BoundingBox(2)):floor(stats(InterestVector(index)).BoundingBox(2)+...
    stats(InterestVector(index)).BoundingBox(4)), ...
    ceil(stats(InterestVector(index)).BoundingBox(1)):floor(stats(InterestVector(index)).BoundingBox(1)+ ...
    stats(InterestVector(index)).BoundingBox(3)) ...
    );
    
    % need this image for GUI @rasmus
    if t == 1
        imgNP = cutout;
        t = 0;
    end
    % @rasmus

    %Lave sort-hvid af udklippet stykke af oprindeligt billede
    cutout1 = imbinarize(cutout);
    %Komplementere for at få tegnene som det hvide i billedet for at kigge på dem som objekter.;
    cutout1 = imcomplement(cutout1);
    %Åbne udklippet stykke af billedet:
    % Structuring objekt:
    SE1 = ones(floor(MINIMAL_NP_HEIGHT/20)); %7 i ver1
    cutout1 = imdilate(imerode(cutout1,SE1),SE1);
    % finde labels 
    [cutout1, objectlabel]= bwlabel(cutout1);
    %figure; vislabels(test4_bw);

    stats2 = regionprops(cutout1, 'all');
    %testratios = [];        % i en test max = 2.435, min = 1.602
   
    count = 0;  % Hvor mange objekter der opfylder vores krav.

    %Tømme vector:   % clear LetterInterestVector sletter den helt
    clear LetterInterestVector;
    % letter vector til at gemme de 7 objekt numre
    LetterInterestVector = [];
    
    for index2 = 1:objectlabel
        %testratios = [testratios (stats2(index).MajorAxisLength / stats2(index).MinorAxisLength)];
        ratio = stats2(index2).MajorAxisLength / stats2(index2).MinorAxisLength;
        ori = stats2(index2).Orientation;
        
        %1.5 ser ud til at være for højt ift mange tegn. prøver 0.5
        if (ratio > 0.5 && ratio < 3.6 && ...   % burge være ori -(minus) original vinkel!
             ((ori > 70 && ori < 110 ) || ( ori < -70 && ori > -110 ))...
            && (stats2(index2).Solidity < 0.8) ...
            && ( (stats2(index2).BoundingBox(4)) >  (size(cutout,1)* 0.5) )...( stats(InterestVector(index)).BoundingBox(4) *0.5) )...
            ) %tilføje at størrelse skal være over 30 på bogstav?
            % Hvordan sortere dk mærke fra? Noget med hvor udfylgt objektet er?
            % Solidity?
            % Kigge på hvor høj bogstavet er ift det oprindelige billede? Et
            % tegn burde være en hvis procentdel af højden på nummerpladen!!!
            % Der kommer et lille objekt med i 'C:\Users\jorge\Desktop\Elektronik\5-Semester\IoT-Internet-of-Things\Projekt\Matlab\Testbilleder\test5.png'
            % Måske kan højde hjælpe, minimum 50% af nummerpladehøjde?
            
            %Tilføje til LetterInterestVector
            LetterInterestVector = [LetterInterestVector index2];
            
            % lad os tælle!
            count = count + 1;

        end
    end
    
   %myNPs = cell(1,7); Prøve at flytte længere ud!
   % Prøve at gemme figurerne som kan bruges videre.
   %Måske putte figurerne i et Cell Array som gemmes og sendes videre?
    if(count==7)
        %myNPs = cell(1,7); % prøve at putte udenfor hvis der ikke findes
        %nummerplade - pga fejl der kommer.
        for k = 1:7     %oprette cellarray med billeder. cell2mat ->extract
            % Lave om til cutout i stedet for cutout1, hvis skal være
            % grayscale?!
            myNPs(1,k) = ...
                {cutout(ceil(stats2(LetterInterestVector(k)).BoundingBox(2))...
                :floor(stats2(LetterInterestVector(k)).BoundingBox(2)+       ...
                stats2(LetterInterestVector(k)).BoundingBox(4)),             ...
                ceil(stats2(LetterInterestVector(k)).BoundingBox(1))         ...
                :floor(stats2(LetterInterestVector(k)).BoundingBox(1)+       ...
                stats2(LetterInterestVector(k)).BoundingBox(3))              ...
                )};
        end
    end
   
end
end


