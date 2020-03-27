//***************************************
//			Motion RolePlay
//			   By Keemo
//     Started 2017.11.25 23:09
//***************************************

#include <a_samp>
#include <a_mysql>
//#include <nex-ac>
#include <izcmd>
#include <foreach>
#include <sscanf2>
#include <easyDialog>
#include <log-plugin>
#include <streamer>
#include <strlib>
#include <declareVariables>

#define SQL_HOST						"remotemysql.com" 			// MySQL server's host IP
#define SQL_USER 						"iyXLc8IQyh"					// MySQL server's user name
#define SQL_PASS						"NeO2sD6Fih"						// MySQL server's user password
#define SQL_DB							"iyXLc8IQyh"				// MySQL server's database name

#define SERVER_NAME						"Coriom RPG"
#define SERVER_MODE						"RPG"
#define SERVER_VERSION					"v0.1"

#define CMD_NOT_AVAILABLE				"You don't have access to this command!"
#define PLAYER_NOT_ONLINE				"Specified player isn't online right now!"
#define PLAYER_NOT_LOGGED				"Specified player hasn't logged in yet!"
#define NOT_IN_VEHICLE					"You are not in a vehicle!"
#define NOT_ENOUGH_MONEY_BANK			"You don't have enough money on your bank account!"
#define HOUSE_LIMIT_MESSAGE				"You already have a house!"

#define	SECONDS_TO_LOGIN 				(30)					// Max allowed time for login before getting kicked

#define DEFAULT_POS_X 					(1958.3783)
#define DEFAULT_POS_Y 					(1343.1572)
#define DEFAULT_POS_Z 					(15.3746)
#define DEFAULT_POS_A 					(270.1425)

#define MAX_HOUSES						(300)

#define COLOR_WHITE						"FFFFFF"
#define COLOR_LIGHTRED 					(0xFF6347AA)
#define COLOR_ORANGE        			(0xFF9900FF)
#define COLOR_GREY 						(0xAFAFAFAA)
#define COLOR_PURPLE 					(0xC2A2DAAA)
#define COLOR_FADE1 					(0xFFFFFFFF)
#define COLOR_FADE2 					(0xC8C8C8C8)
#define COLOR_FADE3 					(0xAAAAAAAA)
#define COLOR_FADE4 					(0x8C8C8C8C)
#define COLOR_FADE5 					(0x6E6E6E6E)

#define COLOR_IMPORTANT_MESSAGE 		(0x42C5F4FF)


#define GENERAL_TIMER_ADMIN_FLYING		(1)


// FACTIONS IDS
#define FACTION_NONE            (0)
#define FACTION_PD 				(1)
#define FACTION_FBI 			(2)
#define FACTION_NG 				(3)
#define FACTION_MEDICS			(4)

#if !defined IsValidVehicle
     native IsValidVehicle(vehicleid);
#endif

new 
	MySQL: g_SQL,
	g_MysqlRaceCheck[MAX_PLAYERS];

new 
	String[2048],
	query[1024];

new 
	gmLoaded = 0;

new 
	Logger: adminlog;

new 
	Iterator: admin_vehicle<MAX_VEHICLES-1>;

new 
	Float:XYZA[3],
	Float:POSS[3];
new 
	//TOTAL_HOUSES, 
	TOTAL_PVEHICLES;


enum PlayerInfo
{
	ID,
	Name[MAX_PLAYER_NAME],
	Password[65],
	Salt[17],
	Admin,
	Skin,
	Float: Health,
	Float: Armor,
	Money, 
	BankMoney,
	Float: X_Pos,
	Float: Y_Pos,
	Float: Z_Pos,
	Float: A_Pos,
	Interior,
	Cache: Cache_ID,
	bool: LoggedIn,
	LoginAttempts,
	LoginTimer,
	FactionID,
	DrivingVehicleId,
	VirtualWorld,
	bool: IsAdminFlying,
	AdminFlyingTimerId,
};
new Player[MAX_PLAYERS][PlayerInfo];
new OnlineAdmins;

/*enum hInfo
{
	hID,
	Float: hEntranceX,
	Float: hEntranceY,
	Float: hEntranceZ,
	Float: hExitX,
	Float: hExitY,
	Float: hExitZ,
	hOwner[MAX_PLAYER_NAME],
	hClass[16],
	hInterior,
	hWorld,
	hPrice,
	hIcon, 
	hPickup,
	hPickupExit
};
new House[MAX_HOUSES][hInfo];*/

enum vInfo
{
	vID,
	vOwner[MAX_PLAYER_NAME],
	vModel,
	vColor_1,
	vColor_2,
	Float: vX,
	Float: vY,
	Float: vZ,
	Float: vAngle,
	vVehicle,
	vLocked,
	Float: vFuel,
	vActive
};
new pVehicle[MAX_VEHICLES][vInfo];

enum factionsId{
	NONE = 0,
	PD = 1,
	FBI = 2,
	NG = 3,
	MEDICS = 4
}

enum FactionInfo
{
	Name[100],
	Level,
	LeaderID,
	Motd[255],
	Motm[255],
	Float: SpawnX,
	Float: SpawnY,
	Float: SpawnZ,
	Interior,
	Color[10],
	PrimarySkinID
}

new Faction[factionsId][FactionInfo];


enum FactionMembersInfo
{
	Rank,
	JoinDate[255],
	Warns
}

new FactionMembers[MAX_PLAYERS][FactionMembersInfo];

main()
{
	print("\n_____________________________________");
	print(" ");
	print(" Starting Coriom RPG "SERVER_VERSION"");
	print("_____________________________________\n");
}

public OnGameModeInit()
{
	new MySQLOpt: option_id = mysql_init_options();

	mysql_set_option(option_id, AUTO_RECONNECT, true);

	g_SQL = mysql_connect(SQL_HOST, SQL_USER, SQL_PASS, SQL_DB, option_id);
	if (g_SQL == MYSQL_INVALID_HANDLE || mysql_errno(g_SQL) != 0)
	{
		print("MySQL connection failed. Server is shutting down.");
		SendRconCommand("exit");
		return 1;
	}
	print("MySQL connection is successful.");

	SetGameModeText(""SERVER_MODE" "SERVER_VERSION"");

    //mysql_tquery(g_SQL, "SELECT * FROM `houses`", "LoadHouses", "");
	mysql_tquery(g_SQL, "SELECT * FROM `vehicles` ORDER BY  `vehicles`.`ID` ASC ", "LoadPVehicles", "");
	mysql_tquery(g_SQL, "SELECT * FROM `factions` ORDER BY `factions`.`ID` ASC ", "LoadFactions", "");

	UsePlayerPedAnims();

	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);

	CreateDynamicMapIcon(1553.8625,-1675.6571,16.1953, 30, 0);// L.S.P.D
    CreateDynamicMapIcon(-217.5529,979.2314,19.5026, 30, 0);// L.S.P.D Fort Carson
    CreateDynamicMapIcon(627.5083,-571.7580,17.6770, 30, 0);// L.S.P.D Dillimore
    CreateDynamicMapIcon(1091.3884,1076.4139,10.8359, 30, 0);// F.B.I
    CreateDynamicMapIcon(212.9002,1867.7904,13.1406, 30, 0);// N.G
    CreateDynamicMapIcon(2127.5217,2378.3535,10.8203, 52, 0);// Bank LV
    CreateDynamicMapIcon(1744.7484,-2543.9758,13.5469, 5, 0);// Airport LS
    CreateDynamicMapIcon(1436.9381,1470.1625,10.8203, 5, 0);// Airport LV
    CreateDynamicMapIcon(2229.1284,-1722.0292,13.5684, 54, 0);// GYM LS
    CreateDynamicMapIcon(1968.8180,2295.2957,16.4559, 54, 0);// GYM LV
    CreateDynamicMapIcon(328.7192,-1513.0671,36.0391, 55, 0);// Dealership
    CreateDynamicMapIcon(2421.5796,-1220.1400,25.5036, 48, 0);// Pig Pen
    CreateDynamicMapIcon(1941.2639,-2115.9485,13.6953, 36, 0);// Sex Shop LS
    CreateDynamicMapIcon(2086.3538,2074.0442,11.0547, 36, 0);// Sex Shop LV
    CreateDynamicMapIcon(2360.5117,-1532.7363,24.0000, 32, 0);// House Furniture Shop
    CreateDynamicMapIcon(1573.7052,-1337.5750,16.4844, 42, 0);// Star Tower
    CreateDynamicMapIcon(1631.8013,-1171.9377,24.0781, 33, 0);// Horse Betting
    CreateDynamicMapIcon(1310.14,-1368.57,13.5508, 19, 0);// Paintball
    CreateDynamicMapIcon(979.6398,-1296.9238,13.5460, 34, 0);// Rent Bike LS
    CreateDynamicMapIcon(939.1870,1733.7759,8.8516, 34, 0);// Rent Bike LV
    CreateDynamicMapIcon(1735.3986,-1268.6493,13.5441, 6, 0);// Duel Arena LS
    CreateDynamicMapIcon(1476.6893,-1766.9381,18.7958, 40, 0); CreateDynamicMapIcon(1109.1597,-1796.0924,16.5938, 24, 0);
    CreateDynamicMapIcon(1173.2198,-1340.9633,13.9932, 22, 0); CreateDynamicMapIcon(2026.3625,-1418.0045,16.9922, 22, 0);
    CreateDynamicMapIcon(1770.2095,-2045.0994,13.5420, 42, 0); CreateDynamicMapIcon(1056.0609,-329.4827,73.9922, 23, 0);
    CreateDynamicMapIcon(2483.0784,-1669.4274,13.3359, 62, 0); CreateDynamicMapIcon(691.5782,-1275.1327,13.5607, 59, 0);
    CreateDynamicMapIcon(-50.5379,-1132.2949,1.0781, 51, 0); CreateDynamicMapIcon(927.8555,-1352.9431,13.3438, 14, 0);
    CreateDynamicMapIcon(2420.6687,-1508.9841,24.0000, 14, 0); CreateDynamicMapIcon(2397.7664,-1898.0492,13.5469, 14, 0);
    CreateDynamicMapIcon(1199.4910,-919.3374,43.1126, 10, 0); CreateDynamicMapIcon(811.3038,-1616.2290,13.5469, 10, 0);
    CreateDynamicMapIcon(2104.3892,-1806.5471,13.5547, 29, 0); CreateDynamicMapIcon(999.7701,-920.0400,42.3281, 17, 0);
    CreateDynamicMapIcon(1832.4980,-1842.6422,13.5781, 17, 0); CreateDynamicMapIcon(1352.2279,-1758.1797,13.5078, 17, 0);
    CreateDynamicMapIcon(1835.6803,-1682.4927,13.3796, 48, 0); CreateDynamicMapIcon(2309.7761,-1643.8135,14.8270, 49, 0);
    CreateDynamicMapIcon(1368.0507,-1279.8347,13.5469, 18, 0); CreateDynamicMapIcon(1791.6370,-1164.3142,23.8281, 18, 0);
    CreateDynamicMapIcon(2244.5432,-1664.5055,15.4766, 45, 0); CreateDynamicMapIcon(499.8358,-1359.7665,16.2956, 45, 0);
    CreateDynamicMapIcon(460.4845,-1501.0464,31.0567, 45, 0); CreateDynamicMapIcon(1457.1896,-1138.4454,24.0007, 45, 0);
    CreateDynamicMapIcon(1462.5045,-1012.2493,26.8438, 52, 0); CreateDynamicMapIcon(2644.7500,-2038.8049,13.5500, 27, 0);
    CreateDynamicMapIcon(1041.4019,-1026.3676,32.1016, 27, 0); CreateDynamicMapIcon(1022.7234,-1030.2301,32.0651, 63, 0);
    CreateDynamicMapIcon(488.2545,-1734.2357,11.1606, 63, 0); CreateDynamicMapIcon(2072.2341,-1831.1907,13.5545, 63, 0);
    CreateDynamicMapIcon(720.1869,-464.1345,16.3359, 63, 0); CreateDynamicMapIcon(1656.2610,1733.2360,10.8281, 45, 0);
    CreateDynamicMapIcon(2102.8862,2257.4741,11.0234, 45, 0); CreateDynamicMapIcon(2779.0737,2453.2334,11.0625, 45, 0);
    CreateDynamicMapIcon(2090.5029,2224.0144,11.0234, 45, 0); CreateDynamicMapIcon(2572.0632,1903.8228,11.0234, 45, 0);
    CreateDynamicMapIcon(2170.2261,2795.8535,10.8203, 10, 0); CreateDynamicMapIcon(1873.0864,2071.9338,11.0625, 10, 0);
    CreateDynamicMapIcon(1158.9788,2072.2092,11.0625, 10, 0); CreateDynamicMapIcon(2471.9080,2034.1794,11.0625, 10, 0);
    CreateDynamicMapIcon(2102.9441,2228.8267,11.0234, 14, 0); CreateDynamicMapIcon(2393.2620,2042.4973,10.8203, 14, 0);
    CreateDynamicMapIcon(2637.2214,1671.9030,11.0234, 14, 0); CreateDynamicMapIcon(172.2086,1176.1655,14.7645, 14, 0);
    CreateDynamicMapIcon(-1213.0343,1831.1514,41.9297, 14, 0); CreateDynamicMapIcon(2351.7979,2532.2896,10.8203, 29, 0);
    CreateDynamicMapIcon(2083.3550,2224.0127,11.0234, 29, 0); CreateDynamicMapIcon(2247.6333,2397.3601,10.8203, 17, 0);
    CreateDynamicMapIcon(2885.1255,2453.5151,11.0690, 17, 0); CreateDynamicMapIcon(2546.5256,1971.5397,10.8203, 17, 0);
    CreateDynamicMapIcon(2452.4941,2064.0022,10.8203, 17, 0); CreateDynamicMapIcon(2194.0291,1991.0111,12.2969, 17, 0);
    CreateDynamicMapIcon(-88.8208,1378.3822,10.4698, 49, 0); CreateDynamicMapIcon(2507.3804,1243.5999,10.8203, 49, 0);
    CreateDynamicMapIcon(778.2071,1871.4915,4.9072, 18, 0); CreateDynamicMapIcon(2538.3052,2083.9543,10.8203, 18, 0);
    CreateDynamicMapIcon(2158.4773,943.2084,10.8203, 18, 0); CreateDynamicMapIcon(-315.0732,829.8504,14.2422, 18, 0);
    CreateDynamicMapIcon(2195.5251,1677.0149,12.3672, 25, 0); CreateDynamicMapIcon(2020.6107,1007.7909,10.8203, 44, 0);
    CreateDynamicMapIcon(1967.1924,2162.4065,10.8203, 63, 0); CreateDynamicMapIcon(2387.3540,2465.9382,10.8203, 40, 0);
    CreateDynamicMapIcon(-1420.6028,2592.6851,55.7916, 63, 0); CreateDynamicMapIcon(-100.0971,1110.5007,19.7422, 63, 0);
    CreateDynamicMapIcon(1168.6505,-1489.7057,22.7568, 16, 0); CreateDynamicMapIcon(1177.4932,-2040.3126,69.0078, 60, 0);
    CreateDynamicMapIcon(2394.0676,1478.6409,10.8203, 63, 0);

    BLog = TextDrawCreate(549.000000, 431.812500, "Coriom.~r~ro");
	TextDrawLetterSize(BLog, 0.308500, 1.493125);
	TextDrawAlignment(BLog, 1);
	TextDrawColor(BLog, -1);
	TextDrawSetShadow(BLog, 0);
	TextDrawSetOutline(BLog, 1);
	TextDrawBackgroundColor(BLog, 51);
	TextDrawFont(BLog, 2);
	TextDrawSetProportional(BLog, 1);

	//Ceas
    Date = TextDrawCreate(547.000000, 33.000000, "Loading...");
    TextDrawBackgroundColor(Date, 200);
    TextDrawFont(Date, 3);
    TextDrawLetterSize(Date, 0.339998, 1.100000);
    TextDrawColor(Date, -1);
    TextDrawSetOutline(Date, 1);
    TextDrawSetProportional(Date, 1);
    TextDrawSetSelectable(Date, 0);

    Time = TextDrawCreate(530.000000, 12.000000, "Loading...");
    TextDrawBackgroundColor(Time, 200);
    TextDrawFont(Time, 3);
    TextDrawLetterSize(Time, 0.529999, 2.400000);
    TextDrawColor(Time, -1);
    TextDrawSetOutline(Time, 1);
    TextDrawSetProportional(Time, 1);
    TextDrawSetSelectable(Time, 0);

    //Pickup's
    CreateDynamicPickup(1247, 23, 1553.8625,-1675.6571,16.1953, -1, -1, -1); // L.S.P.D
    CreateDynamicPickup(1247, 23, -217.5529,979.2314,19.5026, -1, -1, -1); // L.S.P.D Fort Carson
    CreateDynamicPickup(1247, 23, 627.5083,-571.7580,17.6770, -1, -1, -1); // L.S.P.D Dillimore
    CreateDynamicPickup(1247, 23, 1043.5427,1011.9614,11.0000, -1, -1, -1); // F.B.I
    CreateDynamicPickup(1239, 23, 2034.1545,-1402.7700,17.2946, -1, -1, -1); // Paramedics Department
    CreateDynamicPickup(1239, 23, 1768.8511,-2021.0103,14.1382, -1, -1, -1); // Taxi
    CreateDynamicPickup(1239, 23, -329.6332,1536.7391,76.6117, -1, -1, -1); // News Reporters
    CreateDynamicPickup(1239, 23, 865.2123,-1634.9445,14.9297, -1, -1, -1); // School Instructor
    CreateDynamicPickup(1239, 23, 1073.1022,-345.0618,73.9922, -1, -1, -1); // Hitman Agency
    CreateDynamicPickup(1239, 23, 2495.3015,-1690.3706,14.7656, -1, -1, -1); // Grove Street
    CreateDynamicPickup(1239, 23, 690.7156,-1275.9753,13.5601, -1, -1, -1); // The Ballas Family
    CreateDynamicPickup(1239, 23, 1124.2053,-2036.8785,69.8849, -1, -1, -1); // Los Santos Vagos
    CreateDynamicPickup(1239, 23, 2481.8521,1525.9922,11.6289, -1, -1, -1); // La Cosa Nostra
    CreateDynamicPickup(1239, 23, 1529.9651,-1678.3075,5.8906, -1, -1, -1); // /jail LSPD sub-sol
    CreateDynamicPickup(1239, 23, 1529.9651,-1678.3075,5.8906, -1, -1, -1); // /jail LSPD sub-sol
    CreateDynamicPickup(1318, 23, 1480.9657,-1769.6687,18.7958, -1, -1, -1); // City Hall LS
    CreateDynamicPickup(1318, 23, 2387.3540,2465.9382,10.8203, -1, -1, -1); // City Hall LV
    CreateDynamicPickup(1239, 23, 362.5302,173.6927,1008.3828, -1, -1, -1); // Detective Job
    CreateDynamicPickup(1239, 23, 2814.7651,972.5791,10.7500, -1, -1, -1); // Street Sweeper Job
    CreateDynamicPickup(1239, 23, -382.2383,-1426.3613,26.1335, -1, -1, -1); // Farmer Job
    CreateDynamicPickup(1239, 23, -74.8612,-1104.4348,1.1060, -1, -1, -1); // Trucker Job
    CreateDynamicPickup(1239, 23, 2102.5405,-1788.9784,13.5547, -1, -1, -1); // Pizza Boy Job
    //CreateDynamicPickup(1239, 23, 150.5054,-287.6017,1.5781, -1, -1, -1); // Garbage Man Job
    CreateDynamicPickup(1239, 23, 1365.9731,-1274.7964,13.5469, -1, -1, -1); // Arms Dealer Job
    CreateDynamicPickup(1239, 23, 2520.5959,-1715.5168,13.5684, -1, -1, -1); // Drugs Dealer Job
    CreateDynamicPickup(1239, 23, 2781.7976,-1813.7986,11.8438, -1, -1, -1); // StuntMan Job
    CreateDynamicPickup(1239, 23, -568.5550,-1478.4895,10.0544, -1, -1, -1); // Miner Job
    CreateDynamicPickup(1239, 23, 1628.2863,598.4431,1.7578, -1, -1, -1); // Fisher Job
    CreateDynamicPickup(1239, 23, 918.1180,-1252.1699,16.2109, -1, -1, -1); // Mechanic Job
    CreateDynamicPickup(1276, 23, 593.1906,-1249.4102,18.1969, -1, -1, -1); // /getmats Arms Dealer
    CreateDynamicPickup(1318, 23, 2166.6011,-1671.9425,15.0745, -1, -1, -1); // Enter Crack House
    CreateDynamicPickup(1580, 23, 414.7388,2536.8030,10.0000, -1, -1, -1); // /getdrugs Crack House
    CreateDynamicPickup(1484, 23, 499.2582,-20.6862,1000.6797, -1, -1, -1); // /drink Alhambra
    CreateDynamicPickup(1484, 23, 496.2766,-75.4688,998.7578, -1, -1, -1); // /drink Ten Green Bottles
    CreateDynamicPickup(1484, 23, 1215.1302,-13.0056,1000.9219, -1, -1, -1); // /drink Pig Pen
    CreateDynamicPickup(1239, 23, 312.6924,-165.6643,999.6010, -1, -1, -1); // /buygun Ammu-Nation LS #1
    CreateDynamicPickup(1239, 23, 313.9153,-133.9216,999.6016, -1, -1, -1); // /buygun Gun Shop LS #1
    CreateDynamicPickup(1239, 23, 291.4279,-106.3569,1001.5156, -1, -1, -1); // /buygun Ammu-Nation LV #1
    CreateDynamicPickup(1318, 23, 306.3798,-141.8557,1004.0547, 13, -1, -1); // Gun Shop LS #1 - Pickup etaj 2
    CreateDynamicPickup(1318, 23, 300.7512,-141.7873,1004.0625, 13, -1, -1); // Gun Shop LS #1 - Pickup Hol -> Intrare in sala
    CreateDynamicPickup(1318, 23, 306.6394,-159.2810,999.5938, -1, -1, -1); // Ammu-Nation LS #1 - Pickup Shop
    CreateDynamicPickup(1318, 23, 299.5828,-169.0117,999.5938, -1, -1, -1); // Ammu-Nation LS #1 - Pickup Hol
    CreateDynamicPickup(1239, 23, 327.4651,-1513.9923,36.0325, -1, -1, -1); // Dealership EXT
    CreateDynamicPickup(1318, 23, 1525.8956,-1670.8820,6.2188, -1, -1, -1); // Lift LSPD Jos Acoperis
    CreateDynamicPickup(1318, 23, 1564.8909,-1665.6904,28.3956, -1, -1, -1); // Lift LSPD Sus Acoperis
    CreateDynamicPickup(1318, 23, 1524.4851,-1677.9209,6.2188, -1, -1, -1); // Lift LSPD Jos -> Interior
    CreateDynamicPickup(1318, 23, 246.4217,87.8054,1003.6406, -1, -1, -1); // Lift LSPD Interior -> Jos
    CreateDynamicPickup(1242, 23, 1568.5813,-1690.0078,6.2188, -1, -1, -1); // /outfit L.S.P.D
    CreateDynamicPickup(1242, 23, 300.9579,187.5293,1007.1719, -1, -1, -1); // /outfit F.B.I
    CreateDynamicPickup(1242, 23, 201.9497,1869.4393,13.1406, -1, -1, -1); // /outfit N.G
    CreateDynamicPickup(1318, 23, 2229.1284,-1722.0292,13.5684, -1, -1, -1); // GYM LS
    CreateDynamicPickup(1318, 23, 1968.8180,2295.2957,16.4559, -1, -1, -1); // GYM LV
    CreateDynamicPickup(1318, 23, 1173.5221,-1361.4954,13.9721, -1, -1, -1); // Elevator Paramedics HQ-Secondary | Down.
    CreateDynamicPickup(1318, 23, 1163.6093,-1343.7985,26.6109, -1, -1, -1); // Elevator Paramedics HQ-Secondary | Up.
    CreateDynamicPickup(1318, 23, 2041.3066,-1409.4218,17.1641, -1, -1, -1); // Elevator Paramedics HQ-Main | Down.
    CreateDynamicPickup(1318, 23, 2043.7803,-1395.4191,48.3359, -1, -1, -1); // Elevator Paramedics HQ-Main | Up.
    CreateDynamicPickup(1318, 23, 1204.8662,11.7133,1000.9219, -1, -1, -1); // Private Room The Pig Pen
    CreateDynamicPickup(1318, 23, 2232.5674,-1159.8212,25.8906, -1, -1, -1); // Jefferson Motel
    CreateDynamicPickup(1318, 23, -575.8969,-1483.9099,10.6196, -1, -1, -1); // Enter Mine
    CreateDynamicPickup(1318, 23, -546.4297,-1648.3395,-45.5994, -1, -1, -1); // Exit Mine
    CreateDynamicPickup(1247, 23, 256.7137,69.7634,1003.6406, -1, -1, -1); // Clear LSPD
    CreateDynamicPickup(1247, 23, 229.9409,165.0372,1003.0234, -1, -1, -1); // Clear FBI
    CreateDynamicPickup(1247, 23, 246.9711,1859.8922,14.0840, -1, -1, -1); // Clear NG
    CreateDynamicPickup(1318, 23, 1053.6100,2133.9456,10.8203, -1, -1, -1); // Enter Mats INT
    CreateDynamicPickup(1318, 23, 1526.0853,-1664.2771,6.2188, -1, -1, -1); // Train LSPD
    CreateDynamicPickup(1318, 23, 1013.9379,1058.9126,11.0000, -1, -1, -1); // Train FBI
    CreateDynamicPickup(1318, 23, 211.1518,1834.8896,17.6406, -1, -1, -1); // Train NG
    CreateDynamicPickup(1318, 23, 1051.7607,-345.1129,73.9922, -1, -1, -1); // Train Hitman
    CreateDynamicPickup(1318, 23, 2486.4727,-1645.5254,14.0772, -1, -1, -1); // Train Grove
    CreateDynamicPickup(1318, 23, 726.4975,-1276.2246,13.6484, -1, -1, -1); // Train Ballas
    CreateDynamicPickup(1318, 23, 1111.9786,-2036.5148,74.4297, -1, -1, -1); // Train Vagos
    CreateDynamicPickup(1318, 23, 2461.2180,1559.3934,11.6875, -1, -1, -1); // Train LCN
    CreateDynamicPickup(1318, 23, 2609.6699,1435.8795,10.8203, -1, -1, -1); // Train UST
    CreateDynamicPickup(1318, 23, -376.1208,2260.4431,43.0619, -1, -1, -1); // Exit Training
    CreateDynamicPickup(1318, 23, 1573.7052,-1337.5750,16.4844, -1, -1, -1); // Enter Tower
    CreateDynamicPickup(1318, 23, 1548.6807,-1364.5693,326.2183, -1, -1, -1); // Exit Tower
    CreateDynamicPickup(1318, 23, 1631.8013,-1171.9377,24.0781, -1, -1, -1); // Horse Betting
    CreateDynamicPickup(2709, 23, 1951.0146,2143.3718,10.8203, -1, -1, -1); // /carcolor
    CreateDynamicPickup(1318, 23, -1464.8242,1557.3706,1052.5313, -1, -1, -1); // Exit Stunt Arena
    CreateDynamicPickup(1314, 23, 1957.2198,-2183.6379,13.5469, -1, -1, -1); // Flying Lesson
    CreateDynamicPickup(1314, 23, 898.4128,-1919.9692,1.5288, -1, -1, -1); // Sailing Lesson
    CreateDynamicPickup(1239, 23, 362.7672,154.8419,1025.7964, -1, -1, -1); // Injections
    CreateDynamicPickup(1318, 23, -1153.4860,-477.1501,1.9609, -1, -1, -1); // #1 Up
    CreateDynamicPickup(1318, 23, -1155.7948,-475.8309,14.1484, -1, -1, -1); // #1 Down
    CreateDynamicPickup(1318, 23, -1081.1989,-207.5269,1.9609, -1, -1, -1); // #2 Up
    CreateDynamicPickup(1318, 23, -1083.3521,-208.6155,14.1440, -1, -1, -1); // #2 Down
    CreateDynamicPickup(1318, 23, -1182.0620,61.0498,1.9609, -1, -1, -1); // #3 Up
    CreateDynamicPickup(1318, 23, -1184.0129,58.9738,14.1484, -1, -1, -1); // #3 Down
    CreateDynamicPickup(1318, 23, -1445.1057,90.8282,1.9609, -1, -1, -1); // #4 Up
    CreateDynamicPickup(1318, 23, -1443.3502,89.2235,14.1466, -1, -1, -1); // #4 Down
    CreateDynamicPickup(1318, 23, -1619.4005,-83.3528,1.9609, -1, -1, -1); // #5 Up
    CreateDynamicPickup(1318, 23, -1617.6396,-84.9819,14.1484, -1, -1, -1); // #5 Down
    CreateDynamicPickup(1239, 23, 1128.8787,-1490.4647,22.7690, -1, -1, -1); // Gift
    
    CreateDynamicPickup(1239, 23, 830.9294,-2047.7726,12.8672, -1, -1, -1); // spin gift
    CreateDynamicPickup(1247, 23, 1798.1985,-1578.7365,14.0913, -1, -1, -1); // Jail exteror
    
    parachute = CreateDynamicPickup(1310, 23, 1538.6881,-1365.4182,329.4609, -1, -1, -1); // Star Tower Parachute

    AddFactionsObjects();

	//Init Admin 
	OnlineAdmins = 0;

	adminlog = CreateLog("admin", INFO);

	gmLoaded = 1;
	return 1;
}

public OnGameModeExit()
{
	for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++)
	{
		if (IsPlayerConnected(i))
		{
			OnPlayerDisconnect(i, 1);
		}
	}
	mysql_close(g_SQL);

	DestroyLog(adminlog);
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);
	return 1;
}

public OnPlayerConnect(playerid)
{
	if(gmLoaded == 0)
	{
		SendClientMessage(playerid, -1, "Server is not running yet!");
		Kick(playerid);
	}
	g_MysqlRaceCheck[playerid]++;

	static const empty_player[PlayerInfo];
	Player[playerid] = empty_player;

	SetTimer("TimeSet", 1000, true);

	TextDrawShowForPlayer(playerid, Date), TextDrawShowForPlayer(playerid, Time);

	GetPlayerRPName(playerid, Player[playerid][Name], MAX_PLAYER_NAME);

	mysql_format(g_SQL, query, 103, "SELECT * FROM `players` WHERE `Name` = '%e' LIMIT 1", pName(playerid));
	mysql_tquery(g_SQL, query, "OnPlayerDataLoaded", "dd", playerid, g_MysqlRaceCheck[playerid]);
	
	format(String, 100, "[A] %s [ID: %d] joined the server.", Player[playerid][Name], playerid);
	SendAdminMessage(COLOR_LIGHTRED, String);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	g_MysqlRaceCheck[playerid]++;


	//check if Player is Admin to Increment
	if(Player[playerid][Admin] > 0 && Player[playerid][LoggedIn] == true) OnlineAdmins--;

	Player[playerid][LoggedIn] = false;

	UpdatePlayerData(playerid, reason);

	if (cache_is_valid(Player[playerid][Cache_ID]))
	{
		cache_delete(Player[playerid][Cache_ID]);
		Player[playerid][Cache_ID] = MYSQL_INVALID_CACHE;
	}

	if (Player[playerid][LoginTimer])
	{
		KillTimer(Player[playerid][LoginTimer]);
		Player[playerid][LoginTimer] = 0;
	}

	mysql_format(g_SQL, query, 250, "UPDATE `players` SET `LoggedIn` = %d WHERE `ID` = %d LIMIT 1", Player[playerid][LoggedIn], Player[playerid][ID]);
	mysql_tquery(g_SQL, query);

	new disconnectReason[3][] =
    {
        "Timeout/Crash",
        "Quit",
        "Kick/Ban"
    };

	format(String, 100, "[A] %s [ID: %d] left the server with reason: {FF9900}%s", Player[playerid][Name], disconnectReason[reason]);
	SendAdminMessage(COLOR_LIGHTRED, String);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	SetPlayerInterior(playerid, Player[playerid][Interior]);
	SetPlayerPos(playerid, Player[playerid][X_Pos], Player[playerid][Y_Pos], Player[playerid][Z_Pos]);
	SetPlayerFacingAngle(playerid, Player[playerid][A_Pos]);
	SetPlayerSkin(playerid, Player[playerid][Skin]);

	new playerColor[128];
	new factionsId:playerFactionID;
	playerFactionID = factionsId:GetFactionEnumFromParam(Player[playerid][FactionID]);
	strcat(playerColor, sprintf("0x%sFF", Faction[playerFactionID][Color]));
	new playerColorConverted;
	sscanf(playerColor, "x", playerColorConverted);
	SetPlayerColor(playerid, playerColorConverted);

	//SendClientMessage(playerid, COLOR_GREY, sprintf("Your COLOR: %x", playerColorConverted));
	
	SetCameraBehindPlayer(playerid);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	format(String, 128, "%s says: %s", Player[playerid][Name], text);
	SendLocalMessage(30.0, playerid, -1, String);
	if(!IsPlayerInAnyVehicle(playerid)) ApplyAnimation(playerid, "PED", "IDLE_CHAT", 4.1, 0, 1, 1, 1, 1);
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
	if(pickupid == parachute)
	{
		GivePlayerWeapon(playerid, 46, 1);
		return 1;
	}
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

forward OnPlayerDataLoaded(playerid, race_check);
public OnPlayerDataLoaded(playerid, race_check)
{
	if (race_check != g_MysqlRaceCheck[playerid]) return Kick(playerid);

	if(cache_num_rows() > 0)
	{
		cache_get_value(0, "Password", Player[playerid][Password], 65);
		cache_get_value(0, "Salt", Player[playerid][Salt], 17);

		Player[playerid][Cache_ID] = cache_save();

		format(String, 115, "This account %s is registered. Please login by entering your password in the field below:", Player[playerid][Name]);
		Dialog_Show(playerid, Login, DIALOG_STYLE_PASSWORD, "Login", String, "Login", "Abort");

		Player[playerid][LoginTimer] = SetTimerEx("OnLoginTimeout", SECONDS_TO_LOGIN * 1000, false, "d", playerid);
	}
	else
	{
		format(String, sizeof String, "Welcome %s, you can register by entering your password in the field below:", Player[playerid][Name]);
		Dialog_Show(playerid, Register, DIALOG_STYLE_PASSWORD, "Registration", String, "Register", "Abort");
	}
	return 1;
}

forward OnLoginTimeout(playerid);
public OnLoginTimeout(playerid)
{
	Player[playerid][LoginTimer] = 0;
	
	Dialog_Show(playerid, Null, DIALOG_STYLE_MSGBOX, "Login", "You have been kicked for taking too long to login successfully to your account.", "Okay", "");
	DelayedKick(playerid);
	return 1;
}

forward OnPlayerRegister(playerid);
public OnPlayerRegister(playerid)
{
	Player[playerid][ID] = cache_insert_id();

	Dialog_Show(playerid, Null, DIALOG_STYLE_MSGBOX, "Registration", "Account successfully registered, you have been automatically logged in.", "Okay", "");

	Player[playerid][LoggedIn] = true;

	Player[playerid][X_Pos] = DEFAULT_POS_X;
	Player[playerid][Y_Pos] = DEFAULT_POS_Y;
	Player[playerid][Z_Pos] = DEFAULT_POS_Z;
	Player[playerid][A_Pos] = DEFAULT_POS_A;

	TextDrawShowForPlayer(playerid, BLog);
	
	SpawnPlayer(playerid);
	return 1;
}

forward _KickPlayerDelayed(playerid);
public _KickPlayerDelayed(playerid)
{
	Kick(playerid);
	return 1;
}


forward public LoadPVehicles();
public LoadPVehicles()
{
	static rows;
	cache_get_row_count(rows);
	if(rows)
	{
		for(new idx = 1; idx <= rows; idx++)
		{
			cache_get_value_name_int(idx-1, "ID", pVehicle[idx][vID]);
			cache_get_value_name(idx-1, "Owner", pVehicle[idx][vOwner]);
			cache_get_value_name_int(idx-1, "Model", pVehicle[idx][vModel]);
			cache_get_value_name_int(idx-1, "Color_1", pVehicle[idx][vColor_1]);
			cache_get_value_name_int(idx-1, "Color_2", pVehicle[idx][vColor_2]);
			cache_get_value_name_float(idx-1, "X", pVehicle[idx][vX]);
			cache_get_value_name_float(idx-1, "Y", pVehicle[idx][vY]);
			cache_get_value_name_float(idx-1, "Z", pVehicle[idx][vZ]);
			cache_get_value_name_float(idx-1, "Angle", pVehicle[idx][vAngle]);
			cache_get_value_name_int(idx-1, "Active", pVehicle[idx][vActive]);
			if(pVehicle[idx][vActive] == 1)
			{
				pVehicle[idx][vVehicle] = CreateVehicle(pVehicle[idx][vModel], pVehicle[idx][vX], pVehicle[idx][vY], pVehicle[idx][vZ], pVehicle[idx][vAngle], pVehicle[idx][vColor_1], pVehicle[idx][vColor_2], -1);
				TOTAL_PVEHICLES++;
			}
		}
	}
	printf( "Loaded %d player vehicles", TOTAL_PVEHICLES);
	return 1;
}

forward public LoadFactions();
public LoadFactions()
{
	static rows;
	cache_get_row_count(rows);
	new factionsId:factionId;
	for(new idx = 0; idx < rows; idx++)
	{
		cache_get_value_name_int(idx, "ID", factionId);
		cache_get_value(idx, "Name", Faction[factionId][Name], 100);
		cache_get_value_name_int(idx, "Level", Faction[factionId][Level]);
		cache_get_value_name_int(idx, "LeaderID", Faction[factionId][LeaderID]);
		cache_get_value(idx, "Motd", Faction[factionId][Motd], 255);
		cache_get_value(idx, "Motm", Faction[factionId][Motm], 255);
		cache_get_value_name_float(idx, "SpawnX", Faction[factionId][SpawnX]);
		cache_get_value_name_float(idx, "SpawnY", Faction[factionId][SpawnY]);
		cache_get_value_name_float(idx, "SpawnZ", Faction[factionId][SpawnZ]);
		cache_get_value_name_int(idx, "Interior", Faction[factionId][Interior]);
		cache_get_value(idx, "Color", Faction[factionId][Color], 10);
		cache_get_value_name_int(idx, "PrimarySkinID", Faction[factionId][PrimarySkinID]);
	}
	printf( "Loaded %d factions", rows);
	return 1;
}

forward GeneralTimer(playerid, tid);
public GeneralTimer(playerid, tid)
{
    switch(tid)
    {
        case GENERAL_TIMER_ADMIN_FLYING:
        {
            new k, ud, lr, Float:v_x, Float:v_y, Float:v_z, Float:x, Float:y, Float:z;
            GetPlayerKeys(playerid, k, ud, lr);
            if(ud < 0) GetPlayerCameraFrontVector(playerid, x, y, z), v_x = x + 0.1, v_y = y + 0.1;
            if(k & 128) v_z = -0.2;
            else if(k & KEY_FIRE) v_z = 0.2;
            if(k & KEY_WALK) v_x /= 5.0, v_y /= 5.0, v_z /= 5.0;
            if(k & KEY_SPRINT) v_x *= 4.0, v_y *= 4.0, v_z *= 4.0;
            if(v_z == 0.0) v_z = 0.025;
            SetPlayerVelocity(playerid, v_x, v_y, v_z), SetPlayerHealth(playerid, 0x7F800000);
            if(!v_x && !v_y) { if(GetPlayerAnimationIndex(playerid) == 959) ApplyAnimation(playerid, "PARACHUTE", "PARA_steerR", 6.1, 1, 1, 1, 1, 0, 1); }
            else
            {
                GetPlayerCameraFrontVector(playerid, v_x, v_y, v_z), GetPlayerCameraPos(playerid, x, y, z), SetPlayerLookAt(playerid, v_x * 500.0 + x, v_y * 500.0 + y);
                if(GetPlayerAnimationIndex(playerid) != 959) ApplyAnimation(playerid, "PARACHUTE", "FALL_SkyDive_Accel", 6.1, 1, 1, 1, 1, 0, 1);
            }
        }
    }
    return 1;
}

forward TimeSet();
public TimeSet()
{
	new date[12],time[12];
	new y,m,d,h,mi,s;
	new MonthName[12][] =
	{
		"January", "February", "March", "April", "May", "June",
		"July",	"August", "September", "October", "November", "December"
	};

	getdate(y,m,d);
	gettime(h,mi,s);

	format(date, 18, "%d %s", d, MonthName[m-1]);
	format(time, 18, "%02d:%02d:%02d", h, mi, s);

	TextDrawSetString(Date, date);
	TextDrawSetString(Time, time);

}

AddFactionsObjects()
{
	//SCHOOL INSTRUCTORS SF

	AddStaticVehicle(426,-2064.5974,-84.1423,34.9074,179.7453,130,130); // S.I SF car 1
	AddStaticVehicle(426,-2068.4888,-84.1796,34.9075,178.2300,130,130); // S.I SF car 2
	AddStaticVehicle(426,-2072.5901,-84.0756,34.9074,179.1111,130,130); // S.I SF car 3
	AddStaticVehicle(426,-2077.1262,-84.1789,34.9074,178.6190,130,130); // S.I SF car 4
	AddStaticVehicle(426,-2081.1382,-84.1722,34.9069,179.1522,130,130); // S.I SF car 5
	AddStaticVehicle(426,-2085.2773,-84.1596,34.9075,178.5059,130,130); // S.I SF car 6
	AddStaticVehicle(426,-2089.7610,-84.2256,34.9075,178.6065,130,130); // S.I SF car 7
	AddStaticVehicle(426,-2093.6218,-84.2745,34.9068,178.2257,130,130); // S.I SF car 8
	AddStaticVehicle(560,-2081.8706,-100.3450,34.8695,268.5446,130,130); // S.I SF sultan 1
	AddStaticVehicle(560,-2074.1182,-100.6011,34.8692,267.9609,130,130); // S.I SF sultan 2
	AddPlayerClass(250,-2026.6169,-100.5352,35.1641,181.3187,0,0,0,0,0,0); // S.I SF entrance
	AddPlayerClass(250,-2021.8672,-100.5362,35.1641,85.4378,0,0,0,0,0,0); // S.I SF spawn
	AddPlayerClass(250,-2048.4587,-98.5947,35.1641,359.5836,0,0,0,0,0,0); // S.I SF /FVEH

	//SCHOOL INSTRUCTORS LS

	AddPlayerClass(250,1219.3534,-1812.2386,16.5938,2.0627,0,0,0,0,0,0); // S.I LS entrance
	AddPlayerClass(250,1216.0802,-1814.0511,16.5938,269.0019,0,0,0,0,0,0); // S.I LS spawn
	AddPlayerClass(250,1238.0845,-1812.9845,13.4310,180.6644,0,0,0,0,0,0); // S.I LS /FVEH
	AddStaticVehicle(426,1251.2903,-1833.6716,13.1356,357.6915,130,130); // S.I LS car 1
	AddStaticVehicle(426,1247.4417,-1833.6711,13.1362,357.7172,130,130); // S.I LS car 2
	AddStaticVehicle(426,1243.3259,-1833.6143,13.1364,357.6746,130,130); // S.I LS car 3
	AddStaticVehicle(426,1239.4172,-1833.5483,13.1365,357.3240,130,130); // S.I LS car 4
	AddStaticVehicle(426,1255.3658,-1833.8871,13.1344,356.4654,130,130); // S.I LS car 5
	AddStaticVehicle(426,1235.2716,-1833.5042,13.1374,355.7259,130,130); // S.I LS car 6
	AddStaticVehicle(426,1231.2781,-1833.5082,13.1374,357.0415,130,130); // S.I LS car 7
	AddStaticVehicle(426,1227.3800,-1833.3094,13.1366,354.5539,130,130); // S.I LS car 8
	AddStaticVehicle(560,1205.9982,-1826.4408,13.1158,269.5989,130,130); // S.I LS sultan 1
	AddStaticVehicle(560,1214.1842,-1826.3562,13.1155,270.3483,130,130); // S.I LS sultan 2

	//SCHOOL INSTRUCTORS LV

	AddPlayerClass(250,937.7573,1733.0544,8.8516,89.5792,0,0,0,0,0,0); // S.I LV entrance
	AddPlayerClass(250,942.4420,1733.2168,8.8516,271.3142,0,0,0,0,0,0); // S.I LV spawn
	AddPlayerClass(250,950.2761,1733.7813,8.6484,274.4476,0,0,0,0,0,0); // S.I LV /FVEH
	AddStaticVehicle(426,967.0989,1709.6747,8.3913,358.3089,130,130); // S.I LV car 1
	AddStaticVehicle(426,963.0893,1709.6884,8.3912,358.5129,130,130); // S.I LV car 2
	AddStaticVehicle(426,958.8543,1709.7472,8.3917,358.2046,130,130); // S.I LV car 3
	AddStaticVehicle(426,954.4043,1709.5339,8.3915,358.8088,130,130); // S.I LV car 4
	AddStaticVehicle(426,954.1284,1757.0430,8.3919,179.4449,130,130); // S.I LV car 5
	AddStaticVehicle(426,958.3223,1757.0707,8.3911,179.0095,130,130); // S.I LV car 6
	AddStaticVehicle(426,962.4612,1756.9954,8.3916,178.2074,130,130); // S.I LV car 7
	AddStaticVehicle(426,966.8317,1756.8386,8.3917,178.5968,130,130); // S.I LV car 8
	AddStaticVehicle(560,984.6334,1743.4034,8.3553,88.9414,130,130); // S.I LV sultan 1
	AddStaticVehicle(560,984.5568,1739.4016,8.3568,89.4341,130,130); // S.I LV sultan 2

	//PARAMEDICS LV

	AddPlayerClass(250,1606.9437,1815.7488,10.8203,196.1638,0,0,0,0,0,0); // PARAMEDICS LV entrance
	AddPlayerClass(250,1614.0813,1816.9415,10.8203,84.3261,0,0,0,0,0,0); // PARAMEDICS LV spawn
	AddStaticVehicle(416,1620.4082,1849.5498,10.9695,180.5424,1,3); // PARAMEDICS LV car 1
	AddStaticVehicle(416,1615.8967,1849.3981,10.9697,180.3674,1,3); // PARAMEDICS LV car 2
	AddStaticVehicle(416,1611.3462,1849.2699,10.9695,178.6436,1,3); // PARAMEDICS LV car 3
	AddStaticVehicle(416,1600.2992,1840.9059,10.9696,359.8628,1,3); // PARAMEDICS LV car 4
	AddStaticVehicle(416,1593.9722,1830.1914,10.9697,180.6215,1,3); // PARAMEDICS LV car 5
	AddStaticVehicle(416,1593.0184,1848.9404,10.9693,178.9499,1,3); // PARAMEDICS LV car 6
	AddStaticVehicle(505,1597.3278,1850.0594,10.9640,180.2482,1,3); // PARAMEDICS LV rancher 1
	AddStaticVehicle(505,1608.3813,1831.4279,10.9645,180.6853,1,3); // PARAMEDICS LV rancher 2
	AddPlayerClass(250,1623.7150,1819.9967,10.8203,0.6567,0,0,0,0,0,0); // PARAMEDICS LV /FVEH

	//PARAMEIDCS LS

	AddStaticVehicle(505,2006.8004,-1410.2222,17.1355,90.4361,1,3); // PARAMEDICS LS rancher 1
	AddStaticVehicle(489,2014.8055,-1409.9644,17.1359,90.7696,1,3); // PARAMEDICS LS rancher 2
	AddStaticVehicle(416,2029.4622,-1437.7076,17.2241,180.9182,1,3); // PARAMEDICS LS ambulance 1
	AddStaticVehicle(416,2008.8485,-1419.0387,17.1413,90.5952,1,3); // PARAMEDICS LS ambulance 2
	AddStaticVehicle(416,2029.4160,-1428.8066,17.1859,179.0100,1,3); // PARAMEDICS LS ambulance 3
	AddStaticVehicle(416,2019.8722,-1418.9780,17.1415,89.3702,1,3); // PARAMEDICS LS ambulance 4
	AddStaticVehicle(416,2036.9063,-1429.2799,17.1556,181.0903,1,3); // PARAMEDICS LS ambulance 5
	AddStaticVehicle(416,2036.7972,-1421.1801,17.1415,179.9431,1,3); // PARAMEDICS LS ambulance 6
	AddPlayerClass(250,2034.2162,-1402.6768,17.2952,5.0869,0,0,0,0,0,0); // PARAMEDICS LS entrance
	AddPlayerClass(250,2029.5818,-1404.7289,17.2519,168.3117,0,0,0,0,0,0); // PARAMEDICS LS spawn
	AddPlayerClass(250,2031.5282,-1415.6594,16.9922,138.8581,0,0,0,0,0,0); // PARAMEDICS LS /FVEH

	//PARAMEDICS SF

	AddPlayerClass(250,-2665.0879,639.3471,14.4531,359.3772,0,0,0,0,0,0); // PARAMEDICS SF entrance
	AddPlayerClass(250,-2663.5776,634.8121,14.4531,179.2323,0,0,0,0,0,0); // PARAMEDICS SF spawn
	AddStaticVehicle(416,-2669.3364,619.0677,14.6020,90.8805,1,3); // PARAMEDICS SF ambulance 1
	AddStaticVehicle(416,-2659.9663,619.1160,14.6018,88.8848,1,3); // PARAMEDICS SF ambulance 2
	AddStaticVehicle(416,-2650.9739,619.2039,14.6025,89.3478,1,3); // PARAMEDICS SF ambulance 3
	AddStaticVehicle(416,-2641.8760,619.0651,14.6023,89.8127,1,3); // PARAMEDICS SF ambulance 4
	AddStaticVehicle(416,-2632.9675,618.9271,14.6026,90.6796,1,3); // PARAMEDICS SF ambulance 5
	AddStaticVehicle(416,-2623.9771,619.0467,14.6025,88.7850,1,3); // PARAMEDICS SF ambulance 6
	AddStaticVehicle(489,-2619.2979,629.7820,14.5968,89.6712,1,3); // PARAMEDICS SF rancher 1
	AddStaticVehicle(489,-2628.1060,629.8400,14.5968,88.8502,1,3); // PARAMEDICS SF rancher 2
	AddPlayerClass(250,-2683.6782,629.6426,14.4545,175.8046,0,0,0,0,0,0); // PARAMEDICS SF /FVEH

	//NEWS REPORTER SF

	AddStaticVehicle(582,-2505.6284,-602.3748,132.6232,179.5921,1,162); // NR SF van 1
	AddStaticVehicle(582,-2502.0200,-602.4473,132.6195,179.6760,1,162); // NR SF van 2
	AddStaticVehicle(582,-2509.4167,-602.4133,132.6198,180.7553,1,162); // NR SF van 3
	AddStaticVehicle(582,-2513.2900,-602.4412,132.6193,179.8925,1,162); // NR SF van 4
	AddStaticVehicle(582,-2516.8389,-602.5563,132.6207,179.9462,1,162); // NR SF van 5
	AddStaticVehicle(582,-2527.9890,-602.5507,132.6196,179.3858,1,162); // NR SF van 6
	AddStaticVehicle(582,-2524.4006,-602.5169,132.6187,179.2658,1,162); // NR SF van 7
	AddStaticVehicle(488,-2500.3259,-622.3423,132.8529,269.8299,1,162); // NR SF chopper
	AddPlayerClass(250,-2534.8899,-618.0505,132.5625,279.7281,0,0,0,0,0,0); // NR SF /FVEH
	AddPlayerClass(250,-2521.0496,-624.9507,132.7843,182.9073,0,0,0,0,0,0); // NR SF entrance
	AddPlayerClass(250,-2518.9229,-621.7445,132.7392,3.0757,0,0,0,0,0,0); // SF NR spawn

	//NEWS REPORTER LS

	AddStaticVehicle(488,740.6693,-1366.3091,25.8695,181.1746,1,162); // NR LS chopper
	AddPlayerClass(250,736.3957,-1351.7429,13.5000,268.8819,0,0,0,0,0,0); // NR LS spawn
	AddPlayerClass(250,733.4649,-1348.4298,13.5098,273.2920,0,0,0,0,0,0); // NR LS entrance
	AddPlayerClass(250,749.0254,-1352.6613,13.5000,273.8953,0,0,0,0,0,0); // NR LS /FVEH
	AddStaticVehicle(582,752.1847,-1334.1827,13.5943,178.5674,1,162); // NR LS van 1
	AddStaticVehicle(582,756.6245,-1334.1946,13.5986,179.4210,1,162); // NR LS van 2
	AddStaticVehicle(582,760.8542,-1334.2858,13.5969,178.1078,1,162); // NR LS van 3
	AddStaticVehicle(582,765.0814,-1334.4938,13.6007,178.8687,1,162); // NR LS van 4
	AddStaticVehicle(582,782.6440,-1344.8827,13.5903,88.3334,1,162); // NR LS van 5
	AddStaticVehicle(582,782.6516,-1349.0712,13.5955,88.8802,1,162); // NR LS van 6
	AddStaticVehicle(582,782.6694,-1353.6302,13.5982,88.7995,1,162); // NR LS van 7

	//NEWS REPORTER LV

	AddPlayerClass(250,-329.6211,1537.0360,76.6117,359.5079,0,0,0,0,0,0); // NR LV entrance
	AddPlayerClass(250,-308.6386,1538.1974,75.5625,132.5075,0,0,0,0,0,0); // NR LV spawn
	AddStaticVehicle(582,-346.0936,1515.7072,75.4190,0.4217,1,162); // NR LV van 1
	AddStaticVehicle(582,-342.8145,1515.7869,75.4143,359.9774,1,162); // NR LV van 2
	AddStaticVehicle(582,-339.7648,1515.7938,75.4144,0.3375,1,162); // NR LV van 3
	AddStaticVehicle(582,-333.4105,1515.9668,75.4205,0.1876,1,162); // NR LV van 4
	AddStaticVehicle(582,-330.2840,1516.0878,75.4157,0.7987,1,162); // NR LV van 5
	AddStaticVehicle(582,-314.8701,1515.7623,75.4146,359.5338,1,162); // NR LV van 6
	AddStaticVehicle(582,-321.0234,1515.5247,75.4158,0.4367,1,162); // NR LV van 7
	AddStaticVehicle(488,-313.2704,1568.0045,75.5367,41.5533,1,162); // NR LV chopper

	//TOW TRUCK COMPANY

	AddPlayerClass(250,919.4405,-1252.2511,16.2109,275.1962,0,0,0,0,0,0); // TTC entrance
	AddPlayerClass(250,919.2770,-1265.0601,15.1719,359.9420,0,0,0,0,0,0); // TTC spawn
	AddStaticVehicle(525,901.2255,-1207.0852,16.8559,179.7441,158,158); // TTC car 1
	AddStaticVehicle(525,866.9298,-1206.5837,16.8550,178.3268,158,158); // TTC car 2
	AddStaticVehicle(525,830.9609,-1205.9209,16.8546,177.4763,158,158); // TTC car 3
	AddStaticVehicle(525,864.0557,-1245.2629,14.7412,269.8589,158,158); // TTC car 4
	AddStaticVehicle(525,863.8841,-1255.6554,14.7318,267.0167,158,158); // TTC car 5
	AddStaticVehicle(487,919.7804,-1270.5940,19.2626,90.6266,1,158); // TTC maverick
	AddStaticVehicle(552,906.1194,-1265.4368,14.3918,0.4216,1,158); // TTC utility van 1
	AddStaticVehicle(552,906.1854,-1246.1180,15.2051,358.1911,1,158); // TTC utility van 2

	//HITMAN AGENCY

	AddPlayerClass(250,-683.9400,939.5189,13.6328,272.6891,0,0,0,0,0,0); // HITMAN entrance
	AddPlayerClass(250,-688.3964,938.6566,13.6328,179.6282,0,0,0,0,0,0); // HITMAN spawn
	AddStaticVehicle(469,-654.8105,945.8045,12.1423,94.3256,0,0); // HITMAN sparrow 1
	AddStaticVehicle(469,-655.6641,962.3143,12.1423,90.9073,0,0); // HITMAN sparrow 2
	AddStaticVehicle(560,-669.6742,946.5518,11.8377,357.3036,0,0); // HITMAN sultan 1
	AddStaticVehicle(560,-674.5861,946.5967,11.8375,356.9076,0,0); // HITMAN sultan 2
	AddStaticVehicle(402,-674.4952,912.1575,11.9564,88.1506,0,0); // HITMAN buffalo 1
	AddStaticVehicle(402,-682.5430,912.1182,11.9364,90.1156,0,0); // HITMAN buffalo 2
	AddStaticVehicle(402,-690.4138,911.9108,12.0050,90.8769,0,0); // HITMAN buffalo 3
	AddStaticVehicle(402,-698.6599,911.5760,12.1313,91.7862,0,0); // HITMAN buffalo 4
	AddStaticVehicle(487,-714.7469,947.1063,12.4228,357.7184,0,0); // HITMAN maverick
	AddPlayerClass(250,-708.1443,966.3626,12.4811,76.0622,0,0,0,0,0,0); // HITMAN /FVEH
	AddStaticVehicle(461,-694.0099,945.6804,11.8183,0.0394,0,0); // HITMAN pcj 1
	AddStaticVehicle(461,-696.1598,945.7236,11.8618,6.8169,0,0); // HITMAN pcj 2
	AddStaticVehicle(461,-700.0532,934.6024,11.9097,175.4967,0,0); // HITMAN pcj 3
	AddStaticVehicle(461,-701.9243,934.6887,11.9458,175.8009,0,0); // HITMAN pcj 4

	//FEDERAL BUREAU OF INVESTIGATION FBI

	AddPlayerClass(250,314.6721,-1514.7864,24.9219,241.9116,0,0,0,0,0,0); // FBI entrance
	AddPlayerClass(250,312.0814,-1512.4830,24.9219,58.2965,0,0,0,0,0,0); // FBI spawn
	AddStaticVehicle(490,290.9015,-1517.7860,24.7218,234.1591,0,0); // FBI rancher 1
	AddStaticVehicle(490,293.9785,-1513.1304,24.7210,234.3363,0,0); // FBI rancher 2
	AddStaticVehicle(490,287.7979,-1522.1537,24.7206,234.1523,0,0); // FBI rancher 3
	AddStaticVehicle(490,297.0281,-1508.6216,24.7209,233.5063,0,0); // FBI rancher 4
	AddStaticVehicle(541,282.0369,-1531.5682,24.2187,234.0222,0,0); // FBI bullet 1
	AddStaticVehicle(541,279.0664,-1535.8818,24.2193,234.0466,0,0); // FBI bullet 2
	AddStaticVehicle(528,295.0953,-1540.8224,24.6379,54.9993,0,0); // FBI truck 
	AddStaticVehicle(601,292.4016,-1545.2437,24.3525,53.3975,0,0); // FBI swat van 1
	AddStaticVehicle(522,301.0141,-1490.9098,24.1563,232.9443,0,0); // FBI nrg 1
	AddStaticVehicle(522,303.9335,-1486.4569,24.1635,232.5459,0,0); // FBI nrg 2
	AddStaticVehicle(522,306.7749,-1481.6676,24.1621,232.0378,0,0); // FBI nrg 3
	AddPlayerClass(250,312.8574,-1503.8573,24.5938,53.0462,0,0,0,0,0,0); // FBI /FVEH

	//NATIONAL GUARD

	AddPlayerClass(250,223.0665,1872.6128,13.7344,90.7275,0,0,0,0,0,0); // NG spawn
	AddStaticVehicle(470,193.0107,1919.9250,17.6337,177.7058,1,1); // NG patriot 1
	AddStaticVehicle(470,202.3087,1919.9709,17.6348,176.2448,1,1); // NG patriot 2
	AddStaticVehicle(470,211.1554,1920.0035,17.6322,177.0537,1,1); // NG patriot 3
	AddStaticVehicle(470,220.2500,1920.1636,17.6313,179.3924,1,1); // NG patriot 4
	AddStaticVehicle(433,171.5411,1931.5817,18.7506,180.5804,1,1); // NG barracks 1
	AddStaticVehicle(433,177.9803,1931.3180,18.5113,179.0424,1,1); // NG barracks 2
	AddStaticVehicle(598,222.3322,1855.2716,12.6937,0.7082,1,202); // NG policecar 1
	AddStaticVehicle(598,213.9933,1854.6000,12.6637,1.2164,1,202); // NG policecar 2
	AddStaticVehicle(425,227.0795,1889.2382,18.2127,355.0132,1,202); // NG hunter 1
	AddStaticVehicle(425,200.8946,1888.1213,18.2201,3.1745,1,202); // NG hunter 2
	AddStaticVehicle(476,278.9976,2023.4585,18.3534,273.6915,1,202); // NG rustler
	AddStaticVehicle(520,300.7690,1993.4896,18.3639,275.1623,0,0); // NG hydra 1
	AddStaticVehicle(520,300.0462,1954.9688,18.3639,270.5513,0,0); // NG hydra 2
	AddPlayerClass(250,287.1096,1821.1129,17.6406,91.9654,0,0,0,0,0,0); // NG airport exit
	AddPlayerClass(250,284.6866,1821.0803,17.6406,89.1453,0,0,0,0,0,0); // NG airport enter
	AddStaticVehicle(541,203.8382,1862.8643,12.7657,273.1014,202,1); // NG bullet 1
	AddStaticVehicle(541,203.7218,1870.6365,12.7655,272.1086,202,1); // NG bullet 2
	AddPlayerClass(250,2447.2686,2376.2681,12.1635,271.4169,0,0,0,0,0,0); // CITIY HALL LV entrance
	AddStaticVehicle(409,2434.4746,2376.3083,10.6203,179.5579,1,1); // CITY HALL LV stretch
	AddPlayerClass(250,-2765.6863,375.6233,6.3359,94.6606,0,0,0,0,0,0); // CITIY HALL SF /entrance
	AddStaticVehicle(409,-2756.7935,375.8840,4.1389,180.6878,1,1); // CITI HALL SF stretch
	AddStaticVehicle(409,1481.3381,-1741.0288,13.3469,89.4384,1,1); // CITY HALL LS stretch
	AddPlayerClass(250,1480.9697,-1772.2487,18.7958,182.6292,0,0,0,0,0,0); // CITY HALL LS entrance

	AddPlayerClass(304,300.2081,-1154.4183,81.3900,313.7946,0,0,0,0,0,0); // HQ COSA NOSTRA
	AddStaticVehicle(409,286.8106,-1174.6891,80.7129,223.2032,127,127); // COSA NOSTRA LIMO
	AddStaticVehicle(421,292.7531,-1181.1669,80.7966,223.0897,127,127); // COSA NOSTRA WASHINGTON 1
	AddStaticVehicle(421,297.8604,-1186.4309,80.7966,222.5436,127,127); // COSA NOSTRA WASHINGTON 2
	AddStaticVehicle(482,287.4807,-1147.1760,81.0290,222.4821,127,127); // COSA NOSTRA BURRITO 
	AddStaticVehicle(487,279.0134,-1184.8160,80.3878,317.6113,127,127); // COSA NOSTRA MAVERICK
	AddStaticVehicle(545,315.8337,-1166.9818,80.7252,132.5602,127,127); // COSA NOSTRA HUSTLER
	AddStaticVehicle(579,281.3050,-1168.7826,80.8467,223.4188,127,127); // COSA NOSTRA HUNTLEY 1
	AddStaticVehicle(579,276.4467,-1163.6445,80.8484,223.4943,127,127); // COSA NOSTRA HUNTLEY 2
	AddStaticVehicle(461,296.8085,-1150.2478,80.4950,134.4722,127,127); // COSA NOSTRA PCJ 1
	AddStaticVehicle(461,295.4047,-1148.9012,80.4918,131.4003,127,127); // COSA NOSTRA PCJ 2
	/////////////////////////////////////////////////////////
	AddPlayerClass(304,2140.9307,-1801.9806,16.1475,85.0558,0,0,0,0,0,0); // HQ GRAPE STREET
	AddStaticVehicle(487,2142.6731,-1812.0000,19.0324,273.0931,179,179); // GRAPE STREET MAVERICK
	AddStaticVehicle(461,2153.6960,-1805.5168,13.1372,270.4706,179,179); // GRAPE STREET PCJ 1
	AddStaticVehicle(461,2153.6716,-1803.3760,13.1514,271.5005,179,179); // GRAPE STREET PCJ 2
	AddStaticVehicle(567,2157.0667,-1793.4705,13.2230,178.6200,179,179); // GRAPE STREET SAVANA 1
	AddStaticVehicle(567,2161.3557,-1793.5295,13.2351,179.4898,179,179); // GRAPE STREET SAVANA 2
	AddStaticVehicle(579,2165.5837,-1793.9867,13.2965,178.0482,179,179); // GRAPE STREET HUNTLEY 1
	AddStaticVehicle(579,2169.8892,-1793.9513,13.2953,180.4876,179,179); // GRAPE STREET HUNTLEY 2
	AddStaticVehicle(575,2160.8740,-1809.5229,12.9787,270.4091,179,179); // GRAPE STREET BROADWAY 1
	AddStaticVehicle(409,2169.5842,-1809.5048,13.1750,270.0032,179,179); // GRAPE STREET limo
	AddStaticVehicle(459,2179.0132,-1809.5237,13.4219,270.0648,179,179); // GRAPE STREET burrito
	///////////////////////////////////////////////////////////AddPlayerClass(304,2495.3308,-1691.1262,14.7656,176.2376,0,0,0,0,0,0); // LIME HOOD HQ
	AddStaticVehicle(461,2486.7581,-1686.1075,13.0948,359.2699,86,86); // LIME HOOD PCJ 1
	AddStaticVehicle(461,2489.1362,-1686.1338,13.0959,354.5932,86,86); // LIME HOOD PCJ 2
	AddStaticVehicle(409,2498.3425,-1681.9288,13.1592,282.5662,86,86); // LIME HOOD LIMO
	AddStaticVehicle(535,2505.7854,-1693.5555,13.3191,359.8549,86,86); // LIME HOOD SLAMVAN
	AddStaticVehicle(579,2508.8628,-1674.2335,13.3620,337.6395,86,86); // LIME HOOD HUNTLEY
	AddStaticVehicle(579,2509.6802,-1667.4980,13.4104,7.1705,86,86); // LIME HOOD HUNTLEY 2
	AddStaticVehicle(492,2501.7559,-1657.1144,13.1801,62.3296,86,86); // LIME HOOD GREENWOOD 1
	AddStaticVehicle(492,2494.5042,-1654.6372,13.2058,84.3879,86,86); // LIME HOOD GREENWOOD 2
	AddStaticVehicle(487,2528.1917,-1677.7120,20.1069,90.6180,86,86); // LIME HOOD MAVERICK
	AddPlayerClass(304,2497.2659,-1670.8948,13.3359,88.4887,0,0,0,0,0,0); // LIME HOOD /FVEH
	AddPlayerClass(304,2164.3132,-1802.4219,13.3681,275.2371,0,0,0,0,0,0); // GRAPE STREET /FVEH
	AddPlayerClass(304,302.3689,-1170.3157,80.9099,213.5332,0,0,0,0,0,0); // COSA NOSTRA /FVEH
	AddPlayerClass(304,2034.0201,-1401.6705,17.2934,2.0975,0,0,0,0,0,0); // HQ PARAMEDICS


}

AssignPlayerData(playerid)
{
	cache_get_value_int(0, "ID", Player[playerid][ID]);

	cache_get_value_int(0, "LoggedIn", Player[playerid][LoggedIn]);
	cache_get_value_int(0, "Admin", Player[playerid][Admin]);
	cache_get_value_int(0, "Skin", Player[playerid][Skin]);
	cache_get_value_float(0, "Health", Player[playerid][Health]);
	cache_get_value_float(0, "Armor", Player[playerid][Armor]);
	cache_get_value_int(0, "Money", Player[playerid][Money]);
	cache_get_value_int(0, "BankMoney", Player[playerid][BankMoney]);
	
	cache_get_value_float(0, "X", Player[playerid][X_Pos]);
	cache_get_value_float(0, "Y", Player[playerid][Y_Pos]);
	cache_get_value_float(0, "Z", Player[playerid][Z_Pos]);
	cache_get_value_float(0, "Angle", Player[playerid][A_Pos]);
	cache_get_value_int(0, "Interior", Player[playerid][Interior]);
	cache_get_value_int(0, "FactionID", Player[playerid][FactionID]);

	SetMoney(playerid, Player[playerid][Money]);
	SetPlayerSkin(playerid, Player[playerid][Skin]);
	SetHealth(playerid, Player[playerid][Health]);
	SetArmor(playerid, Player[playerid][Armor]);
	return 1;
}

DelayedKick(playerid, time = 500)
{
	SetTimerEx("_KickPlayerDelayed", time, false, "d", playerid);
	return 1;
}

UpdatePlayerData(playerid, reason)
{
	if(Player[playerid][LoggedIn] == false) return 0;

	GetPlayerHealth(playerid, Player[playerid][Health]);
	GetPlayerArmour(playerid, Player[playerid][Armor]);

	if(reason == 1)
	{
		GetPlayerPos(playerid, Player[playerid][X_Pos], Player[playerid][Y_Pos], Player[playerid][Z_Pos]);
		GetPlayerFacingAngle(playerid, Player[playerid][A_Pos]);
	}
	
	mysql_format(g_SQL, query, 250, "UPDATE `players` SET `Money` = %d, `BankMoney` = %d, `Health` = %f, `Armor` = %f, `X` = %f, `Y` = %f, `Z` = %f, `Angle` = %f, `Interior` = %d WHERE `ID` = %d LIMIT 1", 
		Player[playerid][Money], 
		Player[playerid][BankMoney],
		Player[playerid][Health],
		Player[playerid][Armor], 
		Player[playerid][X_Pos], 
		Player[playerid][Y_Pos], 
		Player[playerid][Z_Pos], 
		Player[playerid][A_Pos], 
		GetPlayerInterior(playerid), 
		Player[playerid][ID]);
	mysql_tquery(g_SQL, query);
	return 1;
}

SendAdminMessage(color, str[])
{
	foreach(new i: Player)
	{
		if(!Player[i][LoggedIn]) continue;
		if(Player[i][Admin] > 0) SendClientMessage(i, color, str);
	}
	return 1;
}

SendErrorMessage(playerid, color, str[])
{
	format(String, 128, "[ERROR]: %s", str);
	return SendClientMessage(playerid, color, String);
}

SendSyntaxMessage(playerid, color, str[])
{
	format(String, 128, "[SYNTAX]: %s", str);
	return SendClientMessage(playerid, color, String);
}

SendLocalMessage(Float:radi, playerid, color, string[])
{
	new Float: X, Float: Y, Float: Z;
	GetPlayerPos(playerid, X, Y, Z);
	foreach(Player, i)
	{
		new Float: X2, Float: Y2, Float: Z2;
		GetPlayerPos(i, X2, Y2, Z2);
		if(IsPlayerInRangeOfPoint(i, radi, X, Y, Z)) { SendClientMessage(i, color, string); }
	}
	return 1;
}

SetPlayerVirtualWorldEx(playerid, vw) return SetPlayerVirtualWorld(playerid, vw), Player[playerid][VirtualWorld] = vw, 1;
SetPlayerInteriorEx(playerid, intt) return SetPlayerInterior(playerid, intt), Player[playerid][Interior] = intt, 1;

GetPlayerRPName(playerid, name[], len)
{
	GetPlayerName(playerid, name, len);
	for(new i = 0; i < len; i++)
	{
		if (name[ i ] == '_')
		name[i] = ' ';
	}
}

pName(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, sizeof name);
	return name;
}

SetHealth(playerid, Float: health)
{
	Player[playerid][Health] = health;
	SetPlayerHealth(playerid, health);
}

SetArmor(playerid, Float: armor)
{
	Player[playerid][Armor] = armor;
	SetPlayerArmour(playerid, armor);
}

GiveMoney(playerid, money)
{
	Player[playerid][Money] += money;
	GivePlayerMoney(playerid, money);
}

SetMoney(playerid, money)
{
	Player[playerid][Money] = money;
	ResetPlayerMoney(playerid);
	GivePlayerMoney(playerid, money);
}

ResetMoney(playerid)
{
	Player[playerid][Money] = 0;
	ResetPlayerMoney(playerid);
}

GetOfflineAdmins(playerid)
{
    new Cache:r = mysql_query(g_SQL, "SELECT Name, Admin FROM `players` WHERE `Admin` > 0 AND `LoggedIn` = 0 ", true);
    if(cache_num_rows())
    {
        new name[MAX_PLAYER_NAME];
        for(new i=0; i < cache_num_rows(); i++)
        {
        	new adminLevel;
            cache_get_value_name(i, "Name", name);
            cache_get_value_name_int(i, "Admin", adminLevel);
            if(GetPlayerIdFromName(name) == INVALID_PLAYER_ID)
                SendClientMessage(playerid, 0xFF5729FF, sprintf("%s{%s} - Admin Level %d", COLOR_WHITE, name, adminLevel));
        }
    }
    cache_delete(r);
}

GetPlayerIdFromName(playername[])
{
  for(new i = 0; i <= GetPlayerPoolSize(); i++)
  {
    if(IsPlayerConnected(i))
    {
      new playername2[MAX_PLAYER_NAME];
      GetPlayerName(i, playername2, sizeof(playername2));
      if(strcmp(playername2, playername, true, strlen(playername)) == 0)
      {
        return i;
      }
    }
  }
  return INVALID_PLAYER_ID;
}

GetFactionIdFromName(factionName[])
{
    if(!strcmp(factionName,"none",true)) return FACTION_NONE;
	if(!strcmp(factionName,"pd",true)) return FACTION_PD;
	if(!strcmp(factionName,"fbi",true)) return FACTION_FBI;
	if(!strcmp(factionName,"ng",true)) return FACTION_NG;
	if(!strcmp(factionName,"medics",true)) return FACTION_MEDICS;
	return -1;
}

GetFactionEnumFromParam(factionId)
{
	switch(factionId)
	{
		case FACTION_PD:
		{
			return factionsIds:PD;
		}
		case FACTION_FBI:
		{
			return factionsIds:FBI;
		}
		case FACTION_NG:
		{
			return factionsIds:NG;
		}
		case FACTION_MEDICS:
		{
			return factionsIds:MEDICS;
		}
		default:
		{
			return factionsIds:NONE;
		}
	}
	return 1;
}

GetFactionLeader(factionsId:id)
{
	new message[255] = "No Leader";	
	new bool:isLogged = false;
    new Cache:r = mysql_query(g_SQL, sprintf("SELECT p.Name, p.LoggedIn FROM `players` p JOIN `factions` f ON f.`LeaderID` = p.`ID`  WHERE f.`ID` = %d LIMIT 1", id));

    if(cache_num_rows()) 
	{

		cache_get_value_bool(0, "LoggedIn", isLogged);
		cache_get_value(0, "Name", message, 50);
		printf("%d", isLogged);
    }
    format(message, sizeof(message), "%s\t(%s{FFFFFF})", message, isLogged ? ("{00BA19}Online") : ("{C90000}Offline"));

    cache_delete(r);
    return message;
}

SetNewFactionForPlayer(playerid, factionId)
{
    new oldFactionId = Player[playerid][FactionID];
	new factionsId:factionIdEnum = factionsId:GetFactionEnumFromParam(factionId);

	Player[playerid][FactionID] = factionId;
	Player[playerid][Skin] = Faction[factionIdEnum][PrimarySkinID];
	Player[playerid][X_Pos] = Faction[factionIdEnum][SpawnX];
	Player[playerid][Y_Pos] = Faction[factionIdEnum][SpawnY];
	Player[playerid][Z_Pos] = Faction[factionIdEnum][SpawnZ];
	Player[playerid][Interior] = Faction[factionIdEnum][Interior];

	FactionMembers[playerid][Rank] = 1;
	new date[12],time[12], datetime[36];
	new y,m,d,h,mi,s;

	getdate(y,m,d);
	gettime(h,mi,s);

	format(date, 18, "%d-%d-%d", d, m, y);
	format(time, 18, "%02d:%02d:%02d", h, mi, s);
	format(datetime, 36, "%s %s", date, time);

	strcat(FactionMembers[playerid][JoinDate], datetime);
	FactionMembers[playerid][Warns] = 0;

	mysql_format(g_SQL, query, 250, "UPDATE `players` SET `Interior` = %d, `X` = %f, `Y` = %f, `Z` = %f, `Angle` = %f, `Skin` = %d WHERE `ID` = %d LIMIT 1", Player[playerid][Interior], Player[playerid][X_Pos], Player[playerid][Y_Pos], Player[playerid][Z_Pos], Player[playerid][A_Pos], Player[playerid][Skin], Player[playerid][ID]);
	mysql_tquery(g_SQL, query);

    if(oldFactionId == 0)
    {
    	mysql_format(g_SQL, query, 250, "INSERT INTO `factionMembers` (`MemberID`,`FactionID`) VALUES (%d, %d)", Player[playerid][ID], Player[playerid][FactionID]);
    	mysql_tquery(g_SQL, query);
    }
    else if(oldFactionId != 0 && factionId != 0)
    {
        mysql_format(g_SQL, query, 250, "UPDATE `factionMembers` SET `FactionID` = %d WHERE `MemberID` = %d", Player[playerid][FactionID], Player[playerid][ID]);
        mysql_tquery(g_SQL, query);
    }
    else if(oldFactionId != 0 && factionId == 0)
    {
        mysql_format(g_SQL, query, 250, "DELETE FROM `factionMembers` WHERE `MemberID` = %d", Player[playerid][ID]);
        mysql_tquery(g_SQL, query);
    }

	SendClientMessage(playerid, COLOR_IMPORTANT_MESSAGE, sprintf("You are now a member of {%s}%s", Faction[factionIdEnum][Color], Faction[factionIdEnum][Name]));

	SetSpawnInfo(playerid, NO_TEAM, Player[playerid][Skin], Player[playerid][X_Pos], Player[playerid][Y_Pos], Player[playerid][Z_Pos], Player[playerid][A_Pos], 0, 0, 0, 0, 0, 0);
	SpawnPlayer(playerid);
}

//STOCK FUNCTIONS

stock ToggleFlying(playerid, bool: toggle)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z), Player[playerid][IsAdminFlying] = toggle;
    if(toggle) 
    {
    	SetPlayerPos(playerid, x, y, z + 5.0);
    	Player[playerid][AdminFlyingTimerId] = SetTimerEx("GeneralTimer", 180, true, "ii", playerid, 1);
    	ApplyAnimation(playerid, "PARACHUTE", "PARA_steerR", 6.1, 1, 1, 1, 1, 0, 1);
    	return 1;
    }
    SetPlayerPos(playerid, x, y, z), KillTimer(Player[playerid][AdminFlyingTimerId]), Player[playerid][AdminFlyingTimerId] = -1, SetPlayerHealth(playerid, 150);
    return 1;
}

stock SetPlayerLookAt(playerid, Float: x, Float: y) 
{
    new Float: Px, Float: Py, Float: Pa;
    GetPlayerPos(playerid, Px, Py, Pa), Pa = floatabs(atan((y - Py) / (x - Px)));
    if(x <= Px && y >= Py) Pa = floatsub(180.0, Pa);
    else if(x < Px && y < Py) Pa = floatadd(Pa, 180.0);
    else if(x >= Px && y <= Py) Pa = floatsub(360.0, Pa);
    Pa = floatsub(Pa, 90.0);
    if(Pa >= 360.0) Pa = floatsub(Pa, 360.0);
    SetPlayerFacingAngle(playerid, Pa);
}

stock SendAreaMessage(Float:arearadi, playerid, string[],color)
{
    GetPlayerPos(playerid, XYZA[0],XYZA[1],XYZA[2]);
    if(strlen(string) < 100) { foreach(new i : Player) if(Player[playerid][VirtualWorld] == Player[i][VirtualWorld] && IsPlayerInRangeOfPoint(i, arearadi, XYZA[0], XYZA[1], XYZA[2])) SendClientMessage(i, color, string); return 1; }
    new text1[97], text2[97];
    strcat(text1, string), strcat(text1, "..."), strcat(text2, "..."), strcat(text2, string[96]);
    foreach(new i : Player) if(Player[playerid][VirtualWorld] == Player[i][VirtualWorld] && IsPlayerInRangeOfPoint(i, arearadi, XYZA[0], XYZA[1], XYZA[2])) SendClientMessage(i, color, text1), SendClientMessage(i, color, text2);
    return 1;
}

stock IsNumeric(const string[])
{
    for(new i = 0, j = strlen(string); i < j; i++) if(string[i] > '9' || string[i] < '0') return 0;
    return 1;
}



//DIALOGS

Dialog:Null(playerid, response, listitem, inputtext[]) return 1;

Dialog:Register(playerid, response, listitem, inputtext[])
{
	if(!response) return Kick(playerid);

	if(strlen(inputtext) <= 5) return Dialog_Show(playerid, Register, DIALOG_STYLE_PASSWORD, "Registration", "Your password must be longer than 5 characters!\nPlease enter your password in the field below:", "Register", "Abort");

	for(new i = 0; i < 16; i++) Player[playerid][Salt][i] = random(94) + 33;
	SHA256_PassHash(inputtext, Player[playerid][Salt], Player[playerid][Password], 65);

	mysql_format(g_SQL, query, 221, "INSERT INTO `players` (`Name`, `Password`, `Salt`) VALUES ('%e', '%s', '%e')", pName(playerid), Player[playerid][Password], Player[playerid][Salt]);
	mysql_tquery(g_SQL, query, "OnPlayerRegister", "d", playerid);
	return 1;
}

Dialog:Login(playerid, response, listitem, inputtext[])
{
	if(!response) return Kick(playerid);

	new hashed_pass[65];
	SHA256_PassHash(inputtext, Player[playerid][Salt], hashed_pass, 65);

	if(strcmp(hashed_pass, Player[playerid][Password]) == 0)
	{
		SendClientMessage(playerid, 0xFFFFFFFF, "You have been successfully logged in.");

		cache_set_active(Player[playerid][Cache_ID]);

		AssignPlayerData(playerid);

		//check if Player is Admin
		if(Player[playerid][Admin] > 0) 
		{
			OnlineAdmins++;
			Player[playerid][IsAdminFlying] = false;
			Player[playerid][AdminFlyingTimerId] = -1;
		}
		cache_delete(Player[playerid][Cache_ID]);
		Player[playerid][Cache_ID] = MYSQL_INVALID_CACHE;

		if(Player[playerid][FactionID] > 0)
		{
			new Cache:r = mysql_query(g_SQL, sprintf("SELECT `Rank`, `JoinDate`, `Warns` FROM `factionMembers` WHERE `MemberID` = %d LIMIT 1", Player[playerid][ID]));

		    if(cache_num_rows()) 
			{
				cache_get_value_int(0, "Rank", FactionMembers[playerid][Rank]);
				cache_get_value(0, "JoinDate", FactionMembers[playerid][JoinDate], 255);
				cache_get_value_int(0, "Warns", FactionMembers[playerid][Warns]);
				printf("%d -- %s -- %d", FactionMembers[playerid][Rank], FactionMembers[playerid][JoinDate], FactionMembers[playerid][Warns]);
		    }
		    cache_delete(r);
		}

		KillTimer(Player[playerid][LoginTimer]);
		Player[playerid][LoginTimer] = 0;
		Player[playerid][DrivingVehicleId] = 0;


		Player[playerid][LoggedIn] = true;
		format(String, 256, "UPDATE `players` SET `LoggedIn` = %d WHERE `ID` = %d", Player[playerid][LoggedIn], Player[playerid][ID]);
		mysql_tquery(g_SQL, String, "", "");

		Player[playerid][VirtualWorld] = 0;

		TextDrawShowForPlayer(playerid, BLog);

		SetSpawnInfo(playerid, NO_TEAM, Player[playerid][Skin], Player[playerid][X_Pos], Player[playerid][Y_Pos], Player[playerid][Z_Pos], Player[playerid][A_Pos], 0, 0, 0, 0, 0, 0);
		SpawnPlayer(playerid);
	}
	else
	{
		Player[playerid][LoginAttempts]++;

		if (Player[playerid][LoginAttempts] >= 3)
		{
			Dialog_Show(playerid, Null, DIALOG_STYLE_MSGBOX, "Login", "You have mistyped your password too often (3 times).", "Okay", "");
			DelayedKick(playerid);
		}
		else Dialog_Show(playerid, Login, DIALOG_STYLE_PASSWORD, "Login", "Wrong password!\nPlease enter your password in the field below:", "Login", "Abort");
	}
	return 1;
}

Dialog:ControlPanel(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	switch(listitem)
	{
		case 0: Dialog_Show(playerid, ChangeHostname, DIALOG_STYLE_INPUT, "Input hostname", "Please, input your desired hostname:", "Done", "Back");
		case 1: Dialog_Show(playerid, SetPassword, DIALOG_STYLE_INPUT, "Input password", "(Set 0 for no password)\nPlease, input your desired servers password:", "Done", "Back");
		case 2: Dialog_Show(playerid, ChangeMode, DIALOG_STYLE_INPUT, "Input mode", "Please, input your desired servers mode:", "Done", "Back");
		case 3: Dialog_Show(playerid, ChangeLang, DIALOG_STYLE_INPUT, "Input language", "Please, input your desired servers language:", "Done", "Back");
		case 4: SendRconCommand("gmx");
	}
	return 1;
}

Dialog:ChangeHostname(playerid, response, listitem, inputtext[])
{
	if(!response) return Dialog_Show(playerid, ControlPanel, DIALOG_STYLE_LIST, "Server control panel", "\
		Change server hostname\n\
		Set servers password\n\
		Change servers 'mode'\n\
		Change servers 'language'\n\
		Restart server", "OK", "Cancel");
	new cmd[256];
	format(cmd, sizeof cmd, "hostname %s", inputtext);
	SendRconCommand(cmd);
	format(String, 300, "You changed servers hostname to %s", cmd);
	SendClientMessage(playerid, COLOR_ORANGE, String);
	Log(adminlog, INFO, "Administrator %s changed servers hostname to %s", Player[playerid][Name], cmd);
	return 1;
}

Dialog:SetPassword(playerid, response, listitem, inputtext[])
{
	if(!response) return Dialog_Show(playerid, ControlPanel, DIALOG_STYLE_LIST, "Server control panel", "\
		Change server hostname\n\
		Set servers password\n\
		Change servers 'mode'\n\
		Change servers 'language'\n\
		Restart server", "OK", "Cancel");
	new cmd[64];
	format(cmd, sizeof cmd, "password %s", inputtext);
	SendRconCommand(cmd);
	format(String, 300, "You set servers password to %s", cmd);
	SendClientMessage(playerid, COLOR_ORANGE, String);
	Log(adminlog, INFO, "Administrator %s set servers password to %s", Player[playerid][Name], cmd);
	return 1;
}

Dialog:ChangeMode(playerid, response, listitem, inputtext[])
{
	if(!response) return Dialog_Show(playerid, ControlPanel, DIALOG_STYLE_LIST, "Server control panel", "\
		Change server hostname\n\
		Set servers password\n\
		Change servers 'mode'\n\
		Change servers 'language'\n\
		Restart server", "OK", "Cancel");
	new cmd[32];
	format(cmd, sizeof cmd, "gamemodetext %s", inputtext);
	SendRconCommand(cmd);
	format(String, 300, "You changed servers 'mode' to %s", cmd);
	SendClientMessage(playerid, COLOR_ORANGE, String);
	Log(adminlog, INFO, "Administrator %s changed servers 'mode' to %s", Player[playerid][Name], cmd);
	return 1;
}

Dialog:ChangeLang(playerid, response, listitem, inputtext[])
{
	if(!response) return Dialog_Show(playerid, ControlPanel, DIALOG_STYLE_LIST, "Server control panel", "\
		Change server hostname\n\
		Set servers password\n\
		Change servers 'mode'\n\
		Change servers 'language'\n\
		Restart server", "OK", "Cancel");
	new cmd[32];
	format(cmd, sizeof cmd, "language %s", inputtext);
	SendRconCommand(cmd);
	format(String, 300, "You changed servers 'language' to %s", cmd);
	SendClientMessage(playerid, COLOR_ORANGE, String);
	Log(adminlog, INFO, "Administrator %s changed servers to %s", Player[playerid][Name], cmd);
	return 1;
}


/*Dialog:CreateHouseType(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	new items[2048] = "PosX\tPosY\tPosZ\tInteriorId\n";
    houseCreateSelectedTypeIndex = listitem;
	switch(listitem)
	{
	    case 0:
	    {
	        for(new x=0; x < sizeof(houseInteriorsS); x++)
	        {
				format(items, sizeof(items), "%s%f\t%f\t%f\t%d\n", items,houseInteriorsS[x][0], houseInteriorsS[x][1], houseInteriorsS[x][2], houseInteriorsS[x][3]);
	        }
			ShowPlayerDialog(playerid, CreateHouseInterior, DIALOG_STYLE_TABLIST_HEADERS, "Choose interior", items, "Select", "Back");
	    }
	    case 1:
	    {
	        for(new x=0; x < sizeof(houseInteriorsM); x++)
	        {
				format(items, sizeof(items), "%s%f\t%f\t%f\t%d\n", items,houseInteriorsM[x][0], houseInteriorsM[x][1], houseInteriorsM[x][2], houseInteriorsM[x][3]);
	        }
	        ShowPlayerDialog(playerid, CreateHouseInterior, DIALOG_STYLE_TABLIST_HEADERS, "Choose interior", items, "Select", "Back");
	    }
	    case 2:
	    {
			for(new x=0; x < sizeof(houseInteriorsB); x++)
	        {
	            format(items, sizeof(items), "%s%f\t%f\t%f\t%d\n", items,houseInteriorsB[x][0], houseInteriorsB[x][1], houseInteriorsB[x][2], houseInteriorsB[x][3]);
	        }
	        ShowPlayerDialog(playerid, CreateHouseInterior, DIALOG_STYLE_TABLIST_HEADERS, "Choose interior", items, "Select", "Back");
	    }
    }
}

Dialog:CreateHouseInterior(playerid, response, listitem, inputtext[])
{
	if(!response) return cmd_createhouse(playerid,"");
    houseCreateSelectedIntIndex = listitem;
    ShowPlayerDialog(playerid, CreateHousePrice, DIALOG_STYLE_INPUT, "House Price", "Enter the house price below:", "Next", "Back");
}

Dialog:CreateHousePrice(playerid, response, listitem, inputtext[])
{
	if(!response)
    {
        new items[2048]="PosX\tPosY\tPosZ\tInteriorId\n";
        switch(houseCreateSelectedTypeIndex)
        {
            case 0:
            {
                for(new x=0; x < sizeof(houseInteriorsS); x++)
                {
                    format(items, sizeof(items), "%s%f\t%f\t%f\t%d\n", items,houseInteriorsS[x][0], houseInteriorsS[x][1], houseInteriorsS[x][2], houseInteriorsS[x][3]);
                }
                ShowPlayerDialog(playerid, CreateHouseInterior, DIALOG_STYLE_TABLIST_HEADERS, "Choose interior", items, "Select", "Back");
            }
            case 1:
            {
                for(new x=0; x < sizeof(houseInteriorsM); x++)
                {
                    format(items, sizeof(items), "%s%f\t%f\t%f\t%d\n", items,houseInteriorsM[x][0], houseInteriorsM[x][1], houseInteriorsM[x][2], houseInteriorsM[x][3]);
                }
                ShowPlayerDialog(playerid, CreateHouseInterior, DIALOG_STYLE_TABLIST_HEADERS, "Choose interior", items, "Select", "Back");
            }
            case 2:
            {
                for(new x=0; x < sizeof(houseInteriorsB); x++)
                {
                    format(items, sizeof(items), "%s%f\t%f\t%f\t%d\n", items,houseInteriorsB[x][0], houseInteriorsB[x][1], houseInteriorsB[x][2], houseInteriorsB[x][3]);
                }
                ShowPlayerDialog(playerid, CreateHouseInterior, DIALOG_STYLE_TABLIST_HEADERS, "Choose interior", items, "Select", "Back");
            }
        }
    }
    else 
    {
        houseCreateSelectedPrice = strval(inputtext);
        ShowPlayerDialog(playerid, CreateHouseLevel, DIALOG_STYLE_INPUT, "House Level", "Enter the level of house:", "Next", "Back");
    }
}

Dialog:CreateHouseLevel(playerid, response, listitem, inputtext[])
{
	if(!response)
    {
        ShowPlayerDialog(playerid, CreateHousePrice, DIALOG_STYLE_INPUT, "House Price", "Enter the house price below:", "Create", "Back");
    }
    else
    {
        houseCreateSelectedLevel = strval(inputtext);
        new price, lvl, intId, Float:IntP[3], Float:x, Float:y, Float:z;

        switch(houseCreateSelectedTypeIndex)
        {
            case 0:
            {
                IntP[0] = houseInteriorsS[houseCreateSelectedIntIndex][0];
                IntP[1] = houseInteriorsS[houseCreateSelectedIntIndex][1];
                IntP[2] = houseInteriorsS[houseCreateSelectedIntIndex][2];
                intId   = houseInteriorsS[houseCreateSelectedIntIndex][3];
            }
            case 1:
            {
                IntP[0] = houseInteriorsM[houseCreateSelectedIntIndex][0];
                IntP[1] = houseInteriorsM[houseCreateSelectedIntIndex][1];
                IntP[2] = houseInteriorsM[houseCreateSelectedIntIndex][2];
                intId   = houseInteriorsM[houseCreateSelectedIntIndex][3];
            }
            case 2:
            {
                IntP[0] = houseInteriorsB[houseCreateSelectedIntIndex][0];
                IntP[1] = houseInteriorsB[houseCreateSelectedIntIndex][1];
                IntP[2] = houseInteriorsB[houseCreateSelectedIntIndex][2];
                intId   = houseInteriorsB[houseCreateSelectedIntIndex][3];
            }
        }

        price = houseCreateSelectedPrice;
        lvl = houseCreateSelectedLevel;

        GetPlayerPos(playerid, x, y, z);

        for(new r = 0; r != sizeof(House); r++) if(!IsValidDynamicPickup(House[r][hPickup]))
        {


            new ORM:ormid = Houses[r][ORM_ID] = orm_create("houses",MySQLCon);
            orm_addvar_int(ormid, Houses[r][ID], "ID"), orm_addvar_string(ormid, Houses[r][Owner], 24, "Owner"), orm_addvar_string(ormid, Houses[r][Discription], 26, "Discription"),
            orm_addvar_float(ormid, Houses[r][EnterX], "EnterX"), orm_addvar_float(ormid, Houses[r][EnterY], "EnterY"),
            orm_addvar_float(ormid, Houses[r][EnterZ], "EnterZ"), orm_addvar_float(ormid, Houses[r][IntX], "IntX"),
            orm_addvar_float(ormid, Houses[r][IntY], "IntY"), orm_addvar_float(ormid, Houses[r][IntZ], "IntZ"),
            orm_addvar_int(ormid, Houses[r][Interior], "Interior"), orm_addvar_int(ormid, Houses[r][Value], "Value"),
            orm_addvar_int(ormid, Houses[r][Lock], "Lock"), orm_addvar_int(ormid, Houses[r][RentPrice], "RentPrice"),
            orm_addvar_int(ormid, Houses[r][Rentabil], "Rentabil"), orm_addvar_int(ormid, Houses[r][Level], "Level"),
            orm_addvar_int(ormid, Houses[r][VW], "VW"), orm_addvar_int(ormid, Houses[r][Till], "Till"), orm_addvar_int(ormid, Houses[r][HPrice], "HPrice"),
            orm_addvar_int(ormid, Houses[r][hUpg][0], "Hp"), orm_addvar_int(ormid, Houses[r][hUpg][1], "Arm"),
            orm_insert(ormid,"OnHouseAdd","dfffdfffdd", r, IntP[0], IntP[1], IntP[2], intId, x, y, z, price, lvl), orm_setkey(ormid,"ID");
            SendClientMessage(playerid, COLOR_LIGHTBLUE, "* The house was added to the server.");
            return r;
        }
    }
}*/

Dialog:Teleports(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
	switch(listitem)
	{
		case 0: Dialog_Show(playerid, LS_Teleports, DIALOG_STYLE_LIST, "Los Santos teleports", "\
			Unity station\n\
			Airport\n\
			Bank\n\
			Car dealership\n\
			Hospital\n\
			Police departament\n\
			Docks", "Choose", "Back");
		case 1: Dialog_Show(playerid, SF_Teleports, DIALOG_STYLE_LIST, "San Fierro teleports", "\
			Train station\n\
			Car dealership\n\
			Bank\n\
			Hospital\n\
			Police departament\n\
			Docks", "Choose", "Back");
		case 2: Dialog_Show(playerid, LV_Teleports, DIALOG_STYLE_LIST, "Las Venturas teleports", "\
			Train station\n\
			Car dealership\n\
			Bank\n\
			Casino Four Dragons\n\
			FBI\n\
			Hospital", "Choose", "Back");
	}
	return 1;
}

Dialog:LS_Teleports(playerid, response, listitem, inputtext[])
{
	if(!response) return Dialog_Show(playerid, Teleports, DIALOG_STYLE_LIST, "Teleports", "\
		Los Santos\n\
		San Fierro\n\
		Las Venturas", "OK", "Cancel");
	new Float: X, Float: Y, Float: Z;
	switch(listitem)
	{
		case 0: X = 1792.6862, Y = -1924.5055, Z = 13.3904;		// Unity station
		case 1: X = 1681.5308, Y = -2319.1914, Z = 13.3828; 	// Airport
		case 2: X = 1749.5062, Y = -1668.5699, Z = 13.3828; 	// Bank
		case 3: X = 558.0125, Y = -1243.7642, Z = 17.0432; 		// Car dealership
		case 4: X = 1201.1337, Y = -1327.0913, Z = 13.3984; 	// Hospital
		case 5: X = 1529.3977, Y = -1671.9962, Z = 13.3828; 	// Police departament
		case 6: X = 2320.9243, Y = -2336.6333, Z = 13.3828; 	// Docks
	}
	if(GetPlayerState(playerid) == 2) SetVehiclePos(GetPlayerVehicleID(playerid), X, Y, Z);
	else SetPlayerPos(playerid, X, Y, Z);
	SetPlayerInterior(playerid, 0);
	SetPlayerVirtualWorld(playerid, 0);
	return 1;
}

Dialog:SF_Teleports(playerid, response, listitem, inputtext[])
{
	if(!response) return Dialog_Show(playerid, Teleports, DIALOG_STYLE_LIST, "Teleports", "\
		Los Santos\n\
		San Fierro\n\
		Las Venturas", "OK", "Cancel");
	new Float: X, Float: Y, Float: Z;
	switch(listitem)
	{
		case 0: X = -1990.0402, Y = 136.6163, Z = 27.5391; 		// Train station
		case 1: X = -2004.2463, Y = 293.7323, Z = 34.3055; 		// Car dealership
		case 2: X = -2003.5768, Y = 472.4563, Z = 35.0156; 		// Bank
		case 3: X = 0, Y = 0, Z = 0; 							// Airport
		case 4: X = -2669.4023, Y = 588.1659, Z = 14.4531; 		// Hospital
		case 5: X = -1600.3721, Y = 725.8822, Z = 10.8759; 		// Police departament
		case 6: X = -1742.4924, Y = -91.5269, Z = 3.5547; 		// Docks
	}
	if(GetPlayerState(playerid) == 2) SetVehiclePos(GetPlayerVehicleID(playerid), X, Y, Z);
	else SetPlayerPos(playerid, X, Y, Z);
	SetPlayerInterior(playerid, 0);
	SetPlayerVirtualWorld(playerid, 0);
	return 1;
}

Dialog:LV_Teleports(playerid, response, listitem, inputtext[])
{
	if(!response) return Dialog_Show(playerid, Teleports, DIALOG_STYLE_LIST, "Teleports", "\
		Los Santos\n\
		San Fierro\n\
		Las Venturas", "OK", "Cancel");
	new Float: X, Float: Y, Float: Z;
	switch(listitem)
	{
		case 0: X = 2809.0369, Y = 1280.9080, Z = 10.7500; 		// Train station
		case 1: X = 0, Y = 0, Z = 0; 							// Car dealership
		case 2: X = 2039.6333, Y = 1913.1333, Z = 12.170;     	// Bank
		case 3: X = 2039.8375, Y = 1009.5300, Z = 10.6719; 		// Casino Four Dragons
		case 4: X = 2289.5801, Y = 2418.1296, Z = 11.1030; 		// FBI
		case 5: X = 2127.9524, Y = 2349.3767, Z = 10.6719;    	// Hospital
	}
	if(GetPlayerState(playerid) == 2) SetVehiclePos(GetPlayerVehicleID(playerid), X, Y, Z);
	else SetPlayerPos(playerid, X, Y, Z);
	SetPlayerInterior(playerid, 0);
	SetPlayerVirtualWorld(playerid, 0);
	return 1;
}

Dialog:ADMINCMDS(playerid, response, listitem, inputtext[])
{
    if(!response) return 1;

    new commandsList[1024]="";
    switch(listitem)
    {
        case 0:
        {
            strcat(commandsList, "/adminhelp\n/ah\n/as\n/fly\n/upp\n/dn\n/lt\n/rt\n/frr\n/ba\n/o\n/kick\n/setskin\n/veh\n/delveh\n/delallveh\n/sethp");
            strcat(commandsList, "\n/setarmor\n/setinterior\n/setint\n/setvirtualworld\n/setvw\n/tp\n/teleport\n/gotols");
            Dialog_Show(playerid, ADMINCMDSSELECTED, DIALOG_STYLE_MSGBOX, "Admin 1", commandsList, "Back", "Close");
        }
        case 1:
        {
            Dialog_Show(playerid, ADMINCMDSSELECTED, DIALOG_STYLE_MSGBOX, "Admin 2", "No command for Admin 2+", "Back", "Close");
        }
        case 2:
        {            
        	Dialog_Show(playerid, ADMINCMDSSELECTED, DIALOG_STYLE_MSGBOX, "Admin 3", "No command for Admin 3+", "Back", "Close");
        }
        case 3:
        {
            strcat(commandsList, "/resetmoney\n/givemoney");
            Dialog_Show(playerid, ADMINCMDSSELECTED, DIALOG_STYLE_MSGBOX, "Admin 4", commandsList, "Back", "Close");
        }
        case 4:
        {
            strcat(commandsList, "/makeleader");
            Dialog_Show(playerid, ADMINCMDSSELECTED, DIALOG_STYLE_MSGBOX, "Admin 5", commandsList, "Back", "Close");
        }
        case 5:
        {
            strcat(commandsList, "/setadmin\n/add");
            Dialog_Show(playerid, ADMINCMDSSELECTED, DIALOG_STYLE_MSGBOX, "Admin 6", commandsList, "Back", "Close");
        }
        case 6:
        {
        	strcat(commandsList, "/cp\n/controlpanel\n/debug");
            Dialog_Show(playerid, ADMINCMDSSELECTED, DIALOG_STYLE_MSGBOX, "Admin 7", commandsList, "Back", "Close");
        }
        default:
        {
            Dialog_Show(playerid, ADMINCMDSSELECTED, DIALOG_STYLE_MSGBOX, "Admin 7+", "Same commands as Admin 6", "Back", "Close");
        }
    }
    return 1;
}

Dialog:ADMINCMDSSELECTED(playerid, response, listitem, inputtext[])
{
    if(response) return cmd_adminhelp(playerid, "");
    return 1;
}

Dialog:FACTIONS(playerid, response, listitem, inputtext[])
{
	if(!response) return 1;
    if(response)
    {
        /*if(!strcmp(inputtext,"No Leader",true)) return 1; // or SCM
        new pos = strfind(inputtext," ",true);
        if(pos != -1)
        {
            inputtext[pos] = EOS;
            if(ReturnUser(inputtext) != INVALID_PLAYER_ID && pInfo[ReturnUser(inputtext)][pStatus] == 1) return SendClientMessage(playerid, COLOR_DARKGRAY, "Leader is online, use the commands for online leaders.");
            format(sManage[playerid], MAX_PLAYER_NAME, "%s", inputtext);
            format(stdlg[playerid], 38, "Manage Leader {4D97FF}%s", inputtext);
            ShowPlayerDialog(playerid, DIALOG_MAGLEADER, DIALOG_STYLE_LIST, stdlg[playerid], "Remove From Leader Team", "Select", "Back");
        }
        return 1;*/
    }
    return 1;
}

// Info commands for player
CMD:admins(playerid, params[])
{
	new message[100];
    SendClientMessage(playerid, 0xA4DB00FF, "|______ Admins Online ______|");
    foreach(new i : Player) if(Player[i][Admin] > 0) 
    {
    	format(message, 100, "%s{%s} (%d) - Admin Level %d", pName(i), COLOR_WHITE, i, Player[i][Admin]);
        SendClientMessage(playerid, 0xFF5729FF, message); 
    }

    if(OnlineAdmins == 0) SendClientMessage(playerid, COLOR_GREY, "No admins are online.");
    //format(stmsg[playerid], 34, "* There are %d admins online.", pInfo[playerid][aVar][88]), SendClientMessage(playerid, COLOR_PRODS, stmsg[playerid]);

    SendClientMessage(playerid, 0xA4DB00FF, "|______ Admins Offline ______|");
    GetOfflineAdmins(playerid);
    return 1;
}

// Common helper and admin commands

CMD:gotols(playerid, params[])
{
	new message[255];
	if(Player[playerid][LoggedIn] == false) return 1;
    if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
    if(GetPlayerState(playerid) == 2 ? SetVehiclePos(GetPlayerVehicleID(playerid), 1529.6,-1691.2,13.3) : SetPlayerPos(playerid, 1529.6,-1691.2,13.3))
    SetPlayerInteriorEx(playerid, 0), SetPlayerVirtualWorldEx(playerid, 0);
    format(message, sizeof(message), "AdmCmd: %s has teleported to Los Santos.", pName(playerid));
    SendClientMessage(playerid, COLOR_ORANGE, message);
    return 1;
}

CMD:respawn(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(sscanf(params, "u", params[0])) return SendSyntaxMessage(playerid, -1, "/setadmin [Player's ID/Name]");
	if(!IsPlayerConnected(params[0]) || !Player[params[0]][LoggedIn]) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_ONLINE);

	SpawnPlayer(params[0]);
	SendClientMessage(playerid, COLOR_IMPORTANT_MESSAGE, sprintf("You have respawned %s!", Player[params[0]][Name]));
	SendClientMessage(params[0], COLOR_IMPORTANT_MESSAGE, sprintf("Admin %s has respawned you!", Player[playerid][Name]));
	return 1;
}

// ADMIN 7 COMMANDS

CMD:cp(playerid, params[]) return cmd_controlpanel(playerid, params);
CMD:controlpanel(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(Player[playerid][Admin] < 7) return SendErrorMessage(playerid, COLOR_GREY, "Command available only to LVL 1337 admins!");
	Dialog_Show(playerid, ControlPanel, DIALOG_STYLE_LIST, "Server control panel", "\
		Change server hostname\n\
		Set servers password\n\
		Change servers 'mode'\n\
		Change servers 'language'\n\
		Restart server", "OK", "Cancel");
	return 1;
}

CMD:debug(playerid, params [])
{
	if(Player[playerid][LoggedIn] == false) return 1;
    if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(Player[playerid][Admin] < 7) return SendErrorMessage(playerid, COLOR_GREY, "Command available only to LVL 1337 admins!");
    new st[150];
    format(st, sizeof(st), "ID: %d", Player[playerid][ID]); SendClientMessage(playerid, -1, st);
    format(st, sizeof(st), "OTH: %d", GetVehiclePoolSize()); SendClientMessage(playerid, -1, st);
    format(st, sizeof(st), "RTE: %d", GetServerTickRate()); SendClientMessage(playerid, -1, st);
    mysql_stat(st); 
    SendClientMessage(playerid, -1, st);
    return 1;
}

// ADMIN 6 COMMANDS

CMD:setadmin(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(Player[playerid][Admin] < 6) return SendErrorMessage(playerid, COLOR_GREY, "Command available only to LVL 6 admins!");
	if(sscanf(params, "ud", params[0], params[1])) return SendSyntaxMessage(playerid, -1, "/setadmin [Player's ID/Name] [Admin LVL]");
	if(params[0] == playerid) return SendErrorMessage(playerid, COLOR_GREY, "You cannot set your own admin lvl!");
	if(!IsPlayerConnected(params[0])) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_ONLINE);
	if(Player[params[0]][LoggedIn] == false) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_LOGGED);
	if(params[1] >= Player[playerid][Admin] || params[1] < 0) return SendErrorMessage(playerid, COLOR_GREY, sprintf("Admin LVL from 0 to %d!", Player[playerid][Admin]-1));
	Player[params[0]][Admin] = params[1];
	format(String, 128, "You just set %s admin level to %d.", Player[params[0]][Name], params[1]);
	format(String, 128, "Administrator %s set your admin level to %d.", Player[playerid][Name], params[1]);
	SendClientMessage(params[0], COLOR_ORANGE, String);
	mysql_format(g_SQL, query, 145, "UPDATE `players` SET `Admin` = %d WHERE `ID` = %d LIMIT 1", params[1], params[0]);
	mysql_tquery(g_SQL, query);
	Log(adminlog, INFO, "Administrator %s set %s admin level to %d", Player[playerid][Name], Player[params[0]][Name], params[1]);
	return 1;
}

/*CMD:createhouse(playerid, params[])
{
	if(Player[playerid][Admin] < 6) return SendClientMessage(playerid, COLOR_DARKGRAY, CMD_NOT_AVAILABLE);
	ShowPlayerDialog(playerid, CreateHouseType, DIALOG_STYLE_LIST, "Select house type", "SMALL\nMEDIUM\nBIG", "Select", "Close");
    return 1;
}*/


// ADMIN 5 COMMANDS

CMD:makeleader(playerid, params[])
{
	if(Player[playerid][Admin] < 5) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(sscanf(params, "us[20]", params[0], params[1])) return SendSyntaxMessage(playerid, -1, "/makeleader [Player's ID/Name] [Faction]");
	if(!IsPlayerConnected(params[0]) || Player[params[0]][LoggedIn] == false) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_ONLINE); 

	new factionId = GetFactionIdFromName(params[1]);
	if(factionId == -1) return SendErrorMessage(playerid, COLOR_GREY, "The faction name is invalid!"); 

	new factionsId:factionIdEnum = factionsId:GetFactionEnumFromParam(factionId);
	if(Faction[factionIdEnum][LeaderID] != -1)
	{
		return SendClientMessage(playerid, COLOR_GREY, "There is already a leader for this faction!");
	}

	new targetId, targetName[50];

	targetId = params[0];
	targetName = pName(targetId);

	mysql_format(g_SQL, query, sizeof(query), "UPDATE `factions` SET `LeaderID` = -1 WHERE `ID` = %d ", Player[targetId][FactionID]);
	mysql_query(g_SQL, query);

    Faction[factionsId:GetFactionEnumFromParam(Player[targetId][FactionID])][LeaderID] = -1;

	SetNewFactionForPlayer(targetId, factionId);

	Faction[factionIdEnum][LeaderID] = targetId;

	if(factionId == 0)
    {
        mysql_format(g_SQL, query, sizeof(query), "UPDATE `players` SET `FactionID` = %d WHERE `ID` = %d", factionId, Player[targetId][ID]);
        mysql_query(g_SQL, query);
    }
	else {
        mysql_format(g_SQL, query, sizeof(query), "UPDATE `players`, `factions` SET `players`.`FactionID` = %d, `factions`.`LeaderID` = %d WHERE `players`.`ID` = %d AND `factions`.`ID` = %d ", factionId, Player[targetId][ID], Player[targetId][ID], factionId);
	    mysql_query(g_SQL, query);
    }
	
    switch(factionId)
	{
		case FACTION_PD:
		{
			SendClientMessage(playerid, COLOR_GREY, sprintf("You gave %s leader of PD", targetName));
		}
		case FACTION_FBI:
		{
			SendClientMessage(playerid, COLOR_GREY, sprintf("You gave %s leader of FBI", targetName));
		}
		case FACTION_NG:
		{
			SendClientMessage(playerid, COLOR_GREY, sprintf("You gave %s leader of NG", targetName));
		}
		case FACTION_MEDICS:
		{
			SendClientMessage(playerid, COLOR_GREY, sprintf("You gave %s leader of MEDICS", targetName));
		}
	}

	return 1;
}

// ADMIN 4 COMMANDS

CMD:resetmoney(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(Player[playerid][Admin] < 5) return SendErrorMessage(playerid, COLOR_GREY, "Command available only to LVL 1337 admins!");
	if(sscanf(params, "u", params[0])) return SendSyntaxMessage(playerid, -1, "/resetmoney [Player's ID/Name]");
	if(!IsPlayerConnected(params[0])) return SendErrorMessage(playerid, -1, PLAYER_NOT_ONLINE);
	ResetMoney(params[0]);
	format(String, 128, "You just reseted %s money!", Player[params[0]][Name]);
	SendClientMessage(playerid, COLOR_ORANGE, String);
	format(String, 128, "Administrator %s just reseted your money!", Player[playerid][Name]);
	SendClientMessage(playerid, COLOR_ORANGE, String);
	Log(adminlog, INFO, "Administrator %s reseted %s money", Player[playerid][Name], Player[params[0]][Name]);
	return 1;
}

CMD:givemoney(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(Player[playerid][Admin] < 5) return SendErrorMessage(playerid, COLOR_GREY, "Command available only to LVL 1337 admins!");
	if(sscanf(params, "ui", params[0], params[1])) return SendSyntaxMessage(playerid, -1, "/givemoney [Player's ID/Name] [Amount of money]");
	if(!IsPlayerConnected(params[0])) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_ONLINE);
	if(Player[params[0]][LoggedIn] == false) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_LOGGED);
	if(params[1] < 0 || params[1] > 20000000) return SendErrorMessage(playerid, COLOR_GREY, "Amount of money from 0 to 20'000'000!");
	GiveMoney(params[0], params[1]);
	format(String, 128, "You just gave %s %d dollars!", Player[params[0]], params[1]);
	SendClientMessage(playerid, COLOR_ORANGE, String);
	format(String, 256, "Administrator %s just gave you %d dollars!", Player[playerid][Name], params[1]);
	Log(adminlog, INFO, "Administrator %s just gave %s %d dollars", Player[playerid][Name], Player[params[0]][Name], params[1]);
	return 1;
}


// ADMIN COMMANDS

CMD:adminhelp(playerid, params[])
{
    if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
    new commandsByAdminLevel[255] = "";
    new cmdListFormat[255];
    for(new i = 1; i < Player[playerid][Admin]; i++){
        format(cmdListFormat, 50, "Admin %d\n", i);
        strcat(commandsByAdminLevel, cmdListFormat);
    }
    format(cmdListFormat, 50, "Admin %d", Player[playerid][Admin]);
    strcat(commandsByAdminLevel, cmdListFormat);

    return Dialog_Show(playerid, ADMINCMDS, DIALOG_STYLE_LIST, "Admin Commands List", commandsByAdminLevel, "Select", "Cancel");
}
CMD:ah(playerid, params[]) return cmd_adminhelp(playerid, params);

CMD:as(playerid, params [])
{
    if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
    if(sscanf(params, "s[128]", params[0])) return SendSyntaxMessage(playerid, -1, "/as [admin shout text]");

    new message[128];
    format(message, sizeof(message), "{FC6F76}Admin %s says: {FFFFFF}%s", pName(playerid), params);
    SendAreaMessage(40.0, playerid, message, 0xFFFFFFFF);
    return 1;
}

CMD:fly(playerid, params [])
{
    if(Player[playerid][Admin] > 0 && !IsPlayerInAnyVehicle(playerid)) return ToggleFlying(playerid, !Player[playerid][IsAdminFlying]);
    return 1;
}

CMD:upp(playerid, params[])
{
    if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
    GetPlayerPos(playerid, POSS[0], POSS[1], POSS[2]), SetPlayerPos(playerid, POSS[0], POSS[1], POSS[2]+2);
    return 1;
}

CMD:dn(playerid, params[])
{
    if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
    GetPlayerPos(playerid, POSS[0], POSS[1], POSS[2]), SetPlayerPos(playerid, POSS[0], POSS[1], POSS[2]-2);
    return 1;
}
CMD:lt(playerid, params[])
{
    if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
    GetPlayerPos(playerid, POSS[0], POSS[1], POSS[2]), SetPlayerPos(playerid, POSS[0]-2, POSS[1], POSS[2]);
    return 1;
}
CMD:rt(playerid, params[])
{
    if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
    GetPlayerPos(playerid, POSS[0], POSS[1], POSS[2]), SetPlayerPos(playerid, POSS[0]+2, POSS[1], POSS[2]);
    return 1;
}
CMD:frr(playerid, params[])
{
    if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
    GetPlayerPos(playerid, POSS[0], POSS[1], POSS[2]), SetPlayerPos(playerid, POSS[0], POSS[1]+2, POSS[2]);
    return 1;
}
CMD:ba(playerid, params[])
{
    if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
    GetPlayerPos(playerid, POSS[0], POSS[1], POSS[2]), SetPlayerPos(playerid, POSS[0], POSS[1]-2, POSS[2]);
    return 1;
}

CMD:o(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(isnull(params)) return SendSyntaxMessage(playerid, -1, "/o [Message]");
	format(String, 100, "[A] %s: %s", Player[playerid][Name], params[0]);
	SendClientMessageToAll(-1, String);
	return 1;
}

CMD:kick(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(sscanf(params, "us[32]", params[0], params[1])) return SendSyntaxMessage(playerid, -1, "/kick [Player's ID/Name] [Reason]");
	if(!IsPlayerConnected(params[0])) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_ONLINE);
	format(String, 128, "Administrator %s kicked %s out of server with reason: %s", Player[playerid][Name], Player[params[0]][Name], params[1]);
	SendClientMessageToAll(COLOR_LIGHTRED, String);
	SendClientMessage(playerid, COLOR_ORANGE, "Please, obey the server rules!");
	SendClientMessage(playerid, COLOR_ORANGE, "After a few kicks you can receive a ban!");
	Kick(params[1]);
	Log(adminlog, INFO, "Administrator %s kicked %s with reason: %s", Player[playerid][Name], Player[params[0]][Name], params[1]);
	return 1;
}

CMD:setskin(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(sscanf(params, "ui", params[0], params[1])) return SendSyntaxMessage(playerid, -1, "/setskin [Player's ID/Name] [Reason]");
	if(!IsPlayerConnected(params[0])) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_ONLINE);
	if(Player[params[0]][LoggedIn] == false) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_LOGGED);
	if(params[1] < 0 || params[1] > 311) return SendErrorMessage(playerid, COLOR_GREY, "Skin ID from 0 to 311!");
	SetPlayerSkin(params[0], params[1]);
	format(String, 100, "You just set %s skin to ID %d", Player[params[0]][Name], params[1]);
	SendClientMessage(playerid, COLOR_ORANGE, String);
	format(String, 100, "Administrator %s set your skin to ID %d", Player[playerid][Name], params[1]);
	SendClientMessage(params[0], COLOR_ORANGE, String);
	mysql_format(g_SQL, query, 145, "UPDATE `players` SET `Skin` = %d WHERE `ID` = %d LIMIT 1", params[1]);
	mysql_tquery(g_SQL, query);
	Log(adminlog, INFO, "Administrator %s set %s skin to ID %d", Player[playerid][Name], Player[params[0]][Name], params[1]);
	return 1;
}

CMD:veh(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(GetPlayerInterior(playerid) > 0) return SendErrorMessage(playerid, COLOR_GREY, "You cannot spawn a vehicle in interior!");
	if(sscanf(params, "iii", params[0], params[1], params[2])) return SendSyntaxMessage(playerid, -1, "/veh [Vehicle's ID] [Color 1] [Color 2]");
	if(params[0] < 400 || params[0] > 611) return SendErrorMessage(playerid, COLOR_GREY, "Vehicle's ID from 400 to 611!");
	if(params[1] < 0 || params[1] > 255) return SendErrorMessage(playerid, COLOR_GREY, "Color 1 from 0 to 255!");
	if(params[2] < 0 || params[2] > 255) return SendErrorMessage(playerid, COLOR_GREY, "Color 2 from 0 to 255!");
	new Float: X, Float: Y, Float: Z;
	GetPlayerPos(playerid, X, Y, Z);
	new vehID = CreateVehicle(params[0], X, Y, Z, 0.0, params[1], params[2], -1);
	SetVehicleVirtualWorld(vehID, GetPlayerVirtualWorld(playerid));
	Iter_Add(admin_vehicle, vehID);
	PutPlayerInVehicle(playerid, vehID, 0);
	Log(adminlog, INFO, "Administrator %s spawned vehicle ID %d. (Model: %d)", Player[playerid][Name], vehID, params[0]);
	return 1;
}

CMD:delveh(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(!IsPlayerInAnyVehicle(playerid)) return SendErrorMessage(playerid, COLOR_GREY, NOT_IN_VEHICLE);
	new vehID = GetPlayerVehicleID(playerid);
	new vehModel = GetVehicleModel(vehID);
	if(!Iter_Contains(admin_vehicle, vehID)) return SendErrorMessage(playerid, COLOR_GREY, "This vehicle wasn't spawned by any admin!");
	if(IsValidVehicle(vehID)) DestroyVehicle(vehID);
	Iter_Remove(admin_vehicle, playerid);
	SendClientMessage(playerid, -1, "Vehicle destroyed!");
	Log(adminlog, INFO, "Administrator %s destroyed admin vehicle ID %d. (Model: %d)", Player[playerid][Name], vehID, vehModel);
	return 1;
}

CMD:delallveh(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(Player[playerid][Admin] < 6) return SendErrorMessage(playerid, COLOR_GREY, "Command available only to 6+ lvl administrators.");
	foreach(new i: admin_vehicle)
	{
	    if(IsValidVehicle(i))
	    {
			DestroyVehicle(i);
		}
	}
	Iter_Clear(admin_vehicle);
	Log(adminlog, INFO, "Administrator %s destroyed all admin vehicles", Player[playerid][Name]);
	return 1;
}

CMD:sethp(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(sscanf(params, "ui", params[0], params[1])) return SendSyntaxMessage(playerid, -1, "/sethp [Player's ID/Name] [Amount of HP]");
	if(!IsPlayerConnected(params[0])) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_ONLINE);
	if(Player[params[0]][LoggedIn] == false) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_LOGGED);
	SetHealth(params[0], params[1]);
	format(String, 128, "You just set %s HP to %d.", Player[params[0]], params[1]);
	SendClientMessage(playerid, COLOR_ORANGE, String);
	format(String, 256, "Administrator %s just set your HP to %d.", Player[playerid][Name], params[1]);
	SendClientMessage(params[0], COLOR_ORANGE, String);
	Log(adminlog, INFO, "Administrator %s set %s HP to %d", Player[playerid][Name], Player[params[0]][Name], params[1]);
	

	return 1;
}

CMD:setarmor(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(sscanf(params, "ui", params[0], params[1])) return SendSyntaxMessage(playerid, -1, "/setarmor [Player's ID/Name] [Amount of HP]");
	if(!IsPlayerConnected(params[0])) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_ONLINE);
	if(Player[params[0]][LoggedIn] == false) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_LOGGED);
	SetArmor(params[0], params[1]);
	format(String, 128, "You just set %s armor to %d.", Player[params[0]], params[1]);
	SendClientMessage(playerid, COLOR_ORANGE, String);
	format(String, 256, "Administrator %s just set your armor to %d.", Player[playerid][Name], params[1]);
	SendClientMessage(params[0], COLOR_ORANGE, String);
	Log(adminlog, INFO, "Administrator %s set %s armor to %d", Player[playerid][Name], Player[params[0]][Name], params[1]);
	return 1;
}

CMD:setinterior(playerid, params[]) return cmd_setint(playerid, params);
CMD:setint(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(sscanf(params, "ui", params[0], params[1])) return SendSyntaxMessage(playerid, -1, "/setint [Player's ID/Name] [Interior]");
	if(!IsPlayerConnected(params[0])) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_ONLINE);
	if(Player[params[0]][LoggedIn] == false) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_LOGGED);
	if(params[1] < 0 || params[1] > 50) return SendErrorMessage(playerid, COLOR_GREY, "Interior from 0 to 50!");
	SetPlayerInterior(params[0], params[1]);
	format(String, 128, "You set %s interior to %d.", Player[params[0]][Name], params[1]);
	SendClientMessage(playerid, COLOR_ORANGE, String);
	format(String, 128, "Administrator %s just set your interior to %d.", Player[playerid][Name], params[1]);
	SendClientMessage(params[0], COLOR_ORANGE, String);
	Log(adminlog, INFO, "Administrator %s set %s interior to %d", Player[playerid][Name], Player[params[0]][Name], params[1]);
	return 1;
}

CMD:setvirtualworld(playerid, params[]) return cmd_setvw(playerid, params);
CMD:setvw(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	if(sscanf(params, "ui", params[0], params[1])) return SendSyntaxMessage(playerid, -1, "/setvw [Player's ID/Name] [Virtual World]");
	if(!IsPlayerConnected(params[0])) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_ONLINE);
	if(Player[params[0]][LoggedIn] == false) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_LOGGED);
	if(params[1] < 0 || params[1] > 50) return SendErrorMessage(playerid, COLOR_GREY, "Virtual World from 0 to 50!");
	SetPlayerVirtualWorld(params[0], params[1]);
	format(String, 128, "You set %s interior to %d.", Player[params[0]][Name], params[1]);
	SendClientMessage(playerid, COLOR_ORANGE, String);
	format(String, 128, "Administrator %s just set your interior to %d.", Player[playerid][Name], params[1]);
	SendClientMessage(params[0], COLOR_ORANGE, String);
	Log(adminlog, INFO, "Administrator %s set %s interior to %d", Player[playerid][Name], Player[params[0]][Name], params[1]);
	return 1;
}

CMD:tp(playerid, params[]) return cmd_teleport(playerid, params);
CMD:teleport(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(Player[playerid][Admin] <= 0) return SendErrorMessage(playerid, COLOR_GREY, CMD_NOT_AVAILABLE);
	Dialog_Show(playerid, Teleports, DIALOG_STYLE_LIST, "Teleports", "\
		Los Santos\n\
		San Fierro\n\
		Las Venturas", "OK", "Cancel");
	return 1;
}

// PLAYER COMMANDS

CMD:b(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(sscanf(params, "s[128]", params[0])) return SendSyntaxMessage(playerid, -1, "/b [Message]");
	format(String, 128, "(( [OOC] %s: %s ))", Player[playerid][Name], params[0]);
	SendLocalMessage(30.0, playerid, COLOR_GREY, String);
	return 1;
}

CMD:me(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(isnull(params)) return SendSyntaxMessage(playerid, -1, "/me [Action]");
	format(String, 128, "* %s %s", Player[playerid][Name], params[0]);
	SendLocalMessage(30.0, playerid, COLOR_PURPLE, String);
	return 1;
}

CMD:do(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(isnull(params)) return SendSyntaxMessage(playerid, -1, "/do [Action]");
	format(String, 128, "* %s (%s)", params[0], Player[playerid][Name]);
	SendLocalMessage(30.0, playerid, COLOR_PURPLE, String);
	return 1;
}

CMD:s(playerid, params[]) return cmd_shout(playerid, params);
CMD:shout(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(isnull(params)) return SendSyntaxMessage(playerid, -1, "/(s)hout [Message]");
	format(String, 128, "%s shouts: %s", Player[playerid][Name], params[0]);
	SendLocalMessage(60.0, playerid, -1, String);
	return 1;
}

CMD:pm(playerid, params[])
{
	if(Player[playerid][LoggedIn] == false) return 1;
	if(sscanf(params, "us[64]", params[0], params[1])) return SendSyntaxMessage(playerid, -1, "/pm [Player's ID/Name] [Message]");
	//if(params[0] == playerid) return SendErrorMessage(playerid, COLOR_GREY, "You cannot send a personal message to yourself!");
	if(!IsPlayerConnected(params[0])) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_ONLINE);
	if(Player[params[0]][LoggedIn] == false) return SendErrorMessage(playerid, COLOR_GREY, PLAYER_NOT_LOGGED);
	format(String, 128, "[PM] To {FF6347}%s {FFFFFF}({FF6347}%d{FFFFFF}): %s", Player[params[0]][Name], params[0], params[1]);
	SendClientMessage(playerid, -1, String);
	format(String, 128, "[PM] From {FF6347}%s {FFFFFF}({FF6347}%d{FFFFFF}): %s", Player[playerid][Name], playerid, params[1]);
	SendClientMessage(params[0], -1, String);
	return 1;
}

CMD:factions(playerid, params [])
{
    new tmp[120];
    new message[1024];
	format(tmp, sizeof(tmp), "Faction\tLeader\tStatus\tReq. Level\n"), strcat(message, tmp);
	for(new i; factionsId:i < factionsId; i++)
	{
		if(Faction[factionsId:i][Level] > 1)
		{
		    format(tmp, sizeof(tmp), "{%s}%s\t%s\t%d\n", Faction[factionsId:i][Color], Faction[factionsId:i][Name], GetFactionLeader(factionsId:i), Faction[factionsId:i][Level]);
		    strcat(message, tmp);
	 	}
	}
    Dialog_Show(playerid, FACTIONS, DIALOG_STYLE_TABLIST_HEADERS, "Factions", message, "Select", "Close");
    return 1;
}