# AMX Control Module - Boxee Box & Pre-Eden XBMC

This module uses an HTTP RESTful API to control Boxee Box set top boxes
Further documentation will be provided in the future.  It will work with Boxee Box, as well as Pre-Eden releases of XBMC.
With the release of Eden, XBMC has moved to a JSON API.

This module is provided free of charge with no warranty or guarantee of functionality.
Please refer to the Demo AMX workspace for guidance on implementation.

| COMM Module SEND_COMMANDS        |
|----------------------|
| PLAY | Play/Pause current media |
| PAUSE | Same as Play Above |
| PLAYPAUSE | Same as PLAY & PAUSE |
| STOP | Stops current media playback |
| MUTE | Mutes volume out of Boxee Box (Toggle) |
| NEXT | Skips to the next media in playlist |
| PREVIOUS | Returns to beginning, or jumps back |
| MENU | Simulates Menu button on the remote |
| MENU-UP | DPad Up |
| MENU-DOWN | DPad Down |
| MENU-LEFT | DPad Left |
| MENU-RIGHT | DPad Right |
| MENU-OK | DPad Center Button |
| MENU-SELECT | Same as MENU-OK |
| MENU-ENTER | Same as MENU-OK |
| MENU-EXIT | Exit Button |
| KEYBOARD-DELETE | Keyboard Backspace |
| KEYBOARD-SPACE | Space Bar |
| KEYBOARD-* | * = ASCII Representation of desired key |
| ?VOLUME | Queries current volume |
| VOLUME-UP | 1% Relative volume adjustment |
| VOLUME-DOWN | 1% Relative volume adjustment |
| VOLUME-* | * = Integer representation of absolute volume percentage |
| ?PROGRESS | Queries progress percentage of current media |
| JUMP_TO_PCT-* | * = Integer representation of desired location |
| SEEK_PCT-* | * = Relative jump in current media (percentage) |
| ?NOW_PLAYING | Future |

| Instantiation & Debug SEND_COMMANDS |
|------|
| DEBUG-* | * = Desired debug level (see code comments) |
| PROPERTY-IP_Address,* | IP Address of the Boxee Box |
| PROPERTY-TCP_Port,* | Boxee Box TCP comm port. (Default: 8800) |
| PROPERTY-Poll_Time,* | * = Seconds between poll queries (currently volume only) |
| PROPERTY-Progress_Poll,* | * = 1 or 0 to enable/disable progress polling every second |
| CLEARQUE | Clears command que waiting to be sent to Boxee |
| CLEARBUF | Clears buffer of acks returned from Boxee |
| REINIT | Clears buffers and reinitializes the module |

| UI Button Channels |
|------|
| 1 | Play |
| 2 | Stop |
| 3 | Pause |
| 5 | Next Track |
| 6 | Previous Track |
| 7 | Scan Forward (1%) |
| 8 | Scan Reverse (1%) |
| 24 | Volume Up |
| 25 | Volume Down |
| 26 | Volume Mute Toggle |
| 45 | DPad Up |
| 46 | DPad Down |
| 47 | DPad Left |
| 48 | DPad Right |
| 49 | DPad Center Button |
| 50 | Menu |
| 100 | Shift/Caps Lock |
| 101 - 146 | Keyboard Keys |
| 150 | Space Bar |
| 151 | Delete |

