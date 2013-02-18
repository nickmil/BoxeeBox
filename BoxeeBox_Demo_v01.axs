PROGRAM_NAME='BoxeeBox_Demo_v01'

//-----------------------------------------------------------------------------

DEFINE_DEVICE		//---IP Devices
	dvBoxeeBox			= 0:3:1

DEFINE_DEVICE		//---Touch Panel Devices
	dvTP_BoxeeBox		= 10001:1:1
	
DEFINE_DEVICE
	vdvBoxeeBox			= 33001:1:1
	
//-----------------------------------------------------------------------------

DEFINE_EVENT
	DATA_EVENT [vdvBoxeeBox] {
		ONLINE : {
			SEND_COMMAND vdvBoxeeBox,"'PROPERTY-IP_Address,192.168.1.106'"
			SEND_COMMAND vdvBoxeeBox,"'PROPERTY-TCP_Port,8800'"
			SEND_COMMAND vdvBoxeeBox,"'PROPERTY-Poll_Time,60'"
			SEND_COMMAND vdvBoxeeBox,"'PROPERTY-Progress_Poll,0'"
			SEND_COMMAND vdvBoxeeBox,"'DEBUG-1'"
		}
	}
	
//-----------------------------------------------------------------------------
	
DEFINE_MODULE 'BoxeeBox_Comm_v01' bbox01(vdvBoxeeBox,dvBoxeeBox)
DEFINE_MODULE 'BoxeeBox_UI_v01' bbox01ui(vdvBoxeeBox,dvTP_BoxeeBox)