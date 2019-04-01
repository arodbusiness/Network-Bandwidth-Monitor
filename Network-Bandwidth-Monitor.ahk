#SingleInstance force
#NoEnv
#Include Gdip.ahk
#Include XNET.ahk
;#NoTrayIcon
;SetBatchLines, -1
DetectHiddenWindows Off
CoordMode, Mouse, Screen
SetFormat, IntegerFast, d
iconSet := 18 

Menu, Tray, Icon, shell32.dll,47 ; 47 ; ; 95 ;22 ;123
Menu, Tray, NoStandard
Menu, Tray, Add, Reload , Reload
Menu, Tray, Add, Exit , Exit 
Menu, Tray, Default, Exit ; double click tray icon to exit

If !pToken := Gdip_Startup()
{
	MsgBox, No Gdiplus 
	ExitApp
}

if !FileExist("BandwidthSettings.ini")
{
	file := FileOpen("BandwidthSettings.ini", "w")
	file.Write("[Main]`r`nMaxDownMB=10`r`nMaxUpMB=1`r`nX=0`r`nY=0`r`nW=400`r`nH=100`r`nBarHeight=16`r`nColorDown=00AC00`r`nColorUp=AC0000`r`nuseSearchSpace=1`r`nCustomX=0`r`nCustomY=0`r`nCustomW=0`r`nCustomH=0`r`nRefreshTime=1500")
	file.close
}

IniRead, max_down_mb, BandwidthSettings.ini, Main, MaxDownMB
IniRead, max_up_mb, BandwidthSettings.ini, Main, MaxUpMB
IniRead, pos_x, BandwidthSettings.ini, Main, X
IniRead, pos_y, BandwidthSettings.ini, Main, Y
IniRead, pos_w, BandwidthSettings.ini, Main, W
IniRead, pos_h, BandwidthSettings.ini, Main, H
IniRead, arrow_w, BandwidthSettings.ini, Main, BarHeight
IniRead, useSearchSpace, BandwidthSettings.ini, Main, useSearchSpace
IniRead, CustomX, BandwidthSettings.ini, Main, CustomX
IniRead, CustomY, BandwidthSettings.ini, Main, CustomY
IniRead, CustomW, BandwidthSettings.ini, Main, CustomW
IniRead, CustomH, BandwidthSettings.ini, Main, CustomH
IniRead, RefreshTime, BandwidthSettings.ini, Main, RefreshTime
IniRead, AdapterIndices, BandwidthSettings.ini, Main, AdapterIndices




Adapters := StrSplit(AdapterIndices, ",")
Trans := FHex(0xFF/Adapters.MaxIndex())
RefreshTimeDisp := round(RefreshTime/1000,1)
global MoveNow:=0

max_up:=max_up_mb*1000*1000, max_down:=max_down_mb*1000*1000

Gui, +ToolWindow -border +HwndGuiHwnd +AlwaysOnTop 
Gui,Color, 120F00
Gui, -DPIScale

grid_w:=(pos_w)/2

	
grid_down_x:=2
grid_down_y:=2

grid_up_x:=pos_w-grid_w+4
grid_up_y:=grid_down_y

global Bar_w:=grid_w-arrow_w
Bar_h:=arrow_w
	
global grid_h:=pos_h-(arrow_w+2)*Adapters.MaxIndex()	

Gui, Add, Picture, x%grid_down_x% y%grid_down_y% w%grid_w% h%grid_h% vGrid_img_dn 0xE, 
Gui, Add, Picture, x%grid_up_x% y%grid_up_y% w%grid_w% h%grid_h% vGrid_img_up 0xE,


ArraysDown := Object()
ArraysUp := Object()
DownColors := Object()
UpColors := Object()

Loop % Adapters.MaxIndex() {
	array_down%A_Index% := Object()
	array_up%A_Index% := Object()
	
	gridLoops:=grid_w-2
	i:=A_Index
	Loop % gridLoops 
		array_down%i%[A_Index]:=array_up%i%[A_Index]:=grid_h
	
	
	Net%A_Index% := new XNET(False)
	Net%A_Index%.InterfaceIndex := Adapters[A_Index]
	Name%A_Index% := RegexReplace(Net%A_Index%.Description," Ethernet| Connection| Device")

	arrowDown_x:=grid_down_x
	arrowDown_y:=grid_h+5+(arrow_w+3)*(A_Index-1)
	
	arrowUp_x:=pos_w/2+4
	arrowUp_y:=arrowDown_y
	

	Bar_dn_h_x:=arrowDown_x+arrow_w
	Bar_dn_h_y:=arrowDown_y
	
	Bar_up_h_x:=arrowUp_x+arrow_w
	Bar_up_h_y:=Bar_dn_h_y
	


	Gui, Add, Picture, x%arrowUp_x% y%arrowUp_y% w%arrow_w% h%arrow_w% varrowUp%A_Index% BackgroundTrans 0xE, 
	Gui, Add, Picture, x%arrowDown_x% y%arrowDown_y% w%arrow_w% h%arrow_w% varrowDown%A_Index% BackgroundTrans 0xE,

	Gui, 1: Add, Picture, x%Bar_up_h_x% y%Bar_up_h_y% w%Bar_w% h%Bar_h% vBar_up_h%A_Index% 0xE 
	Gui, 1: Add, Picture, x%Bar_dn_h_x% y%Bar_dn_h_y% w%Bar_w% h%Bar_h% vBar_dn_h%A_Index% 0xE 

	if (A_Index=1 || A_Index=4) 
		Color1 := "FF2222", Color2 := "00FFFF"
	else if (A_Index=2 || A_Index=5) 
		Color1 := "00FF00", Color2 := "FFFF00"
	else if (A_Index=3 || A_Index=6) 
		Color1 := "FF0000", Color2 := "FF00FF"
	else 
		Color1 := "FFFFFF", Color2 := "FFFFFF"

	ColorDown%A_Index% := Color1
	ColorUp%A_Index% := Color2
	
	
	DownColors[A_Index] := "0x" Trans Color1
	UpColors[A_Index] := "0x" Trans Color2
	
	
	SplitRGBColor("0x" Color1,R1,G1,B1)
	R2 := floor(R1/8), G2 := floor(G1/8), B2 := floor(B1/8)
	R3 := floor(R1), G3 := floor(G1), B3 := floor(B1)
	grad_col_dn%A_Index%:="0xff" . FHex(R2) . FHex(G2) . FHex(B2) . "|0xff" . FHex(R3) . FHex(G3) . FHex(B3) . "|" .  Bar_h/2

	SplitRGBColor("0x" Color2,R1,G1,B1)
	R2 := floor(R1/8), G2 := floor(G1/8), B2 := floor(B1/8)
	R3 := floor(R1), G3 := floor(G1), B3 := floor(B1)
	grad_col_up%A_Index%:="0xff" . FHex(R2) . FHex(G2) . FHex(B2) . "|0xff" . FHex(R3) . FHex(G3) . FHex(B3) . "|" .  Bar_h/2

	Gdip_draw_arrow(arrowDown%A_Index%,"0xFF" Color1,2)
	Gdip_draw_arrow(arrowUp%A_Index%,"0xFF" Color2,0)

}








OnMessage(0x200, "WM_MOUSEMOVE")
OnMessage(0x201, "WM_LBUTTONDOWN")
OnMessage(0x202, "WM_LBUTTONUP")

Gui, Show, x%pos_x% y%pos_y% w%pos_w% h%pos_h%, Bandwidth_Monitor
ShowingGUI1:=1

WinSet, Style, -0xC00000, Bandwidth_Monitor ; COMPLETELY remove window border

Settimer, get_up_down_data, %RefreshTime%
Settimer, CheckOverWindow, 100
return

;========================================


WinSearchMode:
	MoveNow:=0
	WinGetPos, AX, AY, AW, AH, ahk_class Shell_TrayWnd
	pos_x:=AX+47
	pos_y:=AY
	pos_w := AW>=1920 ? 360 : 340
	pos_h:=46
	WinMove, Bandwidth_Monitor, ,pos_x, pos_y, pos_w, pos_h
return

MoveWindow:
	GuiControlGet, InputX , 2:, InputX
	GuiControlGet, InputY , 2:, InputY
	GuiControlGet, InputW , 2:, InputW
	GuiControlGet, InputH , 2:, InputH
	WinMove, Bandwidth_Monitor, ,InputX, InputY, InputW, InputH
return

MoveMode:
	MoveNow:=1
return
;========================================
WM_LBUTTONDOWN(){
	if (A_Gui=1 && MoveNow=1){
		PostMessage, 0xA1, 2,,,Bandwidth_Monitor ; movable borderless window 
	}
}

WM_MOUSEMOVE(){
	if (MoveNow=1){
		WinGetPos, WX, WY, WW, WH, Bandwidth_Monitor
		GuiControl, 2:,InputX,%WX%
		GuiControl, 2:,InputY,%WY%
	}
}

CheckOverWindow:
	if (MoveNow=0)
	{
		MouseGetPos, MouseX, MouseY
		;Tooltip, Mouse`nX:%MouseX%`nY:%MouseY%`n`nWindow`nX:%pos_x%`nY:%pos_y%
			
		cond1:=MouseX>pos_x
		cond2:=MouseX<pos_x+pos_w
		cond3:=MouseY>pos_y
		cond4:=MouseY<pos_y+pos_h
		cond5:=WinExist("Bandwidth_Monitor")
		;Tooltip, %cond1%`n%cond2%`n%cond3%`n%cond4%`n%cond5%
		
		if (cond1 && cond2 && cond3 && cond4)
		{
			if (ShowingGUI1==1)
			{
				Gui, 1: Hide
				ShowingGUI1:=0
			}
		}
		else
		{
			if (ShowingGUI1==0 || cond5)
			{
				Gui, 1: Show, NA
				ShowingGUI1:=1
			}
		}
	}
return

;======================================

get_up_down_data:
	
	Loop % Adapters.MaxIndex() {
	
		Net%A_Index%.Update()
		DownRate:=Net%A_Index%.RxBPS*10
		UpRate:=Net%A_Index%.TxBPS*10

		DownRate_perc:= Round(DownRate/max_down,2) ;*100
		UpRate_perc:= Round(UpRate/max_up, 2) ;*100
		downRate_draw:=Round(grid_h - grid_h*(DownRate_perc)) 
		UpRate_draw:=Round(grid_h - grid_h*(UpRate_perc))
		
	
		array_down%A_Index%.InsertAt(1,downRate_draw)
		array_down%A_Index%.Pop()
		ArraysDown[A_Index] := array_down%A_Index%
		
		
		array_up%A_Index%.InsertAt(1,UpRate_draw)
		array_up%A_Index%.Pop()
		ArraysUp[A_Index] := array_up%A_Index%
		
		
		DownRate_f:=Size_format(DownRate)
		UpRate_f:=Size_format(UpRate)
		DownRate_b:= (DownRate==0) ? "" : Size_format_bar(DownRate)
		UpRate_b:= (UpRate==0) ? "" : Size_format_bar(UpRate)

		
		Gdip_SetProgress(Bar_dn_h%A_Index%, DownRate_perc*100, grad_col_dn%A_Index%, ,Name%A_Index% . " :  " . DownRate_b ,"x0p y4p s78p Center cffEEEEEE r5 Bold","Arial") 
		Gdip_SetProgress(Bar_up_h%A_Index%, UpRate_perc*100, grad_col_up%A_Index%, ,Name%A_Index% . " :  " . UpRate_b ,"x0p y4p s78p Center cffEEEEEE r5 Bold","Arial")
	}
	Gdip_Set_Grid(Grid_img_dn,ArraysDown,DownColors) 
	Gdip_Set_Grid(Grid_img_up,ArraysUp,UpColors) 
return

;=============================

Gdip_Set_Grid(ByRef Variable, ByRef OuterArray, ColorsArray, Background=0xFF131313){ 
	GuiControlGet, Pos, Pos, Variable
	GuiControlGet, hwnd, hwnd, Variable 

	pBitmap := Gdip_CreateBitmap(Posw, Posh)
	G := Gdip_GraphicsFromImage(pBitmap)
	Gdip_SetSmoothingMode(G, 4) 
	pBrushBack := Gdip_BrushCreateSolid(Background) 
	Gdip_FillRectangle(G, pBrushBack, 0, 0, PosW-2, PosH-1) 
	Gdip_DeleteBrush(pBrushBack)

	
	Loop % OuterArray.Length() {
		array := OuterArray[A_Index]
		points:="0," grid_h "|" array.Length() "," grid_h "|" 
		Loop, % array.Length() {
			x:=array.Length() - A_Index
			y:=array[A_Index]
			points:= points x "," y "|"
		}
		points:=substr(points,1,StrLen(points)-1)
		pBrushFront := Gdip_BrushCreateSolid(ColorsArray[A_Index])
		pPath := Gdip_CreatePath(0)
		Gdip_AddPathPolygon(pPath,points) 
		Gdip_FillPath(G,pBrushFront, pPath) 
		Gdip_DeleteBrush(pBrushFront)
		Gdip_DeletePath(pPath)
	}
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	SetImage(hwnd, hBitmap)
	Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
	Return, 0
}


Gdip_SetProgress(ByRef Variable, Percentage, Foreground, Background=0xff2C2C2C, Text="", TextOptions="x0p y2p s80p Center cffEEEEEE r5 Bold", Font="Arial"){
	GuiControlGet, Pos, Pos, Variable
	GuiControlGet, hwnd, hwnd, Variable 

	pBitmap := Gdip_CreateBitmap(Posw, Posh)
	G := Gdip_GraphicsFromImage(pBitmap)
	Gdip_SetSmoothingMode(G, 4) 
	pBrushBack := Gdip_BrushCreateSolid(Background) 
	Gdip_FillRectangle(G, pBrushBack,-1, -1, Posw+1, Posh+1) 

	Foreground_:=StrSplit(Foreground,"|")
	if(Foreground_.Length() >1){
		pBrushFront := Gdip_CreateLineBrushFromRect(0, 0, 1, Foreground_[3], Foreground_[1], Foreground_[2] ,1) 
		Gdip_FillRectangle(G, pBrushFront,0, 0, Posw*(Percentage/100), Posh)
	}
	else
	{
		pBrushFront := Gdip_BrushCreateSolid(Foreground)
		Gdip_FillRectangle(G, pBrushFront, 0, 0, Posw*(Percentage/100), Posh)
	}

	Gdip_TextToGraphics(G, Text, TextOptions, Font, Posw, Posh)
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	SetImage(hwnd, hBitmap)

	Gdip_DeleteBrush(pBrushFront), Gdip_DeleteBrush(pBrushBack)
	Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
	Return, 0
}

;=============================

Gdip_draw_arrow(ByRef Variable, Foreground,flip:=0){
	GuiControlGet, Pos, Pos, Variable
	GuiControlGet, hwnd, hwnd, Variable 

	pBitmap := Gdip_CreateBitmap(PosW, PosH)
	G := Gdip_GraphicsFromImage(pBitmap)
	Gdip_SetSmoothingMode(G, 3) 
	pPen:=Gdip_CreatePen(Foreground, 1)

	points:= PosW/2 ",0|" 0.9* PosW "," 0.4* PosH "|" 0.66* PosW "," 0.4* PosH "|" 0.66* PosW "," PosH "|" 0.33* PosW "," PosH 
	points:= points "|" 0.33* PosW "," 0.4* PosH "|" 0.33* PosW "," 0.4* PosH "|" 0.1* PosW "," 0.4* PosH "|" PosW/2 ",0"

	pBrushFront := Gdip_BrushCreateSolid(Foreground)
	pPath := Gdip_CreatePath(0)
	Gdip_AddPathPolygon(pPath,points) 
	Gdip_FillPath(G,pBrushFront, pPath) 

	Gdip_ImageRotateFlip(pBitmap,flip)
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	SetImage(hwnd, hBitmap)

	Gdip_DeleteBrush(pBrushFront), Gdip_DeletePen(pPen), Gdip_DeletePath(pPath)
	Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
	Return, 0
}
;======================================

Size_format_bar(bytes,round:=0){
	size:=0
	if(!bytes || bytes == 0){
		size :=0 ;" kB" 
	}else if(bytes >= 1000000000){
		if(Mod(bytes,1000000000) < 100000000) ; 0.1 GB
			size :=Round(bytes/1000000000,0) " GB"
		else 
			size :=Round(bytes/1000000000,1) " GB"
	}else if(bytes >= 500000){
		if(round)
			size :=Round(bytes/1000000,0) " MB"
		else 
			size :=Round(bytes/1000000,1) " MB" 
	}else if(bytes >= 10000)
		size :=Round(bytes/1000) " kB"
	else if(bytes && bytes < 100 )
		size := bytes " B" 
	else
		size :=Round(bytes/1000,1) " kB" 
	return size
}

Size_format(bytes,round:=0){
	size:=0
	if(bytes >= 1000000000000)
		size :=Round(bytes/1000000000000,2) " TB"
	else if(bytes >= 1000000000)
		size :=Round(bytes/1000000000,2) " GB"
	else if(bytes >= 1000000){
		if(round)
			size :=Round(bytes/1000000,0) " MB"
		else 
			size :=Round(bytes/1000000,1) " MB" 
	}else if(bytes >= 1000) 
		size :=Round(bytes/1000) " kB"
	else if(!bytes || bytes == 0)
		size :=0 " kB"
	else
		size := bytes " B" 
	return size
}

Size_format_file(bytes,round:=0){
	size:=0
	if(bytes >= 1073741824){
		if(Mod(bytes,1073741824) < 107374182) ; 0.1 GB
			size :=Round(bytes/1073741824,0) " GB"
		else 
			size :=Round(bytes/1073741824,2) " GB"
	}else if (bytes >= 1048576){
		if(round)
			size :=Round(bytes/1048576,0) " MB"
		else 
			size :=Round(bytes/1048576,1) " MB" 
	}else if (bytes >= 1024)
		size :=Round(bytes/1024) " kB"
	else if (bytes == 0)
		size :=0 
	else {
		if(round)
			size := bytes 
		else 
			size := bytes " B" 
	} 
	return size
}

SplitRGBColor(RGBColor, ByRef Red, ByRef Green, ByRef Blue)
{
    Red := RGBColor >> 16 & 0xFF
    Green := RGBColor >> 8 & 0xFF
    Blue := RGBColor & 0xFF
	return
}

FHex( int, pad=0 ) { ; Function by [VxE]. Formats an integer (decimals are truncated) as hex.
	Static hx := "0123456789ABCDEF"
	If !( 0 < int |= 0 )

		Return !int ? "00" : "-" FHex( -int, pad )
	s := 1 + Floor( Ln( int ) / Ln( 16 ) )
	h := SubStr( "0x0000000000000000", 1, pad := pad < s ? s + 2 : pad < 16 ? pad + 2 : 18 )
	u := A_IsUnicode = 1
	Loop % s
		NumPut( *( &hx + ( ( int & 15 ) << u ) ), h, pad - A_Index << u, "UChar" ), int >>= 4
	h := StrReplace(h,"0x")
	h := StrLen(h)<2 ? "0" . h : h
	Return h
}



Reload:
Reload
return


Close:
GuiClose:
Exit:
	Gdip_Shutdown(pToken)
	ExitApp