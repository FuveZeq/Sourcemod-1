#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>

#define PLUGIN_VERSION  "3.1"

new Handle:kv;
new Float:telepoint[5][3];
new String:telepointName[5][40];
new TurbineTelepoint[MAXPLAYERS+1] = 0;

// Cooldown
#define COOLDOWN 45
new g_fCoolDownTime[MAXPLAYERS+1];

public Plugin:myinfo =
{
  name = "[TF2]Turbine Teleports!",
  author = "Js41637",
  description = "Teleport!",
  version = PLUGIN_VERSION,
  url = ""
}

public OnPluginStart()
{
  CreateConVar("sm_turbinetele_version", PLUGIN_VERSION, "Turbine Teleports Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_PLUGIN);
  RegAdminCmd("sm_dteleports", Command_Teleport, ADMFLAG_CUSTOM3);
  RegAdminCmd("sm_teleports", Command_Teleport, ADMFLAG_SLAY);
}

public OnConfigsExecuted() 
{
  kv = CreateKeyValues("teleports");
  decl String:file[512];
  GetCurrentMap(file, sizeof(file));
  BuildPath(Path_SM, file, sizeof(file), "configs/turbinetele.cfg", file);
  if(FileExists(file, false))
  {
    FileToKeyValues(kv, file);
    BuildTelepoints();
    BuildTelepointsNames();
  }
  else
  {
    PrintToServer("[SM] Turbine Teleports unable to find config file: \"configs/turbinetele.cfg\"", file);
    LogMessage("Turbine Teleports unable to find config file: \"configs/turbinetele.cfg\"", file);
  }
}

public OnClientPostAdminCheck(client)
{
  g_fCoolDownTime[client] = 0;
}

public OnClientDisconnect_Post(client)
{
  g_fCoolDownTime[client] = 0;
}  

BuildTelepoints()
{
  if (!KvJumpToKey(kv, "Telepoints")) return;
  if (!KvGotoFirstSubKey(kv, false)) return;
  decl String:key[10];
  decl String:value[64];
  new String:floatstrings[3][8];
  new i = 0;
  do
  {
    KvGetSectionName(kv, key, sizeof(key));
    KvGetString(kv, NULL_STRING, value, sizeof(value));
    ExplodeString(value, ",", floatstrings, 3, 8, false);
    telepoint[i][0] = StringToFloat(floatstrings[0]);
    telepoint[i][1] = StringToFloat(floatstrings[1]);
    telepoint[i][2] = StringToFloat(floatstrings[2]);
    i++;
  } while (KvGotoNextKey(kv, false) && i<5);

  KvRewind(kv);
}
BuildTelepointsNames()
{
  if (!KvJumpToKey(kv, "TelepointsNames")) return;
  if (!KvGotoFirstSubKey(kv, false)) return;
  decl String:key[10];
  decl String:value[64];
  new i = 0;
  do
  {
    KvGetSectionName(kv, key, sizeof(key));
    KvGetString(kv, NULL_STRING, value, sizeof(value));
    strcopy(telepointName[StringToInt(key)], 40, value);
    i++;
  } while (KvGotoNextKey(kv, false) && i<5);

  KvRewind(kv);
}

public Action:Command_Teleport(client, args) 
{
  if(!IsClientInGame(client) || !IsPlayerAlive(client))
    return Plugin_Handled

  if(IsClientDonator(client)) 
  {
    if(g_fCoolDownTime[client] == 0 || g_fCoolDownTime[client] <= ( GetTime() - COOLDOWN ))
    {
      g_fCoolDownTime[client] = GetTime();
      
      TeleportMenu(client);
    } 
    else
    {
      ReplyToCommand(client, "WOAH THERE BUDDEH, YOU GOTTA WAIT %d SECONDS TO DO THAT AGAIN", COOLDOWN - ( GetTime() - g_fCoolDownTime[client] ));
      ReplyToCommand(client, "You gotta ease it up, turbo.");
    }
  }
  else {
    TeleportMenu(client);
  }
  return Plugin_Handled;
}

TeleportMenu(client) 
{
  new Handle:mastertelemenu = CreateMenu(MasterTeleMenuCallback);
  SetMenuTitle(mastertelemenu, "Master Teleport Menu");
  AddMenuItem(mastertelemenu, "teleport", "Teleports...");
  AddMenuItem(mastertelemenu, "msg", "Teleport Menu ver. 3.1", ITEMDRAW_DISABLED);
  AddMenuItem(mastertelemenu, "msg2", "Created by Js41637", ITEMDRAW_DISABLED);
  AddMenuItem(mastertelemenu, "msg3", "-----------", ITEMDRAW_DISABLED);
  AddMenuItem(mastertelemenu, "msg4", "Have a nice day :)", ITEMDRAW_DISABLED);
  AddMenuItem(mastertelemenu, "msg5", "Except Nyclix", ITEMDRAW_DISABLED);
  DisplayMenu(mastertelemenu, client, 20);
}

public MasterTeleMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
  if (action == MenuAction_End)
  {
    CloseHandle(menu);
  }
  if (action == MenuAction_Select)
  {
    new String:act[20];
    GetMenuItem(menu, param2, act, sizeof(act));
    if(StrEqual(act, "teleport"))
    {
      new Handle:telemenu = CreateMenu(TeleMenuCallback);
      SetMenuTitle(telemenu, "Select Dest:");
      AddMenuItem(telemenu, "dest0", telepointName[0]);
      AddMenuItem(telemenu, "dest1", telepointName[1]);
      AddMenuItem(telemenu, "dest2", telepointName[2]);
      AddMenuItem(telemenu, "dest3", telepointName[3]);
      AddMenuItem(telemenu, "dest4", telepointName[4]);
      DisplayMenu(telemenu, client, MENU_TIME_FOREVER);
    }
    else
    {
      ReplyToCommand(client, "[SM]Error: Wut did you do? You broke it, try again.");
      CloseHandle(menu);
    }
  }
}

public TeleMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
  if (action == MenuAction_Select)
  {
    new String:act[20];
    GetMenuItem(menu, param2, act, sizeof(act));
    if(GetEntityFlags(client) & FL_ONGROUND)
    { 
      if(StrEqual(act, "dest0"))
      {
        TurbineTelepoint[client] = 0;
        TeleOut(client);
      }
      else if(StrEqual(act, "dest1"))
      {
        TurbineTelepoint[client] = 1;
        TeleOut(client);
      }
      else if(StrEqual(act, "dest2"))
      {
        TurbineTelepoint[client] = 2;
        TeleOut(client);
      }
      else if(StrEqual(act, "dest3"))
      {
        TurbineTelepoint[client] = 3;
        TeleOut(client);
      }
      else if(StrEqual(act, "dest4"))
      {
        TurbineTelepoint[client] = 4;
        TeleOut(client);
      }
    }
  }
}

TeleOut(client)
{
  TeleportEntity(client, telepoint[TurbineTelepoint[client]], NULL_VECTOR, NULL_VECTOR);
  PrintToChat(client, "Vwoooooooosh!");
}

public IsClientDonator(client) 
{
  if(GetAdminFlag(GetUserAdmin(client), Admin_Slay))
    return false; 
  
  if(GetAdminFlag(GetUserAdmin(client), Admin_Custom1))
    return true; 

  if(GetAdminFlag(GetUserAdmin(client), Admin_Custom2))
    return true; 

  if(GetAdminFlag(GetUserAdmin(client), Admin_Custom3))
    return true; 

  return false; 
}