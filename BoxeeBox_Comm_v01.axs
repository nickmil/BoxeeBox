MODULE_NAME='BoxeeBox_Comm_v01' (DEV vdvDev,DEV dvDev)

DEFINE_TYPE
	STRUCTURE _Debug {
		INTEGER nDebugLevel
	}
	STRUCTURE _Comm {
		CHAR cIPAddress[15]
		INTEGER nTCPPort
		INTEGER nCommTimeout
		
		CHAR cQue[2048]
		CHAR cBuf[2048]
		CHAR cLastGet[512]
		INTEGER nBusy
		
		LONG lPollTime
	}
	STRUCTURE _BBox {
		_Comm Comm
		_Debug Debug
		
		INTEGER nVolumePct
		INTEGER nProgressPct
		INTEGER nProgressPoll
	}
	
	
DEFINE_VARIABLE
	VOLATILE _BBox BBox
	
DEFINE_VARIABLE	
	CONSTANT tlPolling = 1
	CONSTANT MaxPollCmds = 1
	VOLATILE LONG lTimes[] = { 500,60000 }
	VOLATILE CHAR cPollCmds[2][32] = { '?VOLUME' }

//-----------------------------------------------------------------------------

DEFINE_FUNCTION DebugString(INTEGER nLevel,CHAR cString[]) {
	IF(nLevel<=BBox.Debug.nDebugLevel) {
		SEND_STRING 0,"'BoxeeBox - ',cString"
	}
}
DEFINE_FUNCTION SendQue() {
	LOCAL_VAR CHAR cCmd[64]
	IF(!BBox.Comm.nBusy && FIND_STRING(BBox.Comm.cQue,"$0B,$0B",1)) {
		ON[BBox.Comm.nBusy]
		CALL 'OpenSocket'
	}
}
DEFINE_FUNCTION AddHTTPGet(CHAR cShortURI[]) {
	STACK_VAR CHAR cURLString[512]
	STACK_VAR CHAR cHeader[512]
	
	cURLString = "'/',cShortURI"
	DebugString(4,"'Add to Que: HTTP://',BBox.Comm.cIPAddress,cURLString")
	
	cHeader = "'GET ',cURLString,' HTTP/1.1',$0D,$0A"
	cHeader = "cHeader,'Host: ',BBox.Comm.cIPAddress,$0D,$0A"
	cHeader = "cHeader,'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64,rv:13.0) Gecko/20100101 Firefox/13.0.1',$0D,$0A"
	cHeader = "cHeader,'Accept: text/html,application/xhtml+xml,application/xml;q=0.9*/*;q=0.8',$0D,$0A"
	cHeader = "cHeader,'Accept-Language: en-us;q=0.5',$0D,$0A"
	cHeader = "cHeader,'Accept-Encoding: gzip,deflate',$0D,$0A"
	cHeader = "cHeader,'Connection: keep-alive',$0D,$0A,$0D,$0A"
	
	BBox.Comm.cQue = "BBox.Comm.cQue,cHeader,$0B,$0B"
	DebugString(3,"'AddHTTPGet : ',cShortURI")
}
DEFINE_FUNCTION AddToQue(CHAR cCmd[]) {
	BBox.Comm.cQue = "BBox.Comm.cQue,cCmd,$0B,$0B"
} 
DEFINE_CALL 'OpenSocket' {
	STACK_VAR SINTEGER nError 
	STACK_VAR CHAR cError[32]
	
	nError = IP_CLIENT_OPEN(dvDev.PORT,BBox.Comm.cIPAddress,BBox.Comm.nTCPPort,IP_TCP)
	
	SWITCH(nError) {
		CASE 0	: cError='None'
		CASE 2  : cERROR='General Failure'
		CASE 4  : cERROR='Unknown Host'
		CASE 6  : cERROR='Connection Refused'
		CASE 7  : cERROR='Connection Timed Out'
		CASE 8  : cERROR='Unknown Connection Error'
		CASE 14 : cERROR='Local Port Already in Use'
		CASE 16 : cERROR='Too Many Open Sockets'
		CASE 17 : cERROR='Local Port Not Open'
		DEFAULT : cERROR=ITOA(nERROR)
	}
	IF(nError) {
		SEND_STRING vdvDev,"'ERROR-Socket Connection Error: ',cError"
		DebugString(1,"'ERROR-Socket Connection Error: ',cError")
	}
	ELSE {
		DebugString(2,"'OpenSocket - Socket opened successfully'")
	}
}

//-----------------------------------------------------------------------------Parsing Routines

DEFINE_FUNCTION DevRx(CHAR cBuf[]) {
	LOCAL_VAR CHAR cHTTPResponseCode[8]
	LOCAL_VAR LONG nHTMLStart
	LOCAL_VAR LONG nHTMLEnd
	LOCAL_VAR CHAR cHTML[2048]
	LOCAL_VAR CHAR cAck[128]
	
	DebugString(4,"'Parsing : ',cBuf")
	
	
	REMOVE_STRING(cBuf,"$0D,$0A,$0D,$0A,'b',$0D,$0A",1)
	SET_LENGTH_STRING(cBuf,LENGTH_STRING(cBuf)-7)
	DebugString(4,"'Parse-able data : ',cBuf")
	
	REMOVE_STRING(cBuf,"'HTTP/1.0 '",1)
	cHTTPResponseCode = REMOVE_STRING(cBuf,"$0D,$0A",1)
	SELECT {
		ACTIVE (FIND_STRING(cHTTPResponseCode,'401',1)) : DebugString(1,'ERROR - HTTP Response Code: 401, Unauthorized')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'402',1)) : DebugString(1,'ERROR - HTTP Response Code: 402, Payment Required')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'403',1)) : DebugString(1,'ERROR - HTTP Response Code: 403, Forbidden')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'404',1)) : DebugString(1,'ERROR - HTTP Response Code: 404, Not Found')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'405',1)) : DebugString(1,'ERROR - HTTP Response Code: 405, Method Not Allowed')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'406',1)) : DebugString(1,'ERROR - HTTP Response Code: 406, Not Acceptible')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'407',1)) : DebugString(1,'ERROR - HTTP Response Code: 407, Proxy Auth Required')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'408',1)) : DebugString(1,'ERROR - HTTP Response Code: 408, Request Timeout')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'409',1)) : DebugString(1,'ERROR - HTTP Response Code: 409, Conflict')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'410',1)) : DebugString(1,'ERROR - HTTP Response Code: 410, Gone')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'411',1)) : DebugString(1,'ERROR - HTTP Response Code: 411, Length Required')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'412',1)) : DebugString(1,'ERROR - HTTP Response Code: 412, Precondition Failed')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'413',1)) : DebugString(1,'ERROR - HTTP Response Code: 413, Request Entity Too Large')
		ACTIVE (FIND_STRING(cHTTPResponseCode,'414',1)) : DebugString(1,'ERROR - HTTP Response Code: 414, Request URI Too Long')
		
		ACTIVE (FIND_STRING(cHTTPResponseCode,'200 OK',1)) : {
			DebugString(4,'HTTP Response Code: 200, OK!')
			
			nHTMLStart = FIND_STRING(cBuf,'<html>',1)
			nHTMLEnd = FIND_STRING(cBuf,'</html>',1)
			cHTML = MID_STRING(cBuf,nHTMLStart,(nHTMLEnd-nHTMLStart))
			DebugString(4,"'HTML Content - ',cHTML")
			
			REMOVE_STRING(cBuf,'<li>',1)
			cAck = REMOVE_STRING(cBuf,'<',1)
			SET_LENGTH_STRING(cAck,LENGTH_STRING(cAck)-1)
			DebugString(4,"'Parsed Ack: ',cAck")
			
			SELECT {
				ACTIVE (FIND_STRING(BBox.Comm.cLastGet,'GetVolume',1)) : {
					DebugString(4,"'Volume: ',cAck")
					BBox.nVolumePct = ATOI(cAck)
					SEND_LEVEL vdvDev,1,BBox.nVolumePct
					SEND_STRING vdvDev,"'VOLUME-',ITOA(BBox.nVolumePct)"
				}
				ACTIVE (FIND_STRING(BBox.Comm.cLastGet,'SetVolume',1)) : {
					SEND_COMMAND vdvDev,"'?VOLUME'"
				}
				ACTIVE (FIND_STRING(BBox.Comm.cLastGet,'GetPercent',1)) : {
					DebugString(4,"'Progress: ',cAck")
					BBox.nProgressPct = ATOI(cAck)
					SEND_LEVEL vdvDev,2,BBox.nProgressPct
				}
				ACTIVE (FIND_STRING(cAck,'OK',1)) : DebugString(4,"'OK: Last Tx: ',BBox.Comm.cLastGet")
				ACTIVE (FIND_STRING(cAck,'Error',1)) : DebugString(1,"'ERROR: Last Tx: ',BBox.Comm.cLastGet")
			}
		}
	}
}

//-----------------------------------------------------------------------------

DEFINE_EVENT
	DATA_EVENT [vdvDev] {
		ONLINE : {
			SEND_COMMAND vdvDev,"'PROPERTY-Poll_Time,60'"
		}
		COMMAND : {
			STACK_VAR CHAR cCmd[16]
			STACK_VAR INTEGER nPara
			STACK_VAR CHAR cPara[8][128]
			
			IF(FIND_STRING(DATA.TEXT,'-',1)) {
				cCmd = REMOVE_STRING(DATA.TEXT,'-',1)
				SET_LENGTH_STRING(cCmd,LENGTH_STRING(cCmd)-1)
				
				nPara=1
				WHILE(FIND_STRING(DATA.TEXT,',',1)) {
					cPara[nPara] = REMOVE_STRING(DATA.TEXT,',',1)
					SET_LENGTH_STRING(cPara[nPara],LENGTH_STRING(cPara[nPara])-1)
					nPara++
				}
				cPara[nPara] = DATA.TEXT
			}
			ELSE {
				cCmd = DATA.TEXT
			}
			
			SELECT {
				
				(*********************************************************************)
				
				ACTIVE (CCmd=='PLAY') : AddHTTPGet('xbmcCmds/xbmcHttp?command=Pause')
				ACTIVE (CCmd=='PAUSE') : AddHTTPGet('xbmcCmds/xbmcHttp?command=Pause')
				ACTIVE (CCmd=='PLAYPAUSE') : AddHTTPGet('xbmcCmds/xbmcHttp?command=Pause')
				ACTIVE (cCmd=='MUTE') : AddHTTPGet('xbmcCmds/xbmcHttp?command=Mute')
				ACTIVE (cCmd=='STOP') : AddHTTPGet('xbmcCmds/xbmcHttp?command=Stop')
				ACTIVE (cCmd=='NEXT') : AddHTTPGet('xbmcCmds/xbmcHttp?command=PlayNext')
				ACTIVE (cCmd=='PREVIOUS') : AddHTTPGet('xbmcCmds/xbmcHttp?command=PlayPrev')
				
				ACTIVE ((cCmd=='MENU') && (cPara[1]=='UP')) : AddHTTPGet('xbmcCmds/xbmcHttp?command=SendKey(270)')
				ACTIVE ((cCmd=='MENU') && (cPara[1]=='DOWN')) : AddHTTPGet('xbmcCmds/xbmcHttp?command=SendKey(271)')
				ACTIVE ((cCmd=='MENU') && (cPara[1]=='LEFT')) : AddHTTPGet('xbmcCmds/xbmcHttp?command=SendKey(272)')
				ACTIVE ((cCmd=='MENU') && (cPara[1]=='RIGHT')) : AddHTTPGet('xbmcCmds/xbmcHttp?command=SendKey(273)')
				ACTIVE ((cCmd=='MENU') && (cPara[1]=='OK')) : AddHTTPGet('xbmcCmds/xbmcHttp?command=SendKey(256)')
				ACTIVE ((cCmd=='MENU') && (cPara[1]=='ENTER')) : AddHTTPGet('xbmcCmds/xbmcHttp?command=SendKey(256)')
				ACTIVE ((cCmd=='MENU') && (cPara[1]=='EXIT')) : AddHTTPGet('xbmcCmds/xbmcHttp?command=SendKey(275)')
				ACTIVE (cCmd=='MENU') : AddHTTPGet('xbmcCmds/xbmcHttp?command=SendKey(257)')
				
				ACTIVE ((cCmd=='KEYBOARD') && (cPara[1]=='DELETE')) : AddHTTPGet('xbmcCmds/xbmcHttp?command=SendKey(61704)')
				ACTIVE ((cCmd=='KEYBOARD') && (cPara[1]=='SPACE')) : AddHTTPGet('xbmcCmds/xbmcHttp?command=SendKey(61728)')
				ACTIVE (cCmd=='KEYBOARD') : {
					AddHTTPGet("'xbmcCmds/xbmcHttp?command=SendKey(',ITOA(61696 +GET_BUFFER_CHAR(cPara[1])),')'")
				}
				
				ACTIVE (cCmd=='?VOLUME') : AddHTTPGet("'xbmcCmds/xbmcHttp?command=GetVolume'")
				ACTIVE ((cCmd=='VOLUME') && (cPara[1]=='UP')) : AddHTTPGet("'xbmcCmds/xbmcHttp?command=SetVolume(',ITOA(BBox.nVolumePct+1),')'")
				ACTIVE ((cCmd=='VOLUME') && (cPara[1]=='DOWN')) : AddHTTPGet("'xbmcCmds/xbmcHttp?command=SetVolume(',ITOA(BBox.nVolumePct-1),')'")
				ACTIVE (cCmd=='VOLUME') : AddHTTPGet("'xbmcCmds/xbmcHttp?command=SetVolume(',cPara[1],')'")
				
				ACTIVE (cCmd=='?PROGRESS') : AddHTTPGet("'xbmcCmds/xbmcHttp?command=GetPercentage'")
				
				ACTIVE (cCmd=='JUMP_TO_PCT') : AddHTTPGet("'xbmcCmds/xbmcHttp?command=SeekPercentage(',cPara[1],')'")
				ACTIVE (cCmd=='SEEK_PCT') : AddHTTPGet("'xbmcCmds/xbmcHttp?command=SeekPercentageRelative(',cPara[1],')'")
				
				(*********************************************************************)
				
				
				ACTIVE (cCmd=='PASSTHRU_GET') : {
					AddHTTPGet(cPara[1])
				}
				
				ACTIVE (cCmd=='DEBUG') : {
					BBox.Debug.nDebugLevel = ATOI(cPara[1])
					SEND_STRING vdvDev,"'DEBUG-',cPara[1]"
					DebugString(0,"'DEBUG Level = ',cPara[1]")
				}
				ACTIVE ((cCmd=='PROPERTY') && (cPara[1]=='IP_Address')) : {
					BBox.Comm.cIPAddress = cPara[2]
					SEND_STRING vdvDev,"'PROPERTY-IP_Address,',cPara[2]"
					DebugString(3,"'IP Address: ',cPara[2]")
				}
				ACTIVE ((cCmd=='PROPERTY') && (cPara[1]=='TCP_Port')) : {
					BBox.Comm.nTCPPort = ATOI(cPara[2])
					SEND_STRING vdvDev,"'PROPERTY-TCP_Port,',cPara[2]"
					DebugString(3,"'TCP Port : ',cPara[2]")
				}
				ACTIVE ((cCmd=='PROPERTY') && (cPara[1]=='Poll_Time')) : {
					BBox.Comm.lPollTime = ATOI(cPara[2])*1000
					lTimes[MaxPollCmds+1] = BBox.Comm.lPollTime
					SEND_STRING vdvDev,"'PROPERTY-Poll_Time,',ITOA(BBox.Comm.lPollTime)"
					
					IF(TIMELINE_ACTIVE(tlPolling))
						TIMELINE_KILL(tlPolling)
					
					IF(BBox.Comm.lPollTime > 0)
						TIMELINE_CREATE(tlPolling,lTimes,MaxPollCmds+1,TIMELINE_RELATIVE,TIMELINE_REPEAT)
				}
				ACTIVE ((cCmd=='PROPERTY') && (cPara[1]=='Progress_Poll')) : {
					BBox.nProgressPoll = ATOI(cPara[2])
					SEND_STRING vdvDev,"'PROPERTY-Progress_Poll,',ITOA(BBox.nProgressPoll)"
				}
				
				ACTIVE (cCmd=='CLEARQUE') : {
					BBox.Comm.cQue = ''
				}
				ACTIVE (cCmd=='CLEARBUF') : {
					BBox.Comm.cBuf = ''
					OFF[BBox.Comm.nBusy]
				}
				ACTIVE (cCmd=='REINIT') : {
					BBox.Comm.cQue = ''
					BBox.Comm.cBuf = ''
					ON[BBox.Comm.nBusy]
					IP_CLIENT_CLOSE(dvDev.PORT)
					WAIT 10
						OFF[BBox.Comm.nBusy]
				}
				
				ACTIVE (1) : DebugString(1,"'ERROR - Unhandled Command'")
			}
		}
	}
	DATA_EVENT [dvDev] {
		ONLINE : {
			STACK_VAR CHAR cPayload[512]
			STACK_VAR INTEGER nLastCmdStart
			STACK_VAR INTEGER nLastCmdEnd
			
			cPayload = REMOVE_STRING(BBox.Comm.cQue,"$0B,$0B",1)
			SEND_STRING dvDev,"cPayload"
			
			nLastCmdStart = FIND_STRING(cPayload,"'/xbmc'",1)
			nLastCmdEnd = FIND_STRING(cPayload,"' HTTP/1.'",1)
			BBox.Comm.cLastGet = MID_STRING(cPayload,nLastCmdStart,(nLastCmdEnd-nLastCmdStart))
			
			WAIT BBox.Comm.nCommTimeout 'CommTimeout' {
				BBox.Comm.cBuf = ''
				BBox.Comm.cQue = ''
				BBox.Comm.nBusy = 0
				SEND_STRING vdvDev,"'ERROR-Comm Timeout'"
				DebugString(1,"'ERROR-Comm Timed Out'")
			}
		}
		OFFLINE : {
			OFF[BBox.Comm.nBusy]
			IF(LENGTH_STRING(BBox.Comm.cBuf)) {
				DebugString(3,"'Sending to Parse : ',BBox.Comm.cBuf")
				DevRx(BBox.Comm.cBuf)
				BBox.Comm.cBuf = ''
			}
		}
		STRING : {
			CANCEL_WAIT 'CommTimeout'
			DebugString(4,"'Rx from BoxeeBox: ',DATA.TEXT")
			IF(RIGHT_STRING(BBox.Comm.cBuf,7)=="$0D,$0A,'0',$0D,$0A,$0D,$0A")
				IP_CLIENT_CLOSE(dvDev.PORT)
		}
	}
	
	
DEFINE_EVENT
	TIMELINE_EVENT [tlPolling] {
		IF(TIMELINE.SEQUENCE<=MaxPollCmds)
			SEND_COMMAND vdvDev,"cPollCmds[TIMELINE.SEQUENCE]"
	}
	
//-----------------------------------------------------------------------------

DEFINE_START
	CREATE_BUFFER dvDev,BBox.Comm.cBuf
	BBox.Comm.nTCPPort = 8800
	BBox.Comm.nCommTimeout = 50
	BBox.nProgressPoll = 0


//-----------------------------------------------------------------------------

DEFINE_PROGRAM
	[vdvDev,254] = BBox.Comm.nBusy
	SendQue()
	
	WAIT 10
		IF(BBox.nProgressPoll)
			SEND_COMMAND vdvDev,"'?PROGRESS'"