function BlackHoleMinesweeper
%BLACKHOLEMINESWEEPER Play Minesweeper against a Monte Carlo alien agent.
%   Built by Dan during the pandemic (2020-2021).

rng('shuffle');
close all force

asset_dir = fullfile(fileparts(mfilename('fullpath')), 'assets');

%easy
ops.map_easy=zeros(5,5);
ops.mine_numbers_easy=[3 4];%min and max no of mines
ops.cell_width_easy=150;
ops.cell_height_easy=100;
ops.offset_easy=[475 200];

%medium
ops.map_medium=zeros(8,8);
ops.mine_numbers_medium=[7 10]; %min and max no of mines
ops.cell_width_medium=120;
ops.cell_height_medium=80;
ops.offset_medium=[300 150];

%hard
ops.map_hard=zeros(12,12);
ops.mine_numbers_hard=[15 18]; %min and max no of mines
ops.cell_width_hard=84;
ops.cell_height_hard=56;
ops.offset_hard=[325 150];

%specify media
ops.intro_image=fullfile(asset_dir,'title-screen.png');
ops.background_image=fullfile(asset_dir,'control-room.jpg');
ops.back_home_image=fullfile(asset_dir,'earth-return.jpg');
ops.black_hole_image=fullfile(asset_dir,'black-hole-loss.jpg');
ops.alien_invasion_image=fullfile(asset_dir,'alien-arrival.jpg');
ops.alien_faceoff_image=fullfile(asset_dir,'standoff.jpg');

required_assets={ops.intro_image,ops.background_image, ...
    ops.back_home_image,ops.black_hole_image, ...
    ops.alien_invasion_image,ops.alien_faceoff_image};
missing_assets=required_assets(~cellfun(@isfile,required_assets));
if ~isempty(missing_assets)
    error('BlackHoleMinesweeper:MissingAssets', ...
        'Missing game asset(s):\n%s',strjoin(missing_assets,'\n'));
end

%start game
ops.figure=figure(1);
ops.figure.Units='pixels';
ops.figure.WindowState='maximized';
ops.figure_resolution=[1024 748];

%set(ops.frame_h,'Maximized',1);
%set(gcf,'MenuBar','none');

set(gca,'DataAspectRatioMode','auto');
set(gca,'Position',[0 0 1 1]);

img=imread(ops.intro_image);
image(img);
axis image off

mission_briefing = { ...
    'MISSION BRIEFING'; ...
    'Race an alien navigator through a field of black holes and reach Earth first.'; ...
    'The alien will play the same map after you. Fewer moves wins.'};
annotation('textbox',[0.16,0.70,0.68,0.17], ...
    'String',mission_briefing, ...
    'FontSize',15,'FontWeight','bold','Color','w', ...
    'HorizontalAlignment','center','VerticalAlignment','middle', ...
    'EdgeColor',[0.2 0.8 0.85],'LineWidth',1.5, ...
    'BackgroundColor','k','FaceAlpha',0.55);

navrules=[ 'Left-click to reveal the possible number of black holes in the vicinity'...
    ' \nRight-click to flag a black hole. \nChoose the difficulty'...
    ' level using the radio buttons on the left and click Ready? to begin!'];
annotation('textbox',[0.1, 0.05, 0.85, 0.05], 'String', sprintf(navrules),'fontsize',12,'color','w', 'EdgeColor', 'none');

%easy as default case
ops.map=ops.map_easy;
ops.mine_numbers=ops.mine_numbers_easy;
ops.cell_width=ops.cell_width_easy;
ops.cell_height=ops.cell_height_easy;
ops.offset=ops.offset_easy;

%display map size/number of mines
txt = ['Easy simulates a ' num2str(size(ops.map,1)) 'x' num2str(size(ops.map,2)) ' grid with ' num2str(ops.mine_numbers(1)) '-' num2str(ops.mine_numbers(2)) ' black holes'];
ops.level=annotation('textbox',[0.1, 0.15, 0.85, 0.05], 'String', txt,'fontsize',15,'color','w', 'EdgeColor', 'none');

bg = uibuttongroup('Position',[0 0 0.1 1], 'SelectionChangedFcn',{@bselection,ops});

c1 = uicontrol(bg,'Style','radiobutton','String',{'Easy'},'Position',[10 75 100 30]);
c1.FontSize=10;
c2 = uicontrol(bg,'Style','radiobutton','String',{'Medium'},'Position',[10 100 100 30]);
c2.FontSize=10;
c3 = uicontrol(bg,'Style','radiobutton','String',{'Hard'},'Position',[10 125 100 30]);
c3.FontSize=10;
h = uicontrol('String','Ready?','Callback','uiresume(gcbf)');

%hold until confirm
uiwait(ops.figure);

if ~isempty(bg.UserData)
    ops = bg.UserData;
end

%set internal parameters
ops.p_threshold=0.1; %mcts minimum confidence no mine before chosing random
ops.flag_limit=0.9; %min prob not mine to flag
ops.num_trials=10000; %max number of MCTS playouts
ops.max_trial=100; %mean number of trials per field before making move
ops.min_trial=10; %min numb trials before guessingv
ops.player_moves=0;
ops.computer_moves=0;

%start game
play_game(ops);

close all

end

%radio buttons for selecting difficulty
function bselection(source, event, ops)

%parameters
if isequal(event.NewValue.String,{'Easy'})
    ops.mine_numbers=ops.mine_numbers_easy; %min and max no of mines
    ops.map=ops.map_easy;
    ops.cell_width=ops.cell_width_easy;
    ops.cell_height=ops.cell_height_easy;
    ops.offset=ops.offset_easy;
end

if isequal(event.NewValue.String,{'Medium'})
    ops.mine_numbers=ops.mine_numbers_medium; %min and max no of mines
    ops.map=ops.map_medium;
    ops.cell_width=ops.cell_width_medium;
    ops.cell_height=ops.cell_height_medium;
    ops.offset=ops.offset_medium;
end

if isequal(event.NewValue.String,{'Hard'})
    ops.mine_numbers=ops.mine_numbers_hard; %min and max no of mines
    ops.map=ops.map_hard;
    ops.cell_width=ops.cell_width_hard;
    ops.cell_height=ops.cell_height_hard;
    ops.offset=ops.offset_hard;
end
txt = [char(event.NewValue.String) ' simulates a ' num2str(size(ops.map,1)) 'x' num2str(size(ops.map,2)) ' grid with ' num2str(ops.mine_numbers(1)) '-' num2str(ops.mine_numbers(2)) ' black holes'];
%set(ops.level, 'textbox',[0.3, 0.1, 0.85, 0.55]);
set(ops.level,'String',txt);

source.UserData=ops;

end

function rel_coords=abs_to_rel(abs_coords, ops)
%convert absolute coordinates to relative blahalahcajfklsahsjadjsad
%rel_coords=[0.05 0.88 .4 .1];

AX=axis(gca); %can use this to get all the current axes
figure_width=AX(2)-AX(1);
figure_length=AX(4)-AX(3); 

rel_coords=[abs_coords(1)./figure_width abs_coords(2)./figure_length];

end

function draw_coordinates(ops)

AX=axis(gca); %can use this to get all the current axes
figure_width=AX(2)-AX(1);
figure_length=AX(4)-AX(3); 
  
for ii=0:10
for jj=0:10
    
    rel_coords=abs_to_rel([figure_width*ii/10,figure_length*jj/10],ops);
    annotation('textbox',[rel_coords(1),rel_coords(2),0.1,0.1],'String',[num2str(ii) '/' num2str(jj)]);
    
    text(round(figure_width*ii/10),round(figure_length*jj/10), [num2str(ii) '/' num2str(jj)],'Color','g');    
    
end
end

end

%actual game
function play_game(ops)

clf

%create map
[ops]=createmap(ops);

%to start game, open random field that's not a mine
[row, col]=find(ops.map==0);
idx=randi(size(row,1));
ops.start_field=[row(idx) col(idx)];

%frame size
ops.figure.WindowState='maximized';
set(gcf,'MenuBar','none');
set(gca,'DataAspectRatioMode','auto');
set(gca,'Position',[0 0 1 1]);

AX=axis(gca); %can use this to get all the current axes
figure_width=AX(2)-AX(1);
figure_length=AX(4)-AX(3); 

%rel_coords=abs_to_rel([figure_width*ii/10,figure_length*jj/10],ops);
%annotation('textbox',[rel_coords(1),rel_coords(2),0.1,0.1],'String',[num2str(ii) '/' num2str(jj)]);

%display move number
rel_coords=abs_to_rel([figure_width*4.5/10,figure_length*9/10],ops);
ops.m_annot=annotation('textbox',[rel_coords(1),rel_coords(2),0.1,0.07],'String','','EdgeColor','k','BackgroundColor',[50 102 150]./2^8, 'FitBoxToText','off');

ops.m_annot.Color='white';
ops.m_annot.FontSize = 10;
ops.m_annot.FontWeight = 'bold';

%display time elapsed
rel_coords=abs_to_rel([figure_width*7/10,figure_length*9/10],ops);
ops.t_annot=annotation('textbox',[rel_coords(1),rel_coords(2),0.05,0.07],'String','','EdgeColor','k','BackgroundColor',[50 102 150]./2^8, 'FitBoxToText','off');

ops.t_annot.Color='white';
ops.t_annot.FontSize = 10;
ops.t_annot.FontWeight = 'bold';

%disp when field was already uncovered
rel_coords=abs_to_rel([figure_width*4.15/10,figure_length*0.45/10],ops);
ops.au_annot=annotation('textbox',[rel_coords(1),rel_coords(2),0.15,0.07],'String','','EdgeColor','none','FitBoxToText','off','BackgroundColor','black','FaceAlpha',0.2,'HorizontalAlignment','center');

ops.au_annot.Color='white';
ops.au_annot.FontSize = 12;
ops.au_annot.FontWeight = 'bold';

%disp when each player finishes playing
rel_coords=abs_to_rel([figure_width*4.15/10,figure_length*0.45/10],ops);
ops.gameover_annot=annotation('textbox',[rel_coords(1),rel_coords(2),0.18,0.07],'String','','EdgeColor','none','FitBoxToText','off','BackgroundColor','black','FaceAlpha',0.2,'HorizontalAlignment','center');

ops.gameover_annot.Color='white';
ops.gameover_annot.FontSize = 15;
ops.gameover_annot.FontWeight = 'bold';


%play two games, one player, one computer
for j=1:2
    
    if j==1
        ops.players_turn=1;
    else
        ops.players_turn=0;
    end
    
    %initialize field
    ops.state_values=NaN(size(ops.map));
    ops.mask=ones(size(ops.map));
    ops.flags=zeros(size(ops.map));
    outcome='continue';
    ops.early_abort=0;
    
    %pick a random action
    ops.action=[ops.start_field(1) ops.start_field(2)];
    ops.type=1;
    [ops.mask, ops, outcome]=environment(ops.action, ops.mask, ops)
    
    %plot
    ops=plotfield(ops.mask, ops.display_map, ops.flags, ops);
    
    %draw_coordinates(ops);
    
    tic
    
    while isequal(outcome,'continue')
        
        %various
        ops.time_elapsed=toc;  %update time from game start
        
        txt = ['Time: \n' num2str(round(ops.time_elapsed)) ' s'];
        set(ops.t_annot,'String',sprintf(txt));
        
        %count moves, update time
        if ops.players_turn==1
            ops.player_moves=ops.player_moves+1;
            ops.player_time=ops.time_elapsed;
        else
            ops.computer_moves=ops.computer_moves+1;
            ops.computer_time=ops.time_elapsed;
        end
        
        %select action
        %action=[row column] of move, type=1 for uncover, 2 for flag;
        if ops.players_turn==1
            [ops.action ops.type]=player_input(ops);
        else
            
            AX=axis(gca); %can use this to get all the current axes
            figure_width=AX(2)-AX(1);
            figure_length=AX(4)-AX(3);
            %display mcts trial info
            %thinking
            rel_coords=abs_to_rel([figure_width*1/10,figure_length*9/10],ops);
            ops.h_annot=annotation('textbox',[rel_coords(1),rel_coords(2),0.3,0.07],'String','','EdgeColor','k','BackgroundColor',[50 102 150]./2^8, 'FitBoxToText','off');

            ops.h_annot.Color='white';
            ops.h_annot.FontSize = 10;
            ops.h_annot.FontWeight = 'bold';
            
            %disp reason why move was chosen
            rel_coords=abs_to_rel([figure_width*8/10,figure_length*1/10],ops);
            ops.c_annot=annotation('textbox',[rel_coords(1),rel_coords(2),0.1,0.07],'String','','EdgeColor','k','BackgroundColor',[50 102 150]./2^8, 'FitBoxToText','off');

            ops.c_annot.Color='white';
            ops.c_annot.FontSize = 10;
            ops.c_annot.FontWeight = 'bold';
            %decide if to run mcts:
            %    if all(isnan(ops.state_values(:)))... %not run before
            %            || max(ops.state_values,[],'all') < ops.flag_limit ... %nothing to flag
            %           && min(ops.state_values,[],'all') > ops.p_threshold %and nothing to uncover
            
            random_field=ops.state_values; %filter flagged fields from state-value based decision to run mcts
            random_field(ops.flags==1)=NaN;
            
            if all(isnan(ops.state_values(:))) || max(random_field,[],'all') <= ops.flag_limit || ops.early_abort <= ops.min_trial
                %text according to: if mask is not zero use mask value, map value otherwise
                %mask - 0-8 number of mines, -1 unvisited, 10 flag
                masked_map=mask_map(ops);
                ops=mcts_ms(masked_map,ops);
            else
                pause(0.5);
            end
            
            
            %computer select action
            [ops.action ops.type]=auto_input(ops);
            
        end
        
        %change state
        [ops.mask, ops, outcome]=environment(ops.action, ops.mask, ops);         %environment(action, type - uncover/flag, mask, ops)
        
        %plot update
        plotfield(ops.mask, ops.display_map, ops.flags, ops);
        
    end
    
    %this sequence displays messages after each player completes the map
    %requires button-click to proceed
    
    if isequal(outcome, 'player_hole') %player enters black hole
        txt_control='Mission in danger. You have been pulled into a black hole!';
    end
    
    if isequal(outcome,'player_flags') %player solved all
        txt_control='On return route to Earth! Have you done enough?';
    end
    
    if isequal(outcome,'computer_flags_player_hole') %computer solved all
        txt_control='Alien vessel inbound...is Earth at risk?';
    end
    
    if isequal(outcome,'computer_flags_player_flags') %computer solved all
        txt_control='Alien vessel inbound...is Earth at risk?';
    end
    
    if isequal(outcome, 'computer_hole_player_flags') %computer enters black hole
        txt_control='Possible Evasion. Enemy ship has entered a black hole!';
    end
    
    if isequal(outcome, 'computer_hole_player_hole') %computer enters black hole
        txt_control='Possible Evasion. Enemy ship has entered a black hole!';
    end
    
    set(ops.gameover_annot,'String',sprintf(txt_control));
    pos=[round(ops.figure.Position(1,3)/2-25) ops.offset(2)/10 50 30];
    h = uicontrol('Position',pos,'String','OK', 'Fontsize', 10,'Callback','uiresume(gcbf)');
    uiwait(ops.figure);
    delete(h);
    
end

%outcome is not 'continue'
ops=gameover(ops,outcome);

end

%this function displays summary message and adds an image
%after computer finished

function [ops]=gameover(ops,inputvariable)

if isequal(inputvariable, 'computer_flags_player_hole')
    
    if isnan(ops.player_time) %player enters black hole
        txt_result='The alien lifeform made it to Earth. MISSION FAILURE!';
        final_image=ops.black_hole_image;
    end
    
    
elseif isequal(inputvariable, 'computer_flags_player_flags')
        
    if ops.computer_moves > ops.player_moves %player less moves than computer
       txt_result='You made it back to Earth before the aliens. MISSION ACCOMPLISHED!';
       final_image=ops.back_home_image;
        %end
        
    elseif ops.computer_moves < ops.player_moves %computer less moves than player
        txt_result='The alien lifeform made it to Earth before you did. MISSION FAILURE!';
        final_image=ops.alien_invasion_image;
        
    elseif ops.computer_moves == ops.player_moves %draw
        txt_result='You have both arrived at Earth. Prepare for a FACEOFF!';
        final_image=ops.alien_faceoff_image;
        
    end
    
elseif isequal(inputvariable,'computer_hole_player_flags') %computer enters black hole
    
    txt_result='You made it back to Earth while the aliens went through a black hole. MISSION ACCOMPLISHED!';
    final_image=ops.back_home_image;
    
elseif isequal(inputvariable,'computer_hole_player_hole') %both enter black hole
    
    txt_result='You have both been pulled into black holes. And while EARTH IS SAFE, could you possibly escape before reaching the event horizon?';
    final_image=ops.black_hole_image;
    
end

clf;

ops.figure.WindowState='maximized';
set(gcf,'MenuBar','none');
set(gca,'DataAspectRatioMode','auto');
set(gca,'Position',[0 0 1 1]);

img=imread(final_image);
image(img);
axis image off

AX=axis(gca); %can use this to get all the current axes
figure_width=AX(2)-AX(1);
figure_length=AX(4)-AX(3); 

%for final game results
rel_coords=abs_to_rel([figure_width*2/10,figure_length*8/10],ops);
ops.txt_result_annot=annotation('textbox',[rel_coords(1),rel_coords(2),0.6,0.2],'String','','EdgeColor','none','FitBoxToText','off','BackgroundColor','black','FaceAlpha', 0.2,'HorizontalAlignment','center');

ops.txt_result_annot.Color='white';
ops.txt_result_annot.FontSize = 45;
ops.txt_result_annot.FontWeight = 'bold';

%for final game summary
rel_coords=abs_to_rel([figure_width*2/10,figure_length*0/10],ops);
ops.txt_summary_annot=annotation('textbox',[rel_coords(1),rel_coords(2),0.25,0.2],'String','','EdgeColor','none','FitBoxToText','off','BackgroundColor','black','FaceAlpha', 0.2);

ops.txt_summary_annot.Color='white';
ops.txt_summary_annot.FontSize = 20;
ops.txt_summary_annot.FontWeight = 'bold';

%draw_coordinates(ops);

txt_summary={['Number of player moves: ' num2str(ops.player_moves)]; ['Number of computer moves: ' num2str(ops.computer_moves)];...
    ['Your time: ' num2str(round(ops.player_time)) 's']; ['Their time : ' num2str(round(ops.computer_time)) 's']};

set(ops.txt_result_annot,'String',sprintf(txt_result));
set(ops.txt_summary_annot,'String',(txt_summary));

pause(6);

delete(ops.txt_result_annot);
delete(ops.txt_summary_annot);

rel_coords=abs_to_rel([figure_width*2/10,figure_length*8/10],ops);
ops.MCTSplay_annot=annotation('textbox',[rel_coords(1),rel_coords(2),0.6,0.2],'String','','EdgeColor','none','FitBoxToText','off','BackgroundColor','black','FaceAlpha', 0.2,'HorizontalAlignment','center');

ops.MCTSplay_annot.Color='white';
ops.MCTSplay_annot.FontSize = 35;
ops.MCTSplay_annot.FontWeight = 'bold';

MCTSplay='Find out how the alien life form solves the map';
set(ops.MCTSplay_annot,'String',(MCTSplay));
%    txt_play={['The life 
%set(ops.txt_play_annot, 'String',sprintf(txt_play));
pause(3);

end

function [action type]=player_input(ops)
%player needs to click on undiscovered field - left click uncover, right
%click flag, press other key - use mcts
action=0;
type=[];

while action==0
    
    w=waitforbuttonpress;
    
    mouse_coordinates=get(gca, 'CurrentPoint');
    
    if w==0
        %make sure coordinates within fig
        if mouse_coordinates(1,1) <= length(ops.map(:,1))*ops.cell_width+ops.offset(1)
            if  mouse_coordinates(1,1) >= 1
                if mouse_coordinates(1,2) <= length(ops.map(1,:))*ops.cell_height+ops.offset(2)
                    if mouse_coordinates(1,2) >= 1
                        
                        action(1)=floor((mouse_coordinates(1,1)-ops.offset(1))/ops.cell_width)+1;
                        action(2)=floor((mouse_coordinates(1,2)-ops.offset(2))/ops.cell_height)+1;
                        
                        
                        %determine which button clicked
                        click_type=get(gcf,'SelectionType');
                        
                        if strcmp(click_type,'normal') %uncover field
                            type=1;
                            
                            
                        elseif strcmp(click_type,'alt') %flag mine
                            
                            type=2;
                            
                            if ops.mask(action(1),action(2))==0
                                %clicked on unmasked field, can't flag
                                action=0;
                            end
                        end
                        
                        
                    end
                end
            end
        end
        
    end
end


end

function [action type ops]=auto_input(ops)
%init
action=0; %action - field x,y
type=0; %1 to uncover, 2 to flag

%input:
%ops.state_values; %matrix with prob of mine / nan if unknown or already
%uncovered

%policy
%check if can flag mines
%if nothing to flag, uncover safe fields
%pick random field

%could unflag by checking if flagged cells have low state value

if max(ops.state_values(ops.flags==0),[],'all') >= ops.flag_limit  %find if something unflagged to flag - certain mine
    
    type=2;
    
    state_value_check_flags=ops.state_values; %prevent reflagging by setting flagged state values zero
    state_value_check_flags(ops.flags==1)=0;
    
    [row, col] = find(state_value_check_flags==max(state_value_check_flags,[],'all'));
    
    ridx=randperm(length(row),1);
    action=[row(ridx) col(ridx)];
    
    txt = ['Flag field ' num2str(row(ridx)) '/' num2str(col(ridx)) '. \nProbability of ' num2str(round(ops.state_values(row(ridx),col(ridx)))) ' to be a black hole. \nCertainty: ' num2str(ops.mcts_trials(row(ridx),col(ridx)))];
    set(ops.c_annot,'String',sprintf(txt));
    
elseif min(ops.state_values,[],'all') < ops.p_threshold  %uncover best evaluated field- override safety if only unsafe fields left
    
    type=1;
    random_field=ops.state_values;
    random_field(ops.mask==0)=NaN; %don't try to uncover unmasked fields
    
    [row, col] = find(random_field==min(random_field,[],'all'));
    
    ridx=randperm(length(row),1);
    action=[row(ridx) col(ridx)]; %chose action - field to uncover
    
    txt = ['Uncover field ' num2str(row(ridx)) '/' num2str(col(ridx)) '. \nProbability of ' num2str(round(ops.state_values(row(ridx),col(ridx)))) ' to be a black hole. \nCertainty: ' num2str(ops.mcts_trials(row(ridx),col(ridx)))];
    set(ops.c_annot,'String',sprintf(txt));
    
    ops.state_values(row(ridx),col(ridx))=NaN;
    
else %uncover random covered field since state value fields aren't safe (not flagged)
    
    type=1;
    
    random_field=ops.mask; %only uncover masked fields
    random_field(ops.flags==1)=0; %ignore flagged fields
    
    if isempty(find(random_field>0)) %test if now no fields are left. if so, undo
        random_field(ops.flags==1)=1;
    end
    
    random_field(find(ops.state_values>0))=0; %ignore fields with state value since they are bad
    
    if isempty(find(random_field>0)) %test if now no fields are left. if so, undo and pick lowest state value field
        
        random_field=ops.state_values;
        random_field(ops.mask==0)=NaN; %don't try to uncover unmasked fields
        
        [row, col] = find(random_field==min(random_field,[],'all'));
        
        ridx=randperm(length(row),1);
        action=[row(ridx) col(ridx)]; %chose action - field to uncover
        
        txt = ['Uncover field ' num2str(row(ridx)) '/' num2str(col(ridx)) '. \nProbability of ' num2str(round(ops.state_values(row(ridx),col(ridx)))) ' to be a black hole. \nCertainty: ' num2str(ops.mcts_trials(row(ridx),col(ridx)))];
        set(ops.c_annot,'String',sprintf(txt));
        
        ops.state_values(row(ridx),col(ridx))=NaN;
        
    else
        %fields outside bad state values left
        [row, col] = find(random_field); %only pick from fields outside state value (know it's bad) and unmasked
        
        ridx=randperm(length(row),1);
        action=[row(ridx) col(ridx)];
        
        txt = ['Uncover random field ' num2str(row(ridx)) '/' num2str(col(ridx)) '. \nProbability of ' num2str(round(ops.state_values(row(ridx),col(ridx)))) ' to be a black hole.'];
        set(ops.c_annot,'String',sprintf(txt));
        
        ops.state_values(row(ridx),col(ridx))=NaN;
    end
end

end

function masked_map=mask_map(ops)

%text according to: if mask is not zero use mask value, map value otherwise
%mask - 0-8 number of mines, -1 unvisited, 10 flag
for j = 1:length(ops.mask(:,1))
    for l = 1:length(ops.mask(1,:))
        
        if ops.mask(j,l)~=0
            %field is still masked
            masked_map(j,l)=-1;
        else
            masked_map(j,l)=ops.display_map(j,l);
        end
        
    end
end

end

%masked map is showing unmasked map numbers - 0-8 for surrounding mines, -1 for no info
%state value is likelyhood for mine at given field
function ops=mcts_ms(vis_matrix, ops)
%input vis_matrix:
%0-8 for uncovered fields indicating number of surrounding mines,-1 for masked

%create set of linear equations for every field of vis_matrix:
%vis_matrix(m,n)=sum(put_matrix(surrounding(m,n))),

%solve this in put_matrix, (only allow 1 or 0 as entries) -put_matrix: 1 for mine, 0 for safe

%e.g.
%3x3 map with one uncovered field
%ops.map - showing mines (not visible)
% 0 0 0
% 0 1 0
% 0 0 0

%ops.mask - what fields are uncovered
% 1 1 1
% 1 1 0
% 1 1 1

%vis_matrix adjacent mines/covered fields - this is what we see
% x x x
% x x 1
% x x x

%translates to equation (just one):
%a_coeff define which fields participate in equation (surround a non zero entry in vis_matrix).
%it has as many columns as there are entries in vis_matrix,
%and as many rows as there are equations - non-zero entries in vis_mat
%b_result reflects the non zero entries in vis_mat.
%b_results=sum(a_coeff)

%a_coeff = 0 1 1 0 1 0 0 1 1
%b_results = 1

%system to solve (find entries in put_matrix solving this equation):
%b_results=sum(a_coeff.*put_matrix)

%one solution of put_matrix is:
%0 0 1
%0 0 0
%0 0 0

%this system has just one row since only one field uncovered.
%usually there are more rows

%calculate prob of mine present in given field,
%estimated by fraction of solutions with mine in that field

%return this as state value

%---------------------------------------turn vis_matrix into set of linear
%equations defined by b_results and a_coeff
txt = 'Thinking... ';
set(ops.h_annot,'String',txt);
drawnow;

%these are the eight fields surrounding each point
checkfields=[-1 -1; 0 -1; 1 -1; 1 0; 1 1; 0 1; -1 1; -1 0];

%only field in vis_matrix >0 make for equation

%initialize
%this contains trial solutions for locations of mines
put_matrix=zeros(length(vis_matrix(:,1)),length(vis_matrix(1,:)));

%a_coeff defines equations in matrix form. it has as many columns as there
%are entries in put_mat, and as many rows as there are equations - entries
%in vis_mat
%a-coeff = 1, if a cell participates in an equation
a_coeff=zeros(length(find(vis_matrix>0)),length(vis_matrix(:,1))*length(vis_matrix(1,:)));

%b_result defines entries in vis_mat in vector form, corresponding to each row in a_coeff
b_result=zeros(length(find(vis_matrix>0)),1);

current_row=0;
%consider each field in the vis_matrix
for j=1:length(vis_matrix(:,1))
    for k=1:length(vis_matrix(1,:))
        
        %fields indicating they are next to mines (have number larger than 0) make for new equation
        if vis_matrix(j,k) > 0
            %each field in vis_matrix >0 is an equation, each equation gets a row
            current_row=current_row+1;
            
            %create result vector from vis matrix, containing number of
            %surrounding mines around current field
            b_result(current_row)=vis_matrix(j,k);
            
            %every field around cursor can participate in equation
            for l=1:length(checkfields(:,1))
                
                %field currently checked
                cursor(1)=j+checkfields(l,1);
                cursor(2)=k+checkfields(l,2);
                
                %field inside map
                if cursor(1)>=1 && cursor(2)>=1 && cursor(1)<=length(vis_matrix(:,1)) && cursor(2)<=length(vis_matrix(1,:))
                    
                    %field masked (-1 on vis_matrix)
                    if vis_matrix(cursor(1),cursor(2))==-1
                        %add entry
                        %row represents equation number, column represents
                        %which cell is considered
                        current_column=cursor(1)+(cursor(2)-1)*length(vis_matrix(:,1));
                        a_coeff(current_row,current_column)=1;
                        
                    end
                    
                end
                
            end
        end
    end
end

%if nothing uncovered yet, exit and return nans
if isempty(a_coeff)
    MCTS_prob=NaN(size(a_coeff));
    return
end

%-------------------------now solve the assembled system with MCTS
%strategy
%for each equation/row: pick #b_result entries of a_coeff, set to one ('has mine')
%check if system solved
%if so, count times an entry/cell was set to one
%count total successful trials
%for each participating cell, divide #entries set by #succesful trials for
%state_values to get mine probability estimate

%for better perfomance:
%identify subsets of equations that are linked and solve them separately. e.g.
%vis_matrix adjacent mines/covered fields - this is what we see
% x x x 1
% x x x x
% 1 x x x
% 1 x x x

%would result in three equations and two separate, internally linked systems
%a_coeff(1,1:16) = [0 0 1 1 0 0 1 1 0 0 0 0 0 0 0 0];
%b_results(1,1) = 1;

%a_coeff(2,1:16) = [0 0 0 0 1 1 0 0 0 1 0 0 0 1 0 0];
%b_results(1,2) = 1;

%a_coeff(3,1:16) = [0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0];
%b_results(1,3) = 1;

%make a linked matrix - this shows which equations are _pairwise_ linked
%each equation has one row. each column in that row is 1 if the equation
%linked to an equation in the row corresponding to that column.
%for equations to be linked, they must use at least once the same a_coeff (have them set to 1)
%multiplying the a_coeff between rows indicates that
linked_matrix=zeros(length(b_result(:,1)),length(b_result(:,1)));
%compare each equation with all others
for j=1:length(b_result)
    for k=1:length(b_result)
        if sum(a_coeff(j,:).*a_coeff(k,:)) > 0
            linked_matrix(j,k)=1;
        end
    end
end
%linked matrix here is below.
%1 0 0
%0 1 1
%0 1 1
%indicating equation 1 not linked to 2 or 3, equation 2 linked to 2 and 3,
%equation 3 linked to 2 and 3

%expand pairwise linked matrix to show all equations linked (not just pair wise)
%say, equation 3 was linked to equation 4. Now equations 2,3,4 are all
%linked. This would not be reflected in the pairwise linked matrix.
%graph - represents matrix as connected nodes
%conncomp - returns connected graph components
bins = conncomp(graph(linked_matrix));
%e.g. bins=1 2 2 - equation 1 belongs to node 1, equations 2 and 3 belong to node 2

%initialize
mcts_counts=zeros(size(a_coeff(1,:))); %vector counting how often field had mine
mcts_trials=mcts_counts;
succ_trials=0; %number of trials random solutions worked out
mcts_finished=0;

%each trial only solves one set of linked equations
for j=1:ops.num_trials
    
    %pick a random equation
    currentset = randperm(size(linked_matrix,1),1);
    
    %now list all participating (ie linked) equations of selected equation
    rows=find(bins==bins(currentset));
    
    rows = rows(randperm(size(rows, 2))); %randomize order
    
    put_mcts=zeros(size(a_coeff)); %matrix representing which fields potentially have mines in current trial
    
    %solve each equation in current set of linked equations
    for l=1:length(rows)
        
        k=rows(l); %iterate through each entry in row - k represents current row
        
        %list wich fields participate in current equation
        idx_part_fields=find(a_coeff(k,:)==1);
        
        %select b_result(k) entries of idx to be 1 in put_mcts(k)
        %(we know there's b_result(k) mines in fields where a_coeff(k)==1
        %i.e. randomly pick appropriate number of mines surrounding each
        %field - subtract no of pariticipating fields that were already set to 1 (as listed in put_mcts):
        %datasample(idx,count) - pick count samples from idx
        num_to_select=max(b_result(k)-sum(put_mcts(k,:).*a_coeff(k,:)),0);
        sample_order=randperm(numel(idx_part_fields),num_to_select);
        idx_selected=idx_part_fields(sample_order);
        
        %set corresponding fields to 1 (in all equations (i.e. field has mine), counting in surrounding fields)
        put_mcts(:,idx_selected)=1;
        
        %check if selection valid in current and all previous equations
        for j2=1:l
            flag=0;
            if b_result(rows(j2))~=sum(put_mcts(rows(j2),:).*a_coeff(rows(j2),:))
                flag=1;
                break %invalid trial
            end
        end
        if flag==1
            break
        end
        
    end
    
    %check if system is solved - trial succesfull
    if sum(a_coeff(rows,:).*put_mcts(rows,:),2)==b_result(rows)
        
        %if so, increase counts for cells that were set to one (entries should be identical in rows)
        mcts_counts(find(sum(put_mcts,1)>0))=mcts_counts(find(sum(put_mcts,1)>0))+1;
        
        %increase count of successful trials for all participating cells
        part_fields=find(sum(a_coeff(rows,:),1)>0);
        mcts_trials(part_fields)=mcts_trials(part_fields)+1;
        
        %count overall successful trials
        succ_trials=succ_trials+1;
        
    end
    
    %display update every 1000th trial
    if mod(j,1000)==0
        txt = ['MCTS simulating, trial: \n' num2str(j) ', solving ' num2str(length(unique(bins))) ' independent system(s).'];
        set(ops.h_annot,'String',sprintf(txt));
        drawnow;
    end
    
    %update least number of trials of any cell that participated
    ops.early_abort=min(mcts_trials(find(sum(a_coeff,1)>0)));
    
    %break early if at least min_trial succ trials for each
    if min(mcts_trials(find(sum(a_coeff,1)>0))) > ops.max_trial
        
        mcts_finished=1;
        
        break
        
    end
    
    
end

%calculate state values
%divide #one entries by #succesful trials for set
MCTS_prob=mcts_counts./mcts_trials;
MCTS_prob(sum(a_coeff,1)==0)=NaN;
MCTS_prob=reshape(MCTS_prob,[length(vis_matrix(1,:)),length(vis_matrix(:,1))]);

%return number of trials each field participated in
ops.mcts_trials=reshape(mcts_trials,[length(vis_matrix(1,:)),length(vis_matrix(:,1))]);
%return results
ops.state_values=MCTS_prob;

%MCTS annotation
if mcts_finished==1
    txt = ['MCTS finished after ' num2str(j) ' trials, \nyielding at least ' num2str(ops.early_abort) ' trials for each field.'];
else
    txt = ['MCTS aborted, yielding at least ' num2str(ops.early_abort) ' trials for each field.'];
end

set(ops.h_annot,'String',sprintf(txt));

drawnow;

end

%createmap
%input: action from player (x,y)
%returns: %uses ops.map to return mask, displaying flood map
function [ops]=createmap(ops)
ops.map=zeros(size(ops.map)); %zero empty, one minef
mine_fields=randi([1 numel(ops.map)],[randi([ops.mine_numbers(1) ops.mine_numbers(2)]) 2]);

possible_mines=ops.mine_numbers(1):ops.mine_numbers(2);
minenumber=possible_mines(randperm(numel(possible_mines),1));

mine_fields=zeros(numel(ops.map),1);
mine_fields(randperm(numel(ops.map),minenumber))=1;
mine_fields=reshape(mine_fields,size(ops.map));

ops.map=mine_fields;

%eight fields surrounding a point
checkfields=[-1 -1; 0 -1; 1 -1; 1 0; 1 1; 0 1; -1 1; -1 0];
ops.display_map=ops.map;

%run cursor across every field
for k=1:length(ops.map(:,1))
    for l=1:length(ops.map(1,:))
        
        cursor(1:2)=[k l];
        
        %ignore cursor on mine
        if ops.map(cursor(1),cursor(2))==0
            
            %check each 8 fields surrounding cursor, sum up mines
            for j=1:length(checkfields)
                
                %check if cursor+checkfields(j) is within bounds of map
                if cursor(1)+checkfields(j,1) >= 1 && cursor(2)+checkfields(j,2) >= 1
                    if cursor(1)+checkfields(j,1) <= length(ops.map(1,:)) && cursor(2)+checkfields(j,2) <= length(ops.map(:,1))
                        
                        %create pixel number at cursor location if mine found
                        if ops.map(cursor(1) + checkfields(j,1), cursor(2)+checkfields(j,2))==1
                            
                            ops.display_map(cursor(1), cursor(2))=ops.display_map(cursor(1), cursor(2))+1; %count encountered mine
                            
                        end
                        
                    end
                end
            end
        else
            %show mine as 9 on display map
            ops.display_map(cursor(1), cursor(2))=9;
        end
    end
    
end

end

%input: action from player (x,y), mask, map
%returns: %changes mask to uncover flood map
function [mask, ops, outcome]=environment(action, mask, ops)

cursor(1:2)=action;

outcome='continue';

%eight fields surrounding a point
checkfields=[-1 -1; 0 -1; 1 -1; 1 0; 1 1; 0 1; -1 1; -1 0];

%check action field for mine
if ops.type==1 %uncover field
    
    %uncover fields if encountered unvisited fields (still masked)
    if mask(cursor(1),cursor(2))~=0
        
        %remove flag
        ops.flags(cursor(1),cursor(2))=0;
        
        unvisited=action;
        
        while ~isempty(unvisited)
            
            %pick a random entry from unvisted list
            index=randi(size(unvisited,1));
            cursor(1:2)=unvisited(index,:);
            
            %remove entry from unvisited list
            unvisited(index,:)=[];
            
            %unmask current cell
            ops.mask(cursor(1), cursor(2))=0;
            
            %check map around cursor for fields to be uncovered (0 on display_map)
            for j=1:length(checkfields) %check each 8 fields surrounding cursor, sum up mines
                
                %check if cursor+checkfields(j) is within bounds of map
                if cursor(1)+checkfields(j,1) >= 1 && cursor(2)+checkfields(j,2) >= 1
                    if cursor(1)+checkfields(j,1) <= length(ops.mask(1,:)) && cursor(2)+checkfields(j,2) <= length(ops.mask(:,1))
                        
                        %populate list with unvisited coordinates surrounding
                        %currnet point, if:
                        %map at that surrounding is smaller than 9 - don't show mines
                        %mask at that surrounding is not zero
                        %map at current is 0
                        if ops.map(cursor(1)+checkfields(j,1),cursor(2)+checkfields(j,2)) < 9 &&...
                                ops.mask(cursor(1)+checkfields(j,1),cursor(2)+checkfields(j,2))~=0 &&...
                                ops.display_map(cursor(1),cursor(2))==0
                            
                            if ~isempty(unvisited)
                                if max(ismember(unvisited,cursor+checkfields(j,:),'rows'))<1
                                    unvisited(end+1,1:2)=[cursor(1)+checkfields(j,1),cursor(2)+checkfields(j,2)];
                                end
                            else
                                unvisited(1:2)=[cursor(1)+checkfields(j,1),cursor(2)+checkfields(j,2)];
                            end
                            
                        end
                        
                    end
                end
            end
            
        end
        
        
    else
        %tried to uncover already open field
        txt = ['Field already uncovered, try again'];
        set(ops.au_annot,'String',sprintf(txt));
        %annotation('textbox',[0.8 0.15 0.5 .1],'String','Field already uncovered','EdgeColor','none', 'color', 'w', 'Fontsize', 12);
        %h = uicontrol('String','Already uncovered','Callback','uiresume(gcbf)','Position',[300 75 150 30]);
        
        %hold for x seconds
        pause(3);
        set(ops.au_annot,'String','');
    end
end

if ops.type==2 %flag
    
    %flag covered field
    if ops.type==2
        
        if ops.flags(action(1),action(2))==1
            ops.flags(action(1),action(2))=0; %erase flag
        else
            ops.flags(action(1),action(2))=1; %set flag
        end
    end
end

%check flag outcome
if isequal(ops.flags,ops.map) %someone won
    
    ops.game_over=1;
    
    if ops.players_turn==1
        
        outcome='player_flags';
        
    else
        
        if isnan(ops.player_time)
            outcome='computer_flags_player_hole';
        else
            outcome='computer_flags_player_flags';
        end
        
    end
    
end

if ops.map(action(1), action(2))==1 && ops.type==1 %someone hit mine
    
    mask(action(1), action(2))=0;
    ops.mask=mask;
    ops.game_over=1;

    if ops.players_turn==1
        outcome='player_hole';
        ops.player_time=NaN;
    else
        if isnan(ops.player_time)
            outcome='computer_hole_player_hole';
        else
            outcome='computer_hole_player_flags';
        end
        
        ops.computer_time=NaN;
    
    end
        
end

end

%plot map where mask is 0, plot mask otherwise
function ops=plotfield(mask, map, flags, ops)

ops.figure.WindowState='maximized';
set(gcf,'MenuBar','none');
cla(gca);
hold off
set(gca,'DataAspectRatioMode','auto');
set(gca,'Position',[0 0 1 1]);

%draw white rectangle over everything
%rectangle('Position',[0,0,ops.cell_width*length(mask(:,1)),ops.cell_height*length(mask(1,:))],'FaceColor',[1 1 1]);
showimage=imread(ops.background_image);
ops.showimage=showimage;
image(showimage);
axis image off

%draw dark rectangle behind field
rectangle('Position', [ops.offset(1), ops.offset(2), ops.cell_width*size(ops.map,1), ops.cell_height*size(ops.map,2)], 'FaceColor', [0 0 0 0.4]);
%%
hold on
%draw lines around cells
for j = 1:length(ops.mask(:,1))+1
    %y-lines
    plot((j-1)*ops.cell_width*[1 1]+ops.offset(1),[0 length(ops.mask(1,:))*ops.cell_height]+ops.offset(2),'w','LineWidth',1.5); hold on
end
for j = 1:length(ops.mask(:,1))+1
    %x-lines
    plot([0 length(ops.mask(:,1))*ops.cell_width]+ops.offset(1),(j-1)*ops.cell_height*[1 1]+ops.offset(2),'w','LineWidth',1.5); hold on
end

%color fields with state value heatmap
%color masked fields state_values, if field exits
if isfield(ops,'state_values')
    %create color map
    cmap = hot(256);
    %draw squares in color
    for j = 1:length(ops.mask(:,1))
        for l = 1:length(ops.mask(1,:))
            if ops.mask(j,l)==1
                if ~isnan(ops.state_values(j,l))
                    rectangle('Position',[(j-1)*ops.cell_width+ops.offset(1),(l-1)*ops.cell_height+ops.offset(2),ops.cell_width,ops.cell_height],'FaceColor',cmap(round((1-ops.state_values(j,l))*255)+1,1:3),'LineWidth',2, 'EdgeColor','w');
                end
            end
        end
    end
    
    %plot legend showing min probablilities of colors
    if ops.players_turn==0
        
        AX=axis(gca); %can use this to get all the current axes
        figure_width=AX(2)-AX(1);
        figure_length=AX(4)-AX(3); 
        
        xyhw=[((size(ops.mask,1)+1)*ops.cell_width)+ops.offset(1) ops.offset(2) ops.cell_width 3*ops.cell_height]; 
        edges_x=[xyhw(1) xyhw(1) xyhw(1)+xyhw(3) xyhw(1)+xyhw(3)]; 
        edges_y=[xyhw(2) xyhw(2)+xyhw(4) xyhw(2)+xyhw(4) xyhw(2)];  
        c_s=[1 255 255 1];
        patch(edges_x,edges_y,c_s,'FaceColor','interp','EdgeColor','none');
        colormap hot(256)
        x_coords=(size(ops.mask,1)+1)*ops.cell_width+ops.offset(1);
        y_coords=0.92*ops.offset(2);
        text(x_coords-10, y_coords, '1','color','w','Fontsize', 15, 'Fontweight', 'bold');
        x_coords=(size(ops.mask,1)+1)*ops.cell_width+ops.offset(1);
        y_coords=1.07*ops.offset(2)+ 3*ops.cell_height;
        text(x_coords-10, y_coords, '0','color','w','Fontsize', 15, 'Fontweight', 'bold');
        x_coords=(size(ops.mask,1)+1)*ops.cell_width+ops.offset(1);
        y_coords=1.50*ops.offset(2)+ 3*ops.cell_height;
        text(x_coords, y_coords, 'Black hole probability','color','w','Fontsize', 15, 'Fontweight', 'bold');
        
    end
end

%plot number of mines, flags
%text according to: if mask is 1 use mask value, map value otherwise
for j = 1:length(ops.mask(:,1))
    for l = 1:length(ops.mask(1,:))
        
        if mask(j,l)==1
            %field is still masked
            %do nothing if it's just mask
            %text((j-0.5)*ops.cell_width,(l-0.5)*ops.cell_height,num2str(mask(j,l)));
            %if manual flag set, show flag
            if ops.flags(j,l)==1
                text((j-0.6)*ops.cell_width+ops.offset(1),(l-0.6)*ops.cell_height+ops.offset(2),string(char(182)),'color','w','Fontsize', 18);
            end
        else
            %field is unmasked
                        
            %map shows mine adjacent
            if map(j,l) >= 0 && map(j,l)<=8
                %print field content - different color if computer's turn
                %and for last action
                if isequal(ops.action,[j l]) && ops.players_turn==0
                    text((j-0.6)*ops.cell_width+ops.offset(1),(l-0.6)*ops.cell_height+ops.offset(2),num2str(map(j,l)),'color','r','Fontsize', 18);
                else
                    text((j-0.6)*ops.cell_width+ops.offset(1),(l-0.6)*ops.cell_height+ops.offset(2),num2str(map(j,l)),'color','w','Fontsize', 18);
                end
                
            end
            %hit mine
            if map(j,l) ==9
                text((j-0.6)*ops.cell_width+ops.offset(1),(l-0.6)*ops.cell_height+ops.offset(2),'\oplus','color','w', 'Fontsize', 18);
            end
        end
        
    end
end

txt = ['Moves: \nYours: ' num2str(ops.player_moves) ' Theirs: ' num2str(ops.computer_moves)];
set(ops.m_annot,'String',sprintf(txt));

end


