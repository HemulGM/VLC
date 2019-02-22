(*
 * PasLibVlcClassUnit.pas
 *
 * Last modified: 2018.07.01
 *
 * author: Robert Jêdrzejczyk
 * e-mail: robert@prog.olsztyn.pl
 *    www: http://prog.olsztyn.pl/paslibvlc
 *
  *******************************************************************************
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * Any non-GPL usage of this software or parts of this software is strictly
 * forbidden.
 *
 * The "appropriate copyright message" mentioned in section 2c of the GPLv2
 * must read: "Code from FAAD2 is copyright (c) Nero AG, www.nero.com"
 *
 *)

{$I .\compiler.inc}

unit PasLibVlcClassUnit;

interface

uses
  {$IFDEF UNIX}Unix,{$ENDIF}
  {$IFDEF MSWINDOWS}Windows,{$ENDIF} 
  Classes, SysUtils,
  PasLibVlcUnit;

type
  TDeinterlaceFilter = (deOFF, deON);
  TDeinterlaceMode   = (dmDISCARD, dmBLEND, dmMEAN, dmBOB, dmLINEAR, dmX, dmYADIF, dmYADIF2x, dmPHOSPHOR, dmIVTC);

  TPasLibVlcTitlePosition = (
    plvPosCenter,
    plvPosLeft,
    plvPosRight,
    plvPosTop,
    plvPosTopLeft,
    plvPosTopRight,
    plvPosBottom,
    plvPosBottomLeft,
    plvPosBottomRight
  );

  TVideoRatio = (ra_NONE, ra_16_9, ra_16_10, ra_185_100, ra_221_100, ra_235_100, ra_239_100, ra_4_3, ra_5_4, ra_5_3, ra_1_1);

  TMux = (muxTS, muxPS, muxMp4, muxOgg, muxAvi);

  TVideoOutput = (
    voDefault
    {$IFDEF DARWIN}, voMacOSX{$ENDIF}
    {$IFDEF UNIX}, voX11, voXVideo, voGlx{$ENDIF}
    {$IFDEF MSWINDOWS}, voWinGdi, voDirectX, voDirect3d, voOpenGl{$ENDIF}
    , voDummy
  );

  TAudioOutput = (
    aoDefault
    {$IFDEF DARWIN}, aoCoreAudio{$ENDIF}
    {$IFDEF UNIX}, aoOpenSystemSound, aoAdvancedLinuxSoundArchitecture, aoEnlightenedSoundDaemon, aoKdeSoundServer{$ENDIF}
    {$IFDEF MSWINDOWS}, aoDirectX, aoWaveOut{$ENDIF}
    , aoDummy
  );

  TVideoCodec = (vcNONE, vcMPGV, vcMP4V, vcH264, vcTHEORA);
  
  TAudioCodec = (acNONE, acMPGA, acMP3, acMP4A, acVORB, acFLAC);

const
  // http://www.videolan.org/doc/vlc-user-guide/en/ch02.html#id331515
  vlcDeinterlaceModeNames : array[TDeinterlaceMode] of string = (
    'discard', 'blend', 'mean', 'bob', 'linear', 'x', 'yadif', 'yadif2x', 'phosphor', 'ivtc');

  // http://www.videolan.org/doc/vlc-user-guide/en/ch02.html#id328503
  vlcMuxNames : array[TMux] of AnsiString = (
    'ts', 'ps', 'mp4', 'ogg', 'avi');

  // http://www.videolan.org/doc/vlc-user-guide/en/ch02.html#id330667
  vlcVideoOutputNames : array[TVideoOutput] of string = (
    'default'
    {$IFDEF DARWIN}, 'macosx' {$ENDIF}
    {$IFDEF UNIX}, 'x11', 'xvideo', 'glx'{$ENDIF}
    {$IFDEF MSWINDOWS}, 'wingdi', 'directx', 'direct3d', 'opengl'{$ENDIF}
    , 'dummy'
  );

  // http://www.videolan.org/doc/vlc-user-guide/en/ch02.html#id332336
  vlcAudioOutputNames : array[TAudioOutput] of string = (
    'default'
    {$IFDEF DARWIN}, 'coreaudio'{$ENDIF}
    {$IFDEF UNIX}, 'oss', 'alsa', 'esd', 'arts'{$ENDIF}
    {$IFDEF MSWINDOWS}, 'directx', 'waveout'{$ENDIF}
    , 'dummy'
  );

  vlcVideoRatioNames : array[TVideoRatio] of AnsiString = (
    '', '16:9', '16:10', '185:100', '221:100', '235:100', '239:100', '4:3', '5:4', '5:3', '1:1');

  // http://www.videolan.org/doc/vlc-user-guide/en/ch02.html#id329971
  vlcVideoCodecNames : array[TVideoCodec] of AnsiString = (
    '', 'mpgv', 'mp4v', 'mp4v', 'theora');

  vlcAudioCodecNames : array[TAudioCodec] of AnsiString = (
    '', 'mpga', 'mp3', 'mp4a', 'vorb', 'flac');

type
  TPasLibVlc = class
  private
    FHandle : libvlc_instance_t_ptr;
    FPath   : WideString;

    FTitleShow : Boolean;

    FVersionBin : LongWord;

    FStartOptions : TStringList;

    function GetHandle()     : libvlc_instance_t_ptr;
    function GetError()      : WideString;
    function GetVersion()    : WideString;
    function GetVersionBin() : LongWord;
    function GetCompiler()   : WideString;
    function GetChangeSet()  : WideString;

    procedure SetPath(aPath: WideString);
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddOption(option : string);

    property Handle     : libvlc_instance_t_ptr read GetHandle;
    property Error      : WideString            read GetError;
    property Version    : WideString            read GetVersion;
    property VersionBin : LongWord              read GetVersionBin;
    property Compiler   : WideString            read GetCompiler;
    property ChangeSet  : WideString            read GetChangeSet;
    property Path       : WideString            read FPath write SetPath;
    property TitleShow  : Boolean               read FTitleShow write FTitleShow default FALSE;

    property StartOptions : TStringList read FStartOptions;
  end;

////////////////////////////////////////////////////////////////////////////////

  TPasLibVlcMediaPlayerC = class;
  TPasLibVlcMediaListC = class;
  
  TPasLibVlcMedia = class
  private
    FVLC : TPasLibVlc;
    FMD  : libvlc_media_t_ptr;
  public
    constructor Create(aVLC: TPasLibVlc); overload;
    constructor Create(aVLC: TPasLibVlc; aMrl: WideString); overload;
    constructor Create(aVLC: TPasLibVlc; aMD: libvlc_media_t_ptr); overload;
    constructor Create(aVLC: TPasLibVlc; aStm : TStream); overload;
    destructor Destroy; override;

    procedure NewLocation(mrl: WideString);
    procedure NewPath(path: WideString);
    procedure NewNode(name: WideString);
    procedure NewStream(stm : TStream);

    procedure AddOption(option: WideString);
    procedure AddOptionFlag(option: WideString; flag: input_item_option_e);

    function GetMrl(): WideString;

    function Duplicate(): TPasLibVlcMedia;

    function GetMeta(meta: libvlc_meta_t): WideString;
    procedure SetMeta(meta: libvlc_meta_t; value: WideString);
    procedure SaveMeta();

    function GetState(): libvlc_state_t;
    function GetStats(var stats: libvlc_media_stats_t): Boolean;

    function SubItems(): TPasLibVlcMediaListC;

    function GetEventManager(): libvlc_event_manager_t_ptr;

    function GetDuration(): libvlc_time_t;

    procedure Parse();
    procedure ParseAsync();

    function IsParsed(): Boolean;

    procedure SetUserData(data: Pointer);
    function GetUserData(): Pointer;

    function GetTracksInfo(var tracks : libvlc_media_track_info_t_ptr): Integer;

    procedure SetDeinterlaceFilter(aValue: TDeinterlaceFilter);
    procedure SetDeinterlaceFilterMode(aValue: TDeinterlaceMode);
    
    property MD : libvlc_media_t_ptr read FMD;
  end;

////////////////////////////////////////////////////////////////////////////////

  TPasLibVlcMediaListC = class
  private
    FVLC: TPasLibVlc;
    FML:  libvlc_media_list_t_ptr;

    FMP: TPasLibVlcMediaPlayerC;
  public
    constructor Create(aVLC: TPasLibVlc); overload;
    constructor Create(aVLC: TPasLibVlc; aML: libvlc_media_list_t_ptr); overload;
    destructor Destroy; override;

    procedure SetMedia(media: TPasLibVlcMedia);
    function GetMedia(): TPasLibVlcMedia;               overload;
    function GetMedia(index: Integer): TPasLibVlcMedia; overload;
    function GetIndex(media: TPasLibVlcMedia): Integer;
    function IsReadOnly(): Boolean;

    procedure Add(mrl: WideString); overload;
    procedure Add(media: TPasLibVlcMedia); overload;
    procedure Insert(media: TPasLibVlcMedia; index: Integer);
    procedure Delete(index: Integer);
    procedure Clear();
    function Count(): Integer;

    procedure Lock();
    procedure UnLock();

    function GetEventManager(): libvlc_event_manager_t_ptr;

    property ML : libvlc_media_list_t_ptr read FML;
    property MI : TPasLibVlcMediaPlayerC read FMP write FMP;
  end;

////////////////////////////////////////////////////////////////////////////////

  TPasLibVlcMediaPlayerC = class
  private
    FTitleShow   : Boolean;
    FVideoOnTop  : Boolean;
    FUseOverlay  : Boolean;
    FSnapShotFmt : string;

    FDeinterlaceFilter: TDeinterlaceFilter;
    FDeinterlaceMode:   TDeinterlaceMode;

  public
    property TitleShow   : Boolean read FTitleShow   write FTitleShow  default FALSE;
    property VideoOnTop  : Boolean read FVideoOnTop  write FVideoOnTop default FALSE;
    property UseOverlay  : Boolean read FUseOverlay  write FUseOverlay default FALSE;
    property SnapShotFmt : string  read FSnapShotFmt write FSnapShotFmt;
    property DeinterlaceFilter: TDeinterlaceFilter read FDeinterlaceFilter write FDeinterlaceFilter default deOFF;
    property DeinterlaceMode:   TDeinterlaceMode   read FDeinterlaceMode   write FDeinterlaceMode   default dmDISCARD;
  end;

////////////////////////////////////////////////////////////////////////////////

  TPasLibVlcEqualizer = class
  private
    FVLC       : TPasLibVlc;
    FEqualizer : libvlc_equalizer_t_ptr;
    FPreset    : Word;
  public
    constructor Create(AVLC: TPasLibVlc; APreset : unsigned_t = $FFFF);
    destructor Destroy; override;

    function GetPreAmp() : Single;
    procedure SetPreAmp(value : Single);

    function GetAmp(index: unsigned_t) :  Single;
    procedure SetAmp(index : unsigned_t; value : Single);

    function GetBandCount() : unsigned_t;
    function GetBandFrequency(index : unsigned_t) : Single;

    function GetPresetCount() : unsigned_t;
    function GetPresetName(index : unsigned_t) : WideString; overload;
    function GetPresetName() : WideString; overload;
    function GetPreset() : unsigned_t;
    procedure SetPreset(APreset : unsigned_t = $FFFF);

    function GetHandle() : libvlc_equalizer_t_ptr;
  end;

////////////////////////////////////////////////////////////////////////////////

implementation

{$IFDEF DELPHI_XE6_UP}
uses
	System.AnsiStrings;
{$ENDIF}

constructor TPasLibVlc.Create;
begin
  inherited Create;
  
  FHandle       := NIL;
  FTitleShow    := FALSE;
  FStartOptions := TStringList.Create;
  FVersionBin   := 0;
end;

destructor TPasLibVlc.Destroy;
begin
  if (Assigned(libvlc_release)) then
  begin
    if (FHandle <> NIL) then
    begin
      libvlc_release(FHandle);
      FHandle := NIL;
    end;
  end;

  FStartOptions.Free;
  FStartOptions := NIL;

  inherited Destroy;
end;

procedure TPasLibVlc.AddOption(option : string);
begin
  if (option <> '') and (FStartOptions.IndexOf(option) < 0) then
  begin
    FStartOptions.Add(option);
  end;
end;

{$WARNINGS OFF}
{$HINTS OFF}
function TPasLibVlc.GetHandle() : libvlc_instance_t_ptr;
begin
  Result := NIL;
  if (FHandle = NIL) then
  begin
    if (FPath <> '') then
    begin
      libvlc_dynamic_dll_init_with_path(FPath);
      if (libvlc_dynamic_dll_error <> '') then libvlc_dynamic_dll_init();
    end
    else
    begin
      libvlc_dynamic_dll_init();
    end;
    if (libvlc_dynamic_dll_error <> '') then exit;

    with TArgcArgs.Create([
      libvlc_dynamic_dll_path,
      '--ignore-config',
      '--intf=dummy',
      '--quiet'
//'--telnet-host=localhost',
//'--telnet-port=4212',
//'--telnet-password=test'
//'--extraintf=telnet',
    ]) do
    begin

      // AddArg('--no-one-instance');

      AddArg(FStartOptions);

      if (VersionBin < $020100) then
      begin
        if not TitleShow then
        begin
          AddArg('--no-video-title-show');
        end
        else
        begin
          AddArg('--video-title-show');
        end;
      end;

      // activate marq and logo subfilters
      if (VersionBin >= $010100) then
      begin
        AddArg('--sub-filter=logo:marq');
      end;
      if (VersionBin >= $020000) then
      begin
        AddArg('--sub-source=marq');
      end;

      FHandle := libvlc_new(ARGC, ARGS);

      Free;
    end;
  end;
  Result := FHandle;
end;
{$WARNINGS ON}
{$HINTS ON}

function TPasLibVlc.GetError() : WideString;
begin
  Result := '';
  if Assigned(libvlc_errmsg) then
    Result := {$IFDEF DELPHI_XE2_UP}UTF8ToWideString{$ELSE}UTF8Decode{$ENDIF}(AnsiString(libvlc_errmsg()))
end;

function TPasLibVlc.GetVersion() : WideString;
begin
  Result := '';
  if Assigned(libvlc_get_version) then
    Result := {$IFDEF DELPHI_XE2_UP}UTF8ToWideString{$ELSE}UTF8Decode{$ENDIF}(AnsiString(libvlc_get_version()));
end;
  
function TPasLibVlc.GetVersionBin() : LongWord;
var
  ver_utf8 : PAnsiChar;
  ver_numa : LongWord;
  ver_numb : LongWord;
  ver_numc : LongWord;
begin
  if (FVersionBin = 0) then
  begin
    if Assigned(libvlc_get_version) then
    begin
      ver_utf8 := libvlc_get_version();
      ver_numa := read_dec_number(ver_utf8) and $ff;
      ver_numb := read_dec_number(ver_utf8) and $ff;
      ver_numc := read_dec_number(ver_utf8) and $ff;
      FVersionBin := (ver_numa shl 16) or (ver_numb shl 8) or ver_numc;
    end;
  end;
  Result := FVersionBin;
end;

function TPasLibVlc.GetCompiler() : WideString;
begin
  Result := '';
  if Assigned(libvlc_get_compiler) then
    Result := {$IFDEF DELPHI_XE2_UP}UTF8ToWideString{$ELSE}UTF8Decode{$ENDIF}(AnsiString(libvlc_get_compiler()));
end;

function TPasLibVlc.GetChangeSet() : WideString;
begin
  Result := '';
  if Assigned(libvlc_get_changeset) then
    Result := {$IFDEF DELPHI_XE2_UP}UTF8ToWideString{$ELSE}UTF8Decode{$ENDIF}(AnsiString(libvlc_get_changeset()));
end;

procedure TPasLibVlc.SetPath(aPath: WideString);
begin
  FPath := aPath;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TPasLibVlcMedia.Create(aVLC: TPasLibVlc);
begin
  inherited Create;
  FVLC := aVLC;
  FMD  := NIL;
end;

constructor TPasLibVlcMedia.Create(aVlc: TPasLibVlc; aMrl: WideString);
begin
  inherited Create;
  FVLC := aVLC;
  FMD  := NIL;

  if FileExists(aMrl) then
    NewPath(aMrl)
  else
    NewLocation(aMrl);
end;

constructor TPasLibVlcMedia.Create(aVlc : TPasLibVlc; aMD : libvlc_media_t_ptr);
begin
  inherited Create;
  FVLC := aVLC;
  FMD  := aMD;
end;

constructor TPasLibVlcMedia.Create(aVlc : TPasLibVlc; aStm : TStream);
begin
  inherited Create;
  FVLC := aVLC;
  FMD  := NIL;
  NewStream(aStm);
end;

destructor TPasLibVlcMedia.Destroy;
begin
  if (FMD <> NIL) then
  begin
    libvlc_media_release(FMD);
  end;
  inherited Destroy;
end;

procedure TPasLibVlcMedia.SetDeinterlaceFilter(aValue : TDeinterlaceFilter);
begin
  case aValue of
    deOFF:  AddOption('deinterlace=0');
    deON:   AddOption('deinterlace=1');
  end;
end;

procedure TPasLibVlcMedia.SetDeinterlaceFilterMode(aValue : TDeinterlaceMode);
begin
  AddOption('deinterlace-mode=' + WideString(vlcDeinterlaceModeNames[aValue]));
end;

// media.AddOption('http-caching=1000');
// media.AddOption('network-caching=1000');
// media.AddOption('avcodec-hw=none');

// char mp4_high[] = "#transcode{vcodec=h264,venc=x264{cfr=16},scale=1,acodec=mp4a,ab=160,channels=2,samplerate=44100}";
// char mp4_low[]  = "#transcode{vcodec=h264,venc=x264{cfr=40},scale=1,acodec=mp4a,ab=96,channels=2,samplerate=44100}";

// display and file, transcode before
//  media.AddOption(':sout=#transcode{}:duplicate{dst=display,dst=std{access=file,mux=avi,dst="c:\test.avi"}}');

// display and file, no transcode
//  media.AddOption(':sout=#duplicate{dst=display,dst=std{access=file,mux=avi,dst="c:\test.avi"}}');

// display and output at rtp://127.0.0.1:1234
//  media.AddOption(':sout=#duplicate{dst=display,dst=rtp{dst=127.0.0.1,port=1234,mux=ts}}');

// no display, file with transcode to mp4
//  media.AddOption(':sout=#transcode{vcodec=h264,vb=1024,fps=25,scale=1,acodec=mp3}:std{access=file,mux=mp4,dst="c:\test.mp4"}');

procedure TPasLibVlcMedia.AddOption(option: WideString);
var
  temp : AnsiString;
begin
  if (FMD <> NIL) then
  begin
    temp := Utf8Encode(Trim(option));
    if (temp <> '') then
    begin
      libvlc_media_add_option(FMD, PAnsiChar(temp));
    end;
  end;
end;

procedure TPasLibVlcMedia.AddOptionFlag(option: WideString; flag: input_item_option_e);
begin
  if (FMD <> NIL) then
  begin
    libvlc_media_add_option_flag(FMD, PAnsiChar(UTF8Encode(option)), flag);
  end;
end;

procedure TPasLibVlcMedia.NewLocation(mrl: WideString);
begin
  if (FVLC.Handle <> NIL) then
  begin
    FMD := libvlc_media_new_location(FVLC.Handle, PAnsiChar(UTF8Encode(mrl)));
  end;
end;

procedure TPasLibVlcMedia.NewPath(path: WideString);
begin
  if (FVLC.Handle <> NIL) then
  begin
    FMD := libvlc_media_new_path(FVLC.Handle, PAnsiChar(UTF8Encode(path)));
  end;
end;

procedure TPasLibVlcMedia.NewNode(name: WideString);
begin
  if (FVLC.Handle <> NIL) then
  begin
    FMD := libvlc_media_new_as_node(FVLC.Handle, PAnsiChar(UTF8Encode(name)));
  end;
end;

procedure TPasLibVlcMedia.NewStream(stm: TStream);
begin
  if (FVLC.Handle <> NIL) then
  begin
    FMD := libvlc_media_new_callbacks(
      FVLC.FHandle,
      libvlc_media_open_cb_stm,
      libvlc_media_read_cb_stm,
      libvlc_media_seek_cb_stm,
      libvlc_media_close_cb_stm,
      Pointer(stm)
    );
  end;
end;

function TPasLibVlcMedia.GetMrl(): WideString;
begin
  if (FMD <> NIL) then
  begin
    Result := {$IFDEF DELPHI_XE2_UP}UTF8ToWideString{$ELSE}UTF8Decode{$ENDIF}(AnsiString(libvlc_media_get_mrl(FMD)));
  end
  else
  begin
    Result := '';
  end;
end;

function TPasLibVlcMedia.Duplicate(): TPasLibVlcMedia;
begin
  if (FMD = NIL) then Result := TPasLibVlcMedia.Create(FVLC)
  else Result := TPasLibVlcMedia.Create(FVLC, libvlc_media_duplicate(FMD));
end;

function TPasLibVlcMedia.GetMeta(meta: libvlc_meta_t): WideString;
begin
  Result := {$IFDEF DELPHI_XE2_UP}UTF8ToWideString{$ELSE}UTF8Decode{$ENDIF}(AnsiString(libvlc_media_get_meta(FMD, meta)));
end;

procedure TPasLibVlcMedia.SetMeta(meta: libvlc_meta_t; value: WideString);
begin
  libvlc_media_set_meta(FMD, meta, PAnsiChar(UTF8Encode(value)));
end;

procedure TPasLibVlcMedia.SaveMeta();
begin
  libvlc_media_save_meta(FMD);
end;

function TPasLibVlcMedia.GetState(): libvlc_state_t;
begin
  Result := libvlc_media_get_state(FMD);
end;

function TPasLibVlcMedia.GetStats(var stats: libvlc_media_stats_t): Boolean;
begin
  Result := (libvlc_media_get_stats(FMD, @stats ) <> 0);
end;

function TPasLibVlcMedia.SubItems(): TPasLibVlcMediaListC;
begin
  Result := TPasLibVlcMediaListC.Create(
    FVLC,
    libvlc_media_subitems(FMD)
  );
end;

function TPasLibVlcMedia.GetEventManager(): libvlc_event_manager_t_ptr;
begin
  Result := libvlc_media_event_manager(FMD);
end;

function TPasLibVlcMedia.GetDuration(): libvlc_time_t;
begin
  Result := libvlc_media_get_duration(FMD);
end;

procedure TPasLibVlcMedia.Parse();
begin
  libvlc_media_parse(FMD);
end;

procedure TPasLibVlcMedia.ParseAsync();
begin
  libvlc_media_parse_async(FMD);
end;

function TPasLibVlcMedia.IsParsed(): Boolean;
begin
  Result := (libvlc_media_is_parsed(FMD) <> 0);
end;

procedure TPasLibVlcMedia.SetUserData(data: Pointer);
begin
  libvlc_media_set_user_data(FMD, data);
end;

function TPasLibVlcMedia.GetUserData(): Pointer;
begin
  Result := libvlc_media_get_user_data(FMD);
end;

function TPasLibVlcMedia.GetTracksInfo(var tracks : libvlc_media_track_info_t_ptr): Integer;
begin
  Result := libvlc_media_get_tracks_info(FMD, tracks);
end;

////////////////////////////////////////////////////////////////////////////////

constructor TPasLibVlcMediaListC.Create(aVLC: TPasLibVlc);
begin
  inherited Create;
  FVLC := aVLC;
  FML  := libvlc_media_list_new(FVLC.Handle);
end;

constructor TPasLibVlcMediaListC.Create(aVLC: TPasLibVlc; aML: libvlc_media_list_t_ptr);
begin
  inherited Create;
  FVLC    := aVLC;
  FML     := aML;
end;

destructor TPasLibVlcMediaListC.Destroy;
begin
  if (FML <> NIL) then
  begin
    libvlc_media_list_release(FML);
  end;
  
  inherited Destroy;
end;

procedure TPasLibVlcMediaListC.SetMedia(media: TPasLibVlcMedia);
begin
  libvlc_media_list_set_media(FML, media.MD);
end;

function TPasLibVlcMediaListC.GetMedia(): TPasLibVlcMedia;
begin
  Result := TPasLibVlcMedia.Create(FVLC, libvlc_media_list_media(FML));
end;

function TPasLibVlcMediaListC.GetMedia(index: Integer): TPasLibVlcMedia;
begin
  Result := TPasLibVlcMedia.Create(
    FVLC,
    libvlc_media_list_item_at_index(FML, index)
  );
end;

function TPasLibVlcMediaListC.GetIndex(media: TPasLibVlcMedia): Integer;
begin
  Result := libvlc_media_list_index_of_item(
    FML,
    media.MD
  );
end;

function TPasLibVlcMediaListC.IsReadOnly(): Boolean;
begin
  Result := (libvlc_media_list_is_readonly(FML) = 0);
end;

procedure TPasLibVlcMediaListC.Add(mrl: WideString);
var
  media: TPasLibVlcMedia;
begin
  media := TPasLibVlcMedia.Create(FVLC, mrl);

  if Assigned(SELF.FMP) then
  begin
    media.SetDeinterlaceFilter(SELF.FMP.FDeinterlaceFilter);
    media.SetDeinterlaceFilterMode(SELF.FMP.FDeinterlaceMode);
  end;

  Add(media);

  media.Free;
end;

procedure TPasLibVlcMediaListC.Add(media: TPasLibVlcMedia);
begin
  libvlc_media_list_lock(FML);
  libvlc_media_list_add_media(FML, media.MD);
  libvlc_media_list_unlock(FML);
end;

procedure TPasLibVlcMediaListC.Insert(media: TPasLibVlcMedia; index: Integer);
begin
  libvlc_media_list_lock(FML);
  libvlc_media_list_insert_media(FML, media.MD, index);
  libvlc_media_list_unlock(FML);
end;

procedure TPasLibVlcMediaListC.Delete(index: Integer);
begin
  libvlc_media_list_lock(FML);
  libvlc_media_list_remove_index(FML, index);
  libvlc_media_list_unlock(FML);
end;

procedure TPasLibVlcMediaListC.Clear();
begin
  libvlc_media_list_lock(FML);
  while (Count() > 0) do
  begin
    libvlc_media_list_remove_index(FML, 0);
  end;
  libvlc_media_list_unlock(FML);
end;

function TPasLibVlcMediaListC.Count(): Integer;
begin
  libvlc_media_list_lock(FML);
  Result := libvlc_media_list_count(FML);
  libvlc_media_list_unlock(FML);
end;

procedure TPasLibVlcMediaListC.Lock();
begin
  libvlc_media_list_lock(FML);
end;

procedure TPasLibVlcMediaListC.UnLock();
begin
  libvlc_media_list_unlock(FML);
end;

function TPasLibVlcMediaListC.GetEventManager(): libvlc_event_manager_t_ptr;
begin
  Result := libvlc_media_list_event_manager(FML);
end;

////////////////////////////////////////////////////////////////////////////////

constructor TPasLibVlcEqualizer.Create(AVLC: TPasLibVlc; aPreset : unsigned_t = $FFFF);
begin
  inherited Create;
  FVLC       := AVLC;
  FEqualizer := NIL;
  FPreset    := aPreset;
end;

destructor TPasLibVlcEqualizer.Destroy;
begin
  if (FEqualizer <> NIL) then
  begin
    libvlc_audio_equalizer_release(FEqualizer);
    FEqualizer := NIL;
  end;
  inherited Destroy;
end;

function TPasLibVlcEqualizer.GetPreAmp() : Single;
begin
  Result := 0;
  if (SELF.GetHandle() = NIL) then exit;
  Result := libvlc_audio_equalizer_get_preamp(FEqualizer);
end;

procedure TPasLibVlcEqualizer.SetPreAmp(value : Single);
begin
  if (SELF.GetHandle() = NIL) then exit;
  libvlc_audio_equalizer_set_preamp(FEqualizer, value);
end;

function TPasLibVlcEqualizer.GetAmp(index: unsigned_t) :  Single;
begin
  Result := 0;
  if (SELF.GetHandle() = NIL) then exit;
  Result := libvlc_audio_equalizer_get_amp_at_index(FEqualizer, index);
end;

procedure TPasLibVlcEqualizer.SetAmp(index : unsigned_t; value : Single);
begin
  if (SELF.GetHandle() = NIL) then exit;
  libvlc_audio_equalizer_set_amp_at_index(FEqualizer, value, index);
end;

function TPasLibVlcEqualizer.GetBandCount() : unsigned_t;
begin
  Result := 0;
  if (FVLC.GetHandle() = NIL) then exit;  
  Result := libvlc_audio_equalizer_get_band_count();
end;

function TPasLibVlcEqualizer.GetBandFrequency(index : unsigned_t) : Single;
begin
  Result := 0;
  if (FVLC.GetHandle() = NIL) then exit;
  Result := libvlc_audio_equalizer_get_band_frequency(index);
end;

function TPasLibVlcEqualizer.GetPresetCount() : unsigned_t;
begin
  Result := 0;
  if (FVLC.GetHandle() = NIL) then exit;
  Result := libvlc_audio_equalizer_get_preset_count();
end;

function TPasLibVlcEqualizer.GetPresetName(index : unsigned_t) : WideString;
var
  preset : PAnsiChar;
begin
  Result := '';
  if (FVLC.GetHandle() = NIL) then exit;
  preset := libvlc_audio_equalizer_get_preset_name(index);
  Result := {$IFDEF DELPHI_XE2_UP}UTF8ToWideString{$ELSE}UTF8Decode{$ENDIF}(preset);
end;

function TPasLibVlcEqualizer.GetPresetName() : WideString;
begin
  Result := GetPresetName(FPreset);
end;

function TPasLibVlcEqualizer.GetPreset() : unsigned_t;
begin
  Result := FPreset;
end;

procedure TPasLibVlcEqualizer.SetPreset(APreset : unsigned_t = $FFFF);
begin
  FPreset := aPreset;
  if (FEqualizer <> NIL) then
  begin
    libvlc_audio_equalizer_release(FEqualizer);
    FEqualizer := NIL;
  end;
end;

function TPasLibVlcEqualizer.GetHandle() : libvlc_equalizer_t_ptr;
begin
  Result := NIL;
  if (FVLC.GetHandle() = NIL) then exit;
  
  if (FEqualizer = NIL) then
  begin
    if (FPreset<> $FFFF) then
    begin
      FEqualizer := libvlc_audio_equalizer_new_from_preset(FPreset);
    end;
    if (FEqualizer = NIL) then
    begin
      FEqualizer := libvlc_audio_equalizer_new();
    end;
  end;
  Result := FEqualizer;
end;

end.
