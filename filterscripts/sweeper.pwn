#define 	FILTERSCRIPT
#include 	<a_samp>

#define 	PRESSED(%0) 		(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define     MONEY_PER_METER    	(1.7)  	// will get multiplied by distance player cleaned
#define     UPDATE_TIME         (500)   // in milliseconds

new
	bool: SweeperJob[MAX_PLAYERS] = {false, ...},
	SweeperUpdate[MAX_PLAYERS] = {0, ...},
	SweeperDistance[MAX_PLAYERS] = {0, ...},
	Float: SweeperLastPos[MAX_PLAYERS][3],
	PlayerText: SweeperText[MAX_PLAYERS];

stock ResetSweeperInfo(playerid, bool: removeTD = false)
{
    SweeperJob[playerid] = false;
    SweeperUpdate[playerid] = 0;
	SweeperDistance[playerid] = 0;
	if(removeTD) PlayerTextDrawDestroy(playerid, SweeperText[playerid]);
	return 1;
}

public OnFilterScriptExit()
{
	for(new i; i < GetMaxPlayers(); ++i)
	{
	    if(!IsPlayerConnected(i)) continue;
	    if(SweeperJob[i]) ResetSweeperInfo(i, true);
	}
	
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	ResetSweeperInfo(playerid);
	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(SweeperJob[playerid] && GetVehicleModel(GetPlayerVehicleID(playerid)) == 574 && SweeperUpdate[playerid] < tickcount())
	{
		SweeperUpdate[playerid] = tickcount()+UPDATE_TIME;
		SweeperDistance[playerid] += floatround(GetPlayerDistanceFromPoint(playerid, SweeperLastPos[playerid][0], SweeperLastPos[playerid][1], SweeperLastPos[playerid][2]));
		GetPlayerPos(playerid, SweeperLastPos[playerid][0], SweeperLastPos[playerid][1], SweeperLastPos[playerid][2]);
		
		new string[64];
		format(string, sizeof(string), "~b~~h~Sweeper Job~n~~n~~w~Cleaned: ~y~%d Meters", SweeperDistance[playerid]);
		PlayerTextDrawSetString(playerid, SweeperText[playerid], string);
	}
	
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(newstate == PLAYER_STATE_DRIVER && GetVehicleModel(GetPlayerVehicleID(playerid)) == 574 && !SweeperJob[playerid]) GameTextForPlayer(playerid, "~n~~n~~w~Press ~y~~k~~TOGGLE_SUBMISSIONS~ ~w~to start~n~~b~~h~~h~Sweeper Job", 3000, 3);
	if(oldstate == PLAYER_STATE_DRIVER && SweeperJob[playerid])
	{
	    new money = floatround(SweeperDistance[playerid] * MONEY_PER_METER), string[80];
	    format(string, sizeof(string), "~n~~n~~w~Distance Cleaned: ~b~~h~~h~%d Meters~n~~w~Earned ~g~~h~~h~$%d", SweeperDistance[playerid], money);
	    GameTextForPlayer(playerid, string, 3000, 3);
	    GivePlayerMoney(playerid, money);
	    ResetSweeperInfo(playerid, true);
	}
	
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(PRESSED(KEY_SUBMISSION) && GetVehicleModel(GetPlayerVehicleID(playerid)) == 574 && !SweeperJob[playerid])
	{
	    SweeperText[playerid] = CreatePlayerTextDraw(playerid, 40.000000, 305.000000, "~b~~h~Sweeper Job~n~~n~~w~Cleaned: ~y~0 Meters");
		PlayerTextDrawBackgroundColor(playerid, SweeperText[playerid], 255);
		PlayerTextDrawFont(playerid, SweeperText[playerid], 1);
		PlayerTextDrawLetterSize(playerid, SweeperText[playerid], 0.240000, 1.100000);
		PlayerTextDrawColor(playerid, SweeperText[playerid], -1);
		PlayerTextDrawSetOutline(playerid, SweeperText[playerid], 1);
		PlayerTextDrawSetProportional(playerid, SweeperText[playerid], 1);
		PlayerTextDrawSetSelectable(playerid, SweeperText[playerid], 0);
		PlayerTextDrawShow(playerid, SweeperText[playerid]);
		
	    SweeperDistance[playerid] = 0;
	    GetPlayerPos(playerid, SweeperLastPos[playerid][0], SweeperLastPos[playerid][1], SweeperLastPos[playerid][2]);
	    SweeperJob[playerid] = true;
	    SendClientMessage(playerid, -1, "Drive around and clean the streets!");
	    SendClientMessage(playerid, -1, "You will get your money when you leave your Sweeper.");
	}
	
	return 1;
}
