(*
 *******************************************************************************
 * FmxPasLibVlcPlayerUnit.pas - FMX component for VideoLAN libvlc 3.0.5
 *
 * See copyright notice below.
 *
 * Last modified: 2019.03.24
 *
 * author: Robert Jędrzejczyk
 * e-mail: robert@prog.olsztyn.pl
 *    www: http://prog.olsztyn.pl/paslibvlc
 *
 *
 * See FmxPasLibVlcPlayerUnit.txt for change log
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
 *******************************************************************************
 *
 * libvlc is part of project VideoLAN
 *
 * Copyright (c) 1996-2018 VideoLAN Team
 *
 * For more information about VideoLAN
 *
 * please visit http://www.videolan.org
 *
 *)

{$I compiler.inc}

unit FmxPasLibVlcPlayerUnit;

{$IFDEF DELPHI_XE7_UP}
{$ENDIF}

interface

uses
  {$IFDEF UNIX}Unix,{$ENDIF}
  {$IFDEF MSWINDOWS}Windows,{$ENDIF}
  Classes, SysUtils, SyncObjs,
  FMX.Types, FMX.Objects, FMX.Graphics, System.UITypes,
  PasLibVlcClassUnit,
  PasLibVlcUnit;

type
  TFmxPasLibVlcPlayerState = (
    plvPlayer_NothingSpecial,
    plvPlayer_Opening,
    plvPlayer_Buffering,
    plvPlayer_Playing,
    plvPlayer_Paused,
    plvPlayer_Stopped,
    plvPlayer_Ended,
    plvPlayer_Error
  );

type
  TNotifySeekableChanged    = procedure(Sender : TObject; val             : Boolean) of object;
  TNotifyPausableChanged    = procedure(Sender : TObject; val             : Boolean) of object;
  TNotifyTitleChanged       = procedure(Sender : TObject; title           : Integer) of object;
  TNotifySnapshotTaken      = procedure(Sender : TObject; fileName        : string)  of object;
  TNotifyTimeChanged        = procedure(Sender : TObject; time            : Int64)   of object;
  TNotifyLengthChanged      = procedure(Sender : TObject; time            : Int64)   of object;
  TNotifyPositionChanged    = procedure(Sender : TObject; position        : Single)  of object;
  TNotifyMediaChanged       = procedure(Sender : TObject; mrl             : string)  of object;
  TNotifyVideoOutChanged    = procedure(Sender : TObject; video_out       : Integer) of object;
  TNotifyScrambledChanged   = procedure(Sender : TObject; scrambled       : Integer) of object;
  TNotifyPlayerEvent        = procedure(p_event: libvlc_event_t_ptr; data : Pointer) of object;
  TNotifyAudioVolumeChanged = procedure(Sender : TObject; volume          : Single)  of object;
  TNotifyVideoSizeChanged   = procedure(Sender : TObject; view_w, video_h, video_w_a32, video_h_a32 : LongWord)  of object;

  TNotifyMediaPlayerEsAdded            = procedure(Sender : TObject; i_type : libvlc_track_type_t; i_id : Integer) of object;
  TNotifyMediaPlayerEsDeleted          = procedure(Sender : TObject; i_type : libvlc_track_type_t; i_id : Integer) of object;
  TNotifyMediaPlayerEsSelected         = procedure(Sender : TObject; i_type : libvlc_track_type_t; i_id : Integer) of object;

  TNotifyMediaPlayerAudioDevice        = procedure(Sender : TObject; audio_device    : string) of object;
  TNotifyMediaPlayerChapterChanged     = procedure(Sender : TObject; chapter         : Integer) of object;

  TNotifyRendererDiscoveredItemAdded   = procedure(Sender : TObject; item : libvlc_renderer_item_t_ptr) of object;
  TNotifyRendererDiscoveredItemDeleted = procedure(Sender : TObject; item : libvlc_renderer_item_t_ptr) of object;

type
  TFmxPasLibVlcVideoCbCtx = class
    vctx               : TVideoCbCtx;
    view               : FMX.Objects.TImage;
    frame_buff         : Pointer;
    frame_lock         : TCriticalSection;
    frame_pixel_format : TPixelFormat;
  public
    constructor Create(AView : FMX.Objects.TImage; aWidth : Integer = 320; aHeight : Integer = 160);
    destructor Destroy; override;
  end;

type
  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX32)] //  or pidiOSSimulator or pidAndroid or pidLinux32 or pidiOSDevice
  TFmxPasLibVlcPlayer = class(FMX.Objects.TImage)
  private
    FVLC        : TPasLibVlc;
    p_mi        : libvlc_media_player_t_ptr;
    p_mi_ev_mgr : libvlc_event_manager_t_ptr;
    FVideoCbCtx : TFmxPasLibVlcVideoCbCtx;

    //
    FError        : string;
    FMute         : Boolean;

    FAudioOutput : TAudioOutput;

    FTitleShow        : Boolean;
    FTitleShowPos     : TPasLibVlcTitlePosition;
    FTitleShowTimeOut : LongWord;

    FSnapshotFmt  : string;
    FSnapshotPrv  : Boolean;

    FSpuShow      : Boolean;
    FOsdShow      : Boolean;

    FViewTeleText : Boolean;

    FDeinterlaceFilter : TDeinterlaceFilter;
    FDeinterlaceMode   : TDeinterlaceMode;

    FLastAudioOutput : WideString;
    FLastAudioOutputDeviceId : WideString;
    
    // events handlers
    FOnMediaPlayerMediaChanged       : TNotifyMediaChanged;
    FOnMediaPlayerNothingSpecial     : TNotifyEvent;
    FOnMediaPlayerOpening            : TNotifyEvent;
    FOnMediaPlayerBuffering          : TNotifyEvent;
    FOnMediaPlayerPlaying            : TNotifyEvent;
    FOnMediaPlayerPaused             : TNotifyEvent;
    FOnMediaPlayerStopped            : TNotifyEvent;
    FOnMediaPlayerForward            : TNotifyEvent;
    FOnMediaPlayerBackward           : TNotifyEvent;
    FOnMediaPlayerEndReached         : TNotifyEvent;
    FOnMediaPlayerEncounteredError   : TNotifyEvent;
    FOnMediaPlayerTimeChanged        : TNotifyTimeChanged;
    FOnMediaPlayerPositionChanged    : TNotifyPositionChanged;
    FOnMediaPlayerSeekableChanged    : TNotifySeekableChanged;
    FOnMediaPlayerPausableChanged    : TNotifyPausableChanged;
    FOnMediaPlayerTitleChanged       : TNotifyTitleChanged;
    FOnMediaPlayerSnapshotTaken      : TNotifySnapshotTaken;
    FOnMediaPlayerLengthChanged      : TNotifyLengthChanged;
    FOnMediaPlayerVideoOutChanged    : TNotifyVideoOutChanged;
    FOnMediaPlayerScrambledChanged   : TNotifyScrambledChanged;
    FOnMediaPlayerEvent              : TNotifyPlayerEvent;
    FOnMediaPlayerCorked             : TNotifyEvent;
    FOnMediaPlayerUnCorked           : TNotifyEvent;
    FOnMediaPlayerMuted              : TNotifyEvent;
    FOnMediaPlayerUnMuted            : TNotifyEvent;
    FOnMediaPlayerAudioVolumeChanged : TNotifyAudioVolumeChanged;
    FOnMediaPlayerVideoSizeChanged   : TNotifyVideoSizeChanged;

    FOnMediaPlayerEsAdded            : TNotifyMediaPlayerEsAdded;
    FOnMediaPlayerEsDeleted          : TNotifyMediaPlayerEsDeleted;
    FOnMediaPlayerEsSelected         : TNotifyMediaPlayerEsSelected;
    FOnMediaPlayerAudioDevice        : TNotifyMediaPlayerAudioDevice;
    FOnMediaPlayerChapterChanged     : TNotifyMediaPlayerChapterChanged;

    FOnRendererDiscoveredItemAdded   : TNotifyRendererDiscoveredItemAdded;
    FOnRendererDiscoveredItemDeleted : TNotifyRendererDiscoveredItemDeleted;

    FUseEvents    : boolean;
    FStartOptions : TStringList;

    function  GetVlcInstance() : TPasLibVlc;
    procedure SetStartOptions(Value: TStringList);

    procedure SetSnapshotFmt(aFormat: string);
    procedure SetSnapshotPrv(aValue : Boolean);

    procedure SetSpuShow(aValue: Boolean);
    procedure SetOsdShow(aValue: Boolean);
    procedure SetViewTeleText(aValue : Boolean);
    
    procedure SetTitleShow(aValue: Boolean);
    procedure SetTitleShowPos(aValue: TPasLibVlcTitlePosition);
    procedure SetTitleShowTimeOut(aValue: LongWord);

    procedure SetDeinterlaceFilter(aValue: TDeinterlaceFilter);
    procedure SetDeinterlaceMode(aValue: TDeinterlaceMode);
    function  GetDeinterlaceModeName(): WideString;

    procedure InternalHandleEvent_MediaChanged(p_md : libvlc_media_t_ptr);
    procedure InternalHandleEvent_NothingSpecial();
    procedure InternalHandleEvent_Opening();
    procedure InternalHandleEvent_Buffering();
    procedure InternalHandleEvent_Playing();
    procedure InternalHandleEvent_Paused();
    procedure InternalHandleEvent_Stopped();
    procedure InternalHandleEvent_Forward();
    procedure InternalHandleEvent_Backward();
    procedure InternalHandleEvent_EndReached();
    procedure InternalHandleEvent_EncounteredError();

    procedure InternalHandleEvent_TimeChanged(new_time : libvlc_time_t);
    procedure InternalHandleEvent_PositionChanged(new_position : Single);

    procedure InternalHandleEvent_SeekableChanged(new_seekable : Integer);
    procedure InternalHandleEvent_PausableChanged(new_pausable : Integer);
    procedure InternalHandleEvent_TitleChanged(new_title : Integer);
    procedure InternalHandleEvent_SnapshotTaken(psz_filename : PAnsiChar);

    procedure InternalHandleEvent_LengthChanged(new_length : libvlc_time_t);

    procedure InternalHandleEvent_VOutChanged(new_count : Integer);
    procedure InternalHandleEvent_ScrambledChanged(new_scrambled : Integer);

    procedure InternalHandleEvent_Corked();
    procedure InternalHandleEvent_UnCorked();
    procedure InternalHandleEvent_Muted();
    procedure InternalHandleEvent_UnMuted();
    procedure InternalHandleEvent_AudioVolumeChanged(volume : Single);

    procedure InternalHandleEvent_VideoSizeChanged(video_w, video_h, video_w_a32, video_h_a32 : LongWord);

    procedure InternalHandleEvent_MediaPlayerEsAdded           (i_type : libvlc_track_type_t; i_id : Integer);
    procedure InternalHandleEvent_MediaPlayerEsDeleted         (i_type : libvlc_track_type_t; i_id : Integer);
    procedure InternalHandleEvent_MediaPlayerEsSelected        (i_type : libvlc_track_type_t; i_id : Integer);
    procedure InternalHandleEvent_MediaPlayerAudioDevice       (audio_device : PAnsiChar);
    procedure InternalHandleEvent_MediaPlayerChapterChanged    (chapter : Integer);
    procedure InternalHandleEvent_RendererDiscoveredItemAdded  (item : libvlc_renderer_item_t_ptr);
    procedure InternalHandleEvent_RendererDiscoveredItemDeleted(item : libvlc_renderer_item_t_ptr);

  protected

    procedure DestroyPlayer();

    procedure Paint; override;

    procedure PlayContinue(audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000); overload;
    procedure PlayContinue(mediaOptions : array of WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000); overload;

  public

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetPlayerHandle(): libvlc_media_player_t_ptr;

    procedure Play       (var media : TPasLibVlcMedia; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000); overload;

    procedure Play       (mrl : WideString; mediaOptions : array of WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000); overload;
    procedure Play       (stm : TStream;    mediaOptions : array of WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000); overload;
    procedure PlayNormal (mrl : WideString; mediaOptions : array of WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000); overload;
    procedure PlayYoutube(mrl : WideString; mediaOptions : array of WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000; youtubeTimeout : Cardinal = 10000); overload;

    procedure Play       (mrl : WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000); overload;
    procedure Play       (stm : TStream;    audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000); overload;
    procedure PlayNormal (mrl : WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000); overload;
    procedure PlayYoutube(mrl : WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000; youtubeTimeout : Cardinal = 10000); overload;

    function  GetMediaMrl(): string;

    procedure Pause();
    procedure Resume();
    function  IsPlay(): Boolean;
    function  IsPause(): Boolean;
    procedure Stop(const stopTimeOut : Cardinal = 1000);

    function  GetState(): TFmxPasLibVlcPlayerState;
    function  GetStateName(): string;

    function  CanPlay(): Boolean;
    function  CanPause(): Boolean;
    function  CanSeek(): Boolean;

    function HasVout() : Boolean;
    function IsScrambled() : Boolean;

    function Snapshot(fileName: WideString): Boolean; overload;
    function Snapshot(fileName: WideString; width, height: LongWord): Boolean; overload;

    procedure NextFrame();

    procedure SetPlayRate(rate: Integer);
    function  GetPlayRate(): Integer;

    function  GetVideoWidth(): LongInt;
    function  GetVideoHeight(): LongInt;
    function  GetVideoDimension(var width, height: LongWord) : Boolean;
    function  GetVideoScaleInPercent(): Single;
    function  GetVideoAspectRatio(): string;
    function  GetVideoSampleAspectRatio(var sar_num, sar_den : Longword): Boolean; overload;
    function  GetVideoSampleAspectRatio(): Single; overload;

    procedure SetVideoScaleInPercent(newScaleInPercent: Single);
    procedure SetVideoAspectRatio(newAspectRatio: string);

    function  GetVideoLenInMs(): Int64;
    function  GetVideoPosInMs(): Int64;
    function  GetVideoPosInPercent(): Single;
    function  GetVideoFps(): Single;

    procedure SetVideoPosInMs(newPos: Int64);
    procedure SetVideoPosInPercent(newPos: Single);

    function GetVideoLenStr(fmt: string = 'hh:mm:ss'): string;
    function GetVideoPosStr(fmt: string = 'hh:mm:ss'): string;

    procedure SetTeleText(page: Integer);
    function  GetTeleText() : Integer;
    function  ShowTeleText() : Boolean;
    function  HideTeleText() : Boolean;

    function  GetAudioMute(): Boolean;
    procedure SetAudioMute(mute: Boolean);
    function  GetAudioVolume(): Integer;
    procedure SetAudioVolume(volumeLevel: Integer);

    function  GetAudioChannel(): libvlc_audio_output_channel_t;
    procedure SetAudioChannel(chanel: libvlc_audio_output_channel_t);

    function  GetAudioDelay(): Int64;
    procedure SetAudioDelay(delay: Int64);

    function  GetAudioFilterList(return_name_type : Integer = 0): TStringList;
    function  GetVideoFilterList(return_name_type : Integer = 0): TStringList;

    function  GetAudioTrackList(): TStringList;
    function  GetAudioTrackCount(): Integer;
    function  GetAudioTrackId(): Integer;
    procedure SetAudioTrackById(const track_id : Integer);
    function  GetAudioTrackNo(): Integer;
    procedure SetAudioTrackByNo(track_no : Integer);
    function  GetAudioTrackDescriptionById(const track_id : Integer): WideString;
    function  GetAudioTrackDescriptionByNo(track_no : Integer): WideString;

    function GetAudioOutputList(withDescription : Boolean = FALSE; separator : string = '|'): TStringList;
    function GetAudioOutputDeviceList(aOut : WideString; withDescription : Boolean = FALSE; separator : string = '|'): TStringList;
    function GetAudioOutputDeviceEnum(withDescription : Boolean = FALSE; separator : string = '|') : TStringList;

    function SetAudioOutput(aOut: WideString) : Boolean;
    procedure SetAudioOutputDevice(aOut: WideString; aOutDeviceId: WideString); overload;
    procedure SetAudioOutputDevice(aOutDeviceId: WideString); overload;

    {$IFDEF USE_VLC_DEPRECATED_API}
    function GetAudioOutputDeviceCount(aOut: WideString): Integer;
    function GetAudioOutputDeviceId(aOut: WideString; deviceIdx : Integer) : WideString;
    function GetAudioOutputDeviceName(aOut: WideString; deviceIdx : Integer): WideString;
    {$ENDIF}

    function EqualizerGetPresetList(): TStringList;
    function EqualizerGetBandCount(): unsigned_t;
    function EqualizerGetBandFrequency(bandIndex : unsigned_t): Single;

    function EqualizerCreate(APreset : unsigned_t = $FFFF) : TPasLibVlcEqualizer;
    procedure EqualizerApply(AEqualizer : TPasLibVlcEqualizer);
    procedure EqualizerSetPreset(APreset : unsigned_t = $FFFF);

    procedure SetVideoAdjustEnable(value : Boolean);
    function  GetVideoAdjustEnable(): Boolean;

    procedure SetVideoAdjustContrast(value : Single = 1);
    function  GetVideoAdjustContrast(): Single;

    procedure SetVideoAdjustBrightness(value : Single = 1);
    function  GetVideoAdjustBrightness(): Single;

    procedure SetVideoAdjustHue(value : Integer = 0);
    function  GetVideoAdjustHue(): Integer;

    procedure SetVideoAdjustSaturation(value : Single = 1);
    function  GetVideoAdjustSaturation(): Single;

    procedure SetVideoAdjustGamma(value : Single = 1);
    function  GetVideoAdjustGamma(): Single;

    function  GetVideoChapter(): Integer;
    procedure SetVideoChapter(newChapter: Integer);
    function  GetVideoChapterCount(): Integer;
    function  GetVideoChapterCountByTitleId(const title_id : Integer): Integer;

    function  GetVideoSubtitleList(): TStringList;
    function  GetVideoSubtitleCount(): Integer;
    function  GetVideoSubtitleId(): Integer;
    procedure SetVideoSubtitleById(const subtitle_id : Integer);
    function  GetVideoSubtitleNo(): Integer;
    procedure SetVideoSubtitleByNo(subtitle_no : Integer);
    function  GetVideoSubtitleDescriptionById(const subtitle_id : Integer): WideString;
    function  GetVideoSubtitleDescriptionByNo(subtitle_no : Integer): WideString;
    procedure SetVideoSubtitleFile(subtitle_file : WideString);

    function  GetVideoTitleList() : TStringList;
    function  GetVideoTitleCount(): Integer;
    function  GetVideoTitleId():Integer;
    procedure SetVideoTitleById(const title_id:Integer);
    function  GetVideoTitleNo(): Integer;
    procedure SetVideoTitleByNo(title_no : Integer);
    function  GetVideoTitleDescriptionById(const track_id : Integer): WideString;
    function  GetVideoTitleDescriptionByNo(title_no : Integer): WideString;

    // https://wiki.videolan.org/Documentation:Modules/logo/
    procedure LogoSetFile(file_name : WideString);
    procedure LogoSetFiles(file_names : array of WideString; delay_ms : Integer = 1000; loop : Boolean = TRUE);
    procedure LogoSetPosition(position_x, position_y : Integer); overload;
    procedure LogoSetPosition(position : libvlc_position_t); overload;
    procedure LogoSetOpacity(opacity : libvlc_opacity_t);
    procedure LogoSetDelay(delay_ms : Integer = 1000);  // delay before show next logo file, default 1000
    procedure LogoSetRepeat(loop : boolean = TRUE);
    procedure LogoSetEnable(enable : Integer);
    
    procedure LogoShowFile(file_name : WideString; position_x, position_y : Integer; opacity: libvlc_opacity_t = libvlc_opacity_full); overload;
    procedure LogoShowFile(file_name : WideString; position: libvlc_position_t = libvlc_position_top; opacity: libvlc_opacity_t = libvlc_opacity_full); overload;
    procedure LogoShowFiles(file_names : array of WideString; position_x, position_y : Integer; opacity: libvlc_opacity_t = libvlc_opacity_full; delay_ms : Integer = 1000; loop : Boolean = TRUE); overload;
    procedure LogoShowFiles(file_names : array of WideString; position: libvlc_position_t = libvlc_position_top; opacity: libvlc_opacity_t = libvlc_opacity_full; delay_ms : Integer = 1000; loop : Boolean = TRUE); overload;
    procedure LogoHide();

    // https://wiki.videolan.org/Documentation:Modules/marq/
    procedure MarqueeSetText(marquee_text : WideString);
    procedure MarqueeSetPosition(position_x, position_y : Integer); overload;
    procedure MarqueeSetPosition(position : libvlc_position_t); overload;
    procedure MarqueeSetColor(color : libvlc_video_marquee_color_t);
    procedure MarqueeSetFontSize(font_size: Integer);
    procedure MarqueeSetOpacity(opacity: libvlc_opacity_t);
    procedure MarqueeSetTimeOut(time_out_ms: Integer);
    procedure MarqueeSetRefresh(refresh_after_ms: Integer);
    procedure MarqueeSetEnable(enable : Integer);

    procedure MarqueeShowText(marquee_text : WideString; position_x, position_y : Integer; color : libvlc_video_marquee_color_t = libvlc_video_marquee_color_White; font_size: Integer = libvlc_video_marquee_default_font_size; opacity: libvlc_opacity_t = libvlc_opacity_full; time_out_ms: Integer = 0); overload;
    procedure MarqueeShowText(marquee_text : WideString; position : libvlc_position_t = libvlc_position_bottom; color : libvlc_video_marquee_color_t = libvlc_video_marquee_color_White; font_size: Integer = libvlc_video_marquee_default_font_size; opacity: libvlc_opacity_t = libvlc_opacity_full; time_out_ms: Integer = 0); overload;
    procedure MarqueeHide();

    procedure EventsDisable();
    procedure EventsEnable();

    procedure UpdateDeInterlace();
    procedure UpdateTitleShow();

    property  VLC : TPasLibVlc read GetVlcInstance;
    
  published
  
    property Align;

    property PopupMenu;
    property ShowHint;
    property Visible;
    property OnClick;

    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;

    property SpuShow : Boolean
      read    FSpuShow
      write   SetSpuShow
      default TRUE;

    property OsdShow : Boolean
      read    FOsdShow
      write   SetOsdShow
      default TRUE;

    property TitleShow : Boolean
      read    FTitleShow
      write   SetTitleShow
      default FALSE;

    property TitleShowPos : TPasLibVlcTitlePosition
      read FTitleShowPos
      write SetTitleShowPos
      default plvPosCenter;

    property TitleShowTimeOut : LongWord
      read FTitleShowTimeOut
      write SetTitleShowTimeOut
      default 2000;

    property AudioOutput : TAudioOutput
      read FAudioOutput
      write FAudioOutput
      default aoDefault;

    property SnapShotFmt : string
      read    FSnapShotFmt
      write   SetSnapshotFmt;

    property SnapshotPrv : Boolean
      read    FSnapShotPrv
      write   SetSnapshotPrv
      default FALSE;

    property DeinterlaceFilter : TDeinterlaceFilter
      read    FDeinterlaceFilter
      write   SetDeinterlaceFilter
      default deOFF;

    property DeinterlaceModeName:  WideString
      read    GetDeinterlaceModeName;

    property DeinterlaceMode : TDeinterlaceMode
      read    FDeinterlaceMode
      write   SetDeinterlaceMode
      default dmDISCARD;

    property ViewTeletext : Boolean
      read    FViewTeleText
      write   SetViewTeleText
      default FALSE;

    property LastError: string
      read   FError
      write  FError;

    property StartOptions : TStringList
      read FStartOptions
      write SetStartOptions;

    property OnMediaPlayerEvent	: TNotifyPlayerEvent
      read FOnMediaPlayerEvent
      write FOnMediaPlayerEvent;

    property OnMediaPlayerMediaChanged : TNotifyMediaChanged
      read  FOnMediaPlayerMediaChanged
      write FOnMediaPlayerMediaChanged;

    property OnMediaPlayerNothingSpecial : TNotifyEvent
      read  FOnMediaPlayerNothingSpecial
      write FOnMediaPlayerNothingSpecial;

    property OnMediaPlayerOpening : TNotifyEvent
      read  FOnMediaPlayerOpening
      write FOnMediaPlayerOpening;

    property OnMediaPlayerBuffering : TNotifyEvent
      read  FOnMediaPlayerBuffering
      write FOnMediaPlayerBuffering;

    property OnMediaPlayerPlaying : TNotifyEvent
      read  FOnMediaPlayerPlaying
      write FOnMediaPlayerPlaying;

    property OnMediaPlayerPaused : TNotifyEvent
      read  FOnMediaPlayerPaused
      write FOnMediaPlayerPaused;

    property OnMediaPlayerStopped : TNotifyEvent
      read  FOnMediaPlayerStopped
      write FOnMediaPlayerStopped;

    property OnMediaPlayerForward : TNotifyEvent
      read  FOnMediaPlayerForward
      write FOnMediaPlayerForward;

    property OnMediaPlayerBackward : TNotifyEvent
      read  FOnMediaPlayerBackward
      write FOnMediaPlayerBackward;

    property OnMediaPlayerEndReached : TNotifyEvent
      read  FOnMediaPlayerEndReached
      write FOnMediaPlayerEndReached;

    property OnMediaPlayerEncounteredError : TNotifyEvent
      read  FOnMediaPlayerEncounteredError
      write FOnMediaPlayerEncounteredError;

    property OnMediaPlayerTimeChanged : TNotifyTimeChanged
      read  FOnMediaPlayerTimeChanged
      write FOnMediaPlayerTimeChanged;

    property OnMediaPlayerPositionChanged : TNotifyPositionChanged
      read  FOnMediaPlayerPositionChanged
      write FOnMediaPlayerPositionChanged;

    property OnMediaPlayerSeekableChanged : TNotifySeekableChanged
      read  FOnMediaPlayerSeekableChanged
      write FOnMediaPlayerSeekableChanged;

    property OnMediaPlayerPausableChanged : TNotifyPausableChanged
      read  FOnMediaPlayerPausableChanged
      write FOnMediaPlayerPausableChanged;

    property OnMediaPlayerTitleChanged : TNotifyTitleChanged
      read  FOnMediaPlayerTitleChanged
      write FOnMediaPlayerTitleChanged;

    property OnMediaPlayerSnapshotTaken : TNotifySnapshotTaken
      read  FOnMediaPlayerSnapshotTaken
      write FOnMediaPlayerSnapshotTaken;

    property OnMediaPlayerLengthChanged : TNotifyLengthChanged
      read  FOnMediaPlayerLengthChanged
      write FOnMediaPlayerLengthChanged;

    property OnMediaPlayerVideoOutChanged : TNotifyVideoOutChanged
      read  FOnMediaPlayerVideoOutChanged
      write FOnMediaPlayerVideoOutChanged;

    property OnMediaPlayerScrambledChanged : TNotifyScrambledChanged
      read  FOnMediaPlayerScrambledChanged
      write FOnMediaPlayerScrambledChanged;

    property OnMediaPlayerCorked : TNotifyEvent
      read  FOnMediaPlayerCorked
      write FOnMediaPlayerCorked;

    property OnMediaPlayerUnCorked : TNotifyEvent
      read  FOnMediaPlayerUnCorked
      write FOnMediaPlayerUnCorked;

    property OnMediaPlayerMuted : TNotifyEvent
      read  FOnMediaPlayerMuted
      write FOnMediaPlayerMuted;

    property OnMediaPlayerUnMuted : TNotifyEvent
      read  FOnMediaPlayerUnMuted
      write FOnMediaPlayerUnMuted;

    property OnMediaPlayerAudioVolumeChanged : TNotifyAudioVolumeChanged
      read  FOnMediaPlayerAudioVolumeChanged
      write FOnMediaPlayerAudioVolumeChanged;

    property OnMediaPlayerVideoSizeChanged : TNotifyVideoSizeChanged
      read  FOnMediaPlayerVideoSizeChanged
      write FOnMediaPlayerVideoSizeChanged;

    property OnMediaPlayerEsAdded : TNotifyMediaPlayerEsAdded
      read  FOnMediaPlayerEsAdded
      write FOnMediaPlayerEsAdded;

    property OnMediaPlayerEsDeleted : TNotifyMediaPlayerEsDeleted
      read  FOnMediaPlayerEsDeleted
      write FOnMediaPlayerEsDeleted;

    property OnMediaPlayerEsSelected : TNotifyMediaPlayerEsSelected
      read  FOnMediaPlayerEsSelected
      write FOnMediaPlayerEsSelected;

    property OnMediaPlayerAudioDevice : TNotifyMediaPlayerAudioDevice
      read   FOnMediaPlayerAudioDevice
      write FOnMediaPlayerAudioDevice;

    property OnMediaPlayerChapterChanged : TNotifyMediaPlayerChapterChanged
      read  FOnMediaPlayerChapterChanged
      write FOnMediaPlayerChapterChanged;

    property OnRendererDiscoveredItemAdded : TNotifyRendererDiscoveredItemAdded
      read  FOnRendererDiscoveredItemAdded
      write FOnRendererDiscoveredItemAdded;

    property OnRendererDiscoveredItemDeleted : TNotifyRendererDiscoveredItemDeleted
      read  FOnRendererDiscoveredItemDeleted
      write FOnRendererDiscoveredItemDeleted;

    property UseEvents : boolean
      read FUseEvents
      write FUseEvents default TRUE;

    property
      LastAudioOutput : WideString
      read FLastAudioOutput;

    property
      LastAudioOutputDeviceId : WideString
      read FLastAudioOutputDeviceId;
  end;

procedure Register;


implementation

{$R *.RES}

{$IFDEF DELPHI_XE6_UP}
uses
	System.AnsiStrings;
{$ENDIF}

procedure Register;
begin
  RegisterComponents('FmxPasLibVlc', [TFmxPasLibVlcPlayer]);
end;

////////////////////////////////////////////////////////////////////////////////

procedure fmx_lib_vlc_player_event_hdlr(p_event: libvlc_event_t_ptr; data: Pointer); cdecl; forward;

function  fmx_libvlc_video_lock_cb(ptr : Pointer; planes : PVCBPlanes) : Pointer; cdecl; forward;
procedure fmx_libvlc_video_unlock_cb(ptr : Pointer; picture : Pointer; planes : PVCBPlanes); cdecl; forward;
procedure fmx_libvlc_video_display_cb(ptr : Pointer; picture : Pointer); cdecl; forward;
function  fmx_libvlc_video_format_cb(var ptr : Pointer; chroma : PAnsiChar; var width : LongWord; var height : LongWord; pitches : PVCBPitches; lines : PVCBLines) : LongWord; cdecl; forward;
procedure fmx_libvlc_video_cleanup_cb(ptr : Pointer); cdecl; forward;

////////////////////////////////////////////////////////////////////////////////

constructor TFmxPasLibVlcPlayer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Width      := 320;
  Height     := 240;

  FAudioOutput := aoDefault;

  FLastAudioOutput := '';
  FLastAudioOutputDeviceId := '';

  FTitleShow        := FALSE;
  FTitleShowPos     := plvPosCenter;
  FTitleShowTimeOut := 2000;

  FSnapshotFmt  := 'png';
  FSnapShotPrv  := FALSE;

  FSpuShow      := TRUE;
  FOsdShow      := TRUE;

  FViewTeleText := FALSE;

  p_mi          := NIL;
  p_mi_ev_mgr   := NIL;
  FMute         := FALSE;
  FVLC          := NIL;
  p_mi          := NIL;

  FUseEvents    := TRUE;

  FStartOptions := TStringList.Create;

  FVideoCbCtx   := TFmxPasLibVlcVideoCbCtx.Create(SELF);

  // if (csDesigning in ComponentState) then exit;
end;

procedure TFmxPasLibVlcPlayer.DestroyPlayer();
begin
  EventsDisable();
  Sleep(50);

  if (p_mi <> NIL) then
  begin

    libvlc_video_set_callbacks(p_mi, NIL, NIL, NIL, NIL);
    libvlc_video_set_format_callbacks(p_mi, NIL, NIL);

    Stop();

    libvlc_media_player_release(p_mi);

    p_mi := NIL;
  end;

  Sleep(50);
end;

destructor TFmxPasLibVlcPlayer.Destroy;
begin
  DestroyPlayer();

  if Assigned(FVLC) then
  begin
    FreeAndNil(FVLC);
  end;

  FreeAndNil(FVideoCbCtx);

  FreeAndNil(FStartOptions);

  inherited Destroy;
end;

procedure TFmxPasLibVlcPlayer.EventsEnable();
begin

  EventsDisable();
  
  if (p_mi <> NIL) then
  begin
    p_mi_ev_mgr := libvlc_media_player_event_manager(p_mi);

    if Assigned(p_mi_ev_mgr) then
    begin
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerMediaChanged,       fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerNothingSpecial,     fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerOpening,            fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerBuffering,          fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerPlaying,            fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerPaused,             fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerStopped,            fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerForward,            fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerBackward,           fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerEndReached,         fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerEncounteredError,   fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerTimeChanged,        fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerPositionChanged,    fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerSeekableChanged,    fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerPausableChanged,    fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerTitleChanged,       fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerSnapshotTaken,      fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerLengthChanged,      fmx_lib_vlc_player_event_hdlr, SELF);

      // availiable from 2.2.0
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerVout,               fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerScrambledChanged,   fmx_lib_vlc_player_event_hdlr, SELF);

      // availiable from 2.2.2
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerCorked,             fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerUncorked,           fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerMuted,              fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerUnmuted,            fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerAudioVolume,        fmx_lib_vlc_player_event_hdlr, SELF);

      // availiable from 3.0.0
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerESAdded,            fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerESDeleted,          fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerESSelected,         fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerAudioDevice,        fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_MediaPlayerChapterChanged,     fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_RendererDiscovererItemAdded,   fmx_lib_vlc_player_event_hdlr, SELF);
      libvlc_event_attach(p_mi_ev_mgr, libvlc_RendererDiscovererItemDeleted, fmx_lib_vlc_player_event_hdlr, SELF);
    end;
  end;
end;

procedure TFmxPasLibVlcPlayer.EventsDisable();
begin
  if Assigned(p_mi_ev_mgr) then
  begin
    libvlc_event_detach(p_mi_ev_mgr, libvlc_RendererDiscovererItemDeleted, fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_RendererDiscovererItemAdded,   fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerChapterChanged,     fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerAudioDevice,        fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerESSelected,         fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerESDeleted,          fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerESAdded,            fmx_lib_vlc_player_event_hdlr, SELF);

    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerAudioVolume,      fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerUnmuted,          fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerMuted,            fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerUncorked,         fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerCorked,           fmx_lib_vlc_player_event_hdlr, SELF);

    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerScrambledChanged, fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerVout,             fmx_lib_vlc_player_event_hdlr, SELF);

    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerLengthChanged,    fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerSnapshotTaken,    fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerTitleChanged,     fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerPausableChanged,  fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerSeekableChanged,  fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerPositionChanged,  fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerTimeChanged,      fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerEncounteredError, fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerEndReached,       fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerBackward,         fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerForward,          fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerStopped,          fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerPaused,           fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerPlaying,          fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerBuffering,        fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerOpening,          fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerNothingSpecial,   fmx_lib_vlc_player_event_hdlr, SELF);
    libvlc_event_detach(p_mi_ev_mgr, libvlc_MediaPlayerMediaChanged,     fmx_lib_vlc_player_event_hdlr, SELF);

    p_mi_ev_mgr := NIL;
  end;
end;

procedure TFmxPasLibVlcPlayer.SetSnapshotFmt(aFormat: string);
begin
  FSnapShotFmt := 'png';
  aFormat := AnsiLowerCase(aFormat);
  if ((aFormat = 'png') or (aFormat = 'jpg')) then
  begin
    FSnapShotFmt := aFormat;
  end;
end;

procedure TFmxPasLibVlcPlayer.SetSnapshotPrv(aValue: Boolean);
begin
  if (FSnapshotPrv <> aValue) then
  begin
    FSnapshotPrv := aValue;
  end;
end;

procedure TFmxPasLibVlcPlayer.SetSpuShow(aValue: Boolean);
begin
  if (FSpuShow <> aValue) then
  begin
    FSpuShow := aValue;
  end;
end;

procedure TFmxPasLibVlcPlayer.SetOsdShow(aValue: Boolean);
begin
  if (FOsdShow <> aValue) then
  begin
    FOsdShow := aValue;
  end;
end;

procedure TFmxPasLibVlcPlayer.UpdateTitleShow();
begin
  if (p_mi <> NIL) and (VLC.VersionBin >= $020100) then
  begin
    if FTitleShow then
    begin
      case FTitleShowPos of
        plvPosCenter:      libvlc_media_player_set_video_title_display(p_mi, libvlc_position_center,       FTitleShowTimeOut);
        plvPosLeft:        libvlc_media_player_set_video_title_display(p_mi, libvlc_position_left,         FTitleShowTimeOut);
        plvPosRight:       libvlc_media_player_set_video_title_display(p_mi, libvlc_position_right,        FTitleShowTimeOut);
        plvPosTop:         libvlc_media_player_set_video_title_display(p_mi, libvlc_position_top,          FTitleShowTimeOut);
        plvPosTopLeft:     libvlc_media_player_set_video_title_display(p_mi, libvlc_position_top_left,     FTitleShowTimeOut);
        plvPosTopRight:    libvlc_media_player_set_video_title_display(p_mi, libvlc_position_top_right,    FTitleShowTimeOut);
        plvPosBottom:      libvlc_media_player_set_video_title_display(p_mi, libvlc_position_bottom,       FTitleShowTimeOut);
        plvPosBottomLeft:  libvlc_media_player_set_video_title_display(p_mi, libvlc_position_bottom_left,  FTitleShowTimeOut);
        plvPosBottomRight: libvlc_media_player_set_video_title_display(p_mi, libvlc_position_bottom_right, FTitleShowTimeOut);
      end;
    end
    else
    begin
      libvlc_media_player_set_video_title_display(p_mi, libvlc_position_disable, FTitleShowTimeOut);
    end;
  end;
end;

procedure TFmxPasLibVlcPlayer.SetTitleShow(aValue: Boolean);
begin
  if (FTitleShow <> aValue) then
  begin
    FTitleShow := aValue;
    UpdateTitleShow();
  end;
end;

procedure TFmxPasLibVlcPlayer.SetTitleShowPos(aValue: TPasLibVlcTitlePosition);
begin
  if (FTitleShowPos <> aValue) then
  begin
    FTitleShowPos := aValue;
    UpdateTitleShow();
  end;
end;

procedure TFmxPasLibVlcPlayer.SetTitleShowTimeOut(aValue: LongWord);
begin
  if (FTitleShowTimeOut <> aValue) then
  begin
    FTitleShowTimeOut := aValue;
    UpdateTitleShow();
  end;
end;

procedure TFmxPasLibVlcPlayer.SetViewTeleText(aValue : Boolean);
begin
  if (FViewTeleText <> aValue) then
  begin
    if aValue then ShowTeleText() else HideTeleText();
  end;
end;

procedure TFmxPasLibVlcPlayer.UpdateDeInterlace();
var
  dm: string;
begin
  if (p_mi = NIL) then exit;

  if (FDeinterlaceFilter = deON) then
  begin
    dm := vlcDeinterlaceModeNames[FDeinterlaceMode];
  end
  else
  begin
    dm := '';
  end;

  if (dm <> '') then
  begin
    libvlc_video_set_deinterlace(p_mi, PAnsiChar(Utf8Encode(dm)));
  end
  else
  begin
    libvlc_video_set_deinterlace(p_mi, NIL);
  end;
end;

function TFmxPasLibVlcPlayer.GetDeinterlaceModeName(): WideString;
begin
  Result := vlcDeinterlaceModeNames[FDeinterlaceMode];
end;

procedure TFmxPasLibVlcPlayer.SetDeinterlaceFilter(aValue: TDeinterlaceFilter);
begin
  if (FDeinterlaceFilter <> aValue) then
  begin
    FDeinterlaceFilter := aValue;
    UpdateDeInterlace();
  end;
end;

procedure TFmxPasLibVlcPlayer.SetDeinterlaceMode(aValue: TDeinterlaceMode);
begin
  if (FDeinterlaceMode <> aValue) then
  begin
    FDeinterlaceMode := aValue;
    UpdateDeInterlace();
  end;
end;

function TFmxPasLibVlcPlayer.GetVlcInstance() : TPasLibVlc;
var
  oIdx : Integer;
begin
  if not Assigned(FVLC) then
  begin
    FVLC := TPasLibVlc.Create;

    for oIdx := 0 to FStartOptions.Count - 1 do
    begin
      FVLC.AddOption(FStartOptions.Strings[oIdx]);
    end;

    FVLC.AddOption('--drop-late-frames');

    // for versions before 2.1.0
    FVLC.TitleShow := FTitleShow;

    if not FSpuShow     then FVLC.AddOption('--no-spu')              else FVLC.AddOption('--spu');
    if not FOsdShow     then FVLC.AddOption('--no-osd')              else FVLC.AddOption('--osd');
    if not FSnapshotPrv then FVLC.AddOption('--no-snapshot-preview') else FVLC.AddOption('--snapshot-preview');

    if (FAudioOutput <> aoDefault) then FVLC.AddOption('--aout=' + vlcAudioOutputNames[FAudioOutput]);
  end;
  Result := FVLC;
end;

procedure TFmxPasLibVlcPlayer.SetStartOptions(Value: TStringList);
begin
  FStartOptions.Assign(Value);
end;

function TFmxPasLibVlcPlayer.GetPlayerHandle(): libvlc_media_player_t_ptr;
var
   p_instance : libvlc_instance_t_ptr;
begin
  
  if (p_mi = NIL) then
  begin
    // get instance
    p_instance := VLC.Handle;

    if (p_instance <> NIL) then
    begin
      // create media player
      p_mi := libvlc_media_player_new(p_instance);

      // handling mouse events by vlc ???
      if (p_mi <> NIL) then
      begin
//        libvlc_video_set_mouse_input(p_mi, 1);
//        libvlc_video_set_key_input(p_mi, 1);

        libvlc_video_set_callbacks(
          p_mi,
          fmx_libvlc_video_lock_cb,
          fmx_libvlc_video_unlock_cb,
          fmx_libvlc_video_display_cb,
          Pointer(FVideoCbCtx)
        );

        libvlc_video_set_format_callbacks(
          p_mi,
          fmx_libvlc_video_format_cb,
          fmx_libvlc_video_cleanup_cb
        );
      end;

//      libvlc_video_set_format(p_mi, 'RV32', 640, 480, 640 * 4);
//
//      with context do
//      begin
//        video_w := 640;
//        video_h := 480;
//        pitch_w := video_w * FMX.Types.PixelFormatBytes[TPixelFormat.BGRA];
//
//        (*
//         * Furthermore, we recommend that pitches and lines be multiple of 32
//         * to not break assumption that might be made by various optimizations
//         * in the video decoders, video filters and/or video converters.
//         *)
//        video_w_a32 := (((640  + 31) shr 5) shl 5);
//        video_h_a32 := (((640 + 31) shr 5) shl 5);
//        pitch_w_a32 := video_w_a32 * FMX.Types.PixelFormatBytes[TPixelFormat.BGRA];
//
//        if (buff <> NIL) then
//        begin
//          FreeMem(buff);
//          buff_size := 0;
//        end;
//        buff_size := video_w_a32 * pitch_w_a32 + 32;
//        GetMem(buff, buff_size);
//        buff_a32 := Pointer(((NativeInt(buff) + 31) shr 5) shl 5);
//
//        bmpi.SetSize(640, 480);
//
//        (view as TFmxPasLibVlcPlayer).Bitmap.Assign(bmpi);
//      end;

    end;

  end;

  UpdateTitleShow();

  if FUseEvents then
  begin
    EventsEnable();
  end;

  Result := p_mi;
end;

function GetToSep(var str : WideString; sep : WideString) : WideString;
var
  p : Integer;
begin
  p := Pos(sep, str);
  if (p > 0) then
  begin
    Result := Copy(str, 1, p - 1);
    Delete(str, 1, p - 1 + Length(sep));
  end
  else
  begin
    Result := str;
    str := '';
  end;
end;

procedure TFmxPasLibVlcPlayer.Play(var media : TPasLibVlcMedia; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000);
begin
  // assign media to player
  libvlc_media_player_set_media(p_mi, media.MD);

  // play
  libvlc_media_player_play(p_mi);

  // release media
  media.Free;
  media := NIL;

  UpdateTitleShow();

  if ((audioOutput <> '') or (audioOutputDeviceId <> '')) then
  begin
    while (libvlc_media_player_is_playing(p_mi) = 0) do
    begin
      Sleep(10);
      if (audioSetTimeOut < 10) then break;
      Dec(audioSetTimeOut, 10);
    end;
    SetAudioOutputDevice(audioOutput, audioOutputDeviceId);
  end
  else
  if ((FLastAudioOutput <> '') or (FLastAudioOutputDeviceId <> '')) then
  begin
    while (libvlc_media_player_is_playing(p_mi) = 0) do
    begin
      Sleep(10);
      if (audioSetTimeOut < 10) then break;
      Dec(audioSetTimeOut, 10);
    end;
    SetAudioOutputDevice(FLastAudioOutput, FLastAudioOutputDeviceId);
  end;

  FMute := FALSE;
end;

(*
 * mrl - media resource location
 *
 * This can be file: c:\movie.avi
 *              ulr: http://host/movie.avi
 *              rtp: rstp://host/movie
 *)

procedure TFmxPasLibVlcPlayer.Play(mrl : WideString; mediaOptions : array of WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000);
var
  lcMRL : WideString;
  proto : WideString;
  host  : WideString;
begin
  lcMRL := Trim(LowerCase(mrl));

  // get media protocol, http, rtp, file, etc.
  proto := GetToSep(lcMRL, '://');

  if (proto = 'http') or (proto = 'https') then
  begin
    host  := GetToSep(lcMRL, '/');
    if (host = 'youtube.com') or (host = 'www.youtube.com') then
    begin
      PlayYoutube(mrl, mediaOptions, audioOutput, audioOutputDeviceId);
      exit;
    end;
  end;

  PlayNormal(mrl, mediaOptions, audioOutput, audioOutputDeviceId, audioSetTimeOut);
end;

procedure TFmxPasLibVlcPlayer.Play(stm : TStream; mediaOptions : array of WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000);
var
  media : TPasLibVlcMedia;
  mediaOptionIdx : Integer;
begin
  GetPlayerHandle();

  if (p_mi = NIL) then exit;

  Stop();

  // create media
  media := TPasLibVlcMedia.Create(VLC, stm);
  media.SetDeinterlaceFilter(FDeinterlaceFilter);
  media.SetDeinterlaceFilterMode(FDeinterlaceMode);

  for mediaOptionIdx := Low(mediaOptions) to High(mediaOptions) do
  begin
    media.AddOption(mediaOptions[mediaOptionIdx]);
  end;

  Play(media, audioOutput, audioOutputDeviceId, audioSetTimeOut);
end;

procedure TFmxPasLibVlcPlayer.PlayNormal(mrl : WideString; mediaOptions : array of WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000);
var
  media : TPasLibVlcMedia;
  mediaOptionsIdx : Integer;
begin
  GetPlayerHandle();

  if (p_mi = NIL) then exit;

  // create media
  media := TPasLibVlcMedia.Create(VLC, mrl);
  media.SetDeinterlaceFilter(FDeinterlaceFilter);
  media.SetDeinterlaceFilterMode(FDeinterlaceMode);

  for mediaOptionsIdx := Low(mediaOptions) to High(mediaOptions) do
  begin
    media.AddOption(mediaOptions[mediaOptionsIdx]);
  end;

  Play(media, audioOutput, audioOutputDeviceId, audioSetTimeOut);
end;

procedure TFmxPasLibVlcPlayer.PlayYoutube(mrl : WideString; mediaOptions : array of WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000; youtubeTimeout: Cardinal = 10000);
begin
  // http://www.youtube.com/watch?feature=player_detailpage&v=ZHHOYmERmDc
  PlayNormal(mrl, mediaOptions, audioOutput, audioOutputDeviceId, audioSetTimeOut);

  // wait for media switch, for example
  while (youtubeTimeout > 0) do
  begin
    Sleep(10);
    if (youtubeTimeout < 10) then break;
    Dec(youtubeTimeout, 10);
    if (GetState() = plvPlayer_Ended) then
    begin
      // if media ended, then check subitem list and
      // try continue play with first subitem mrl
      // for example:
      // http://r2---sn-4g57kn6z.googlevideo.com/videoplayback?sver=3&ipbits=0&itag=22&ip=83.31.142.43&sparams=id%2Cip%2Cipbits%2Citag%2Cratebypass%2Csource%2Cupn%2Cexpire&fexp=900064%2C902408%2C924222%2C930008%2C934030%2C946020&upn=PPuY3_P4Og8&mv=m&ms=au&id=o-ANEBC2i5aojuRlQK5Kj-nfzUUQQbvGvG3MI2udImzhm9&mws=yes&key=yt5&signature=80D290D0D7957DBC3013E7A225B64B0AE7A561CA.EE07EA42ACCCF387DACA6FF59D81135E823ED161&mt=1403761633&expire=1403784000&ratebypass=yes&source=youtube
      PlayContinue(mediaOptions, audioOutput, audioOutputDeviceId, audioSetTimeOut);
      break;
    end;
  end;
end;

procedure TFmxPasLibVlcPlayer.PlayContinue(mediaOptions : array of WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000);
var
  p_md     : libvlc_media_t_ptr;
  p_ml     : libvlc_media_list_t_ptr;
  sub_p_md : libvlc_media_t_ptr;
  cnt      : Integer;
  mrl      : String;
begin
  mrl := '';

  if (p_mi = NIL) then exit;

  p_md := libvlc_media_player_get_media(p_mi);
  if (p_md <> NIL) then
  begin
    p_ml := libvlc_media_subitems(p_md);
    if (p_ml <> NIL) then
    begin
      libvlc_media_list_lock(p_ml);
      cnt := libvlc_media_list_count(p_ml);
      if (cnt > 0) then
      begin
        sub_p_md := libvlc_media_list_item_at_index(p_ml, 0);
        mrl := UTF8ToWideString(libvlc_media_get_mrl(sub_p_md));
        libvlc_media_release(sub_p_md);
      end;
      libvlc_media_list_unlock(p_ml);
      libvlc_media_list_release(p_ml);
    end;
    // libvlc_media_release(p_md);
  end;

  if (mrl <> '') then Play(mrl, mediaOptions, audioOutput, audioOutputDeviceId, audioSetTimeOut);
end;

(*
 * mrl - media resource location
 *
 * This can be file: c:\movie.avi
 *              ulr: http://host/movie.avi
 *              rtp: rstp://host/movie
 *)

procedure TFmxPasLibVlcPlayer.Play(mrl : WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000);
begin
  Play(mrl, [], audioOutput, audioOutputDeviceId, audioSetTimeOut);
end;

procedure TFmxPasLibVlcPlayer.Play(stm : TStream; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000);
begin
  Play(stm, [], audioOutput, audioOutputDeviceId, audioSetTimeOut);
end;

procedure TFmxPasLibVlcPlayer.PlayNormal(mrl : WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000);
begin
  PlayNormal(mrl, [], audioOutput, audioOutputDeviceId, audioSetTimeOut);
end;

procedure TFmxPasLibVlcPlayer.PlayYoutube(mrl : WideString; audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000; youtubeTimeout : Cardinal = 10000);
begin
  PlayYoutube(mrl, [], audioOutput, audioOutputDeviceId, audioSetTimeOut, youtubeTimeout);
end;

procedure TFmxPasLibVlcPlayer.PlayContinue(audioOutput : WideString = ''; audioOutputDeviceId : WideString = ''; audioSetTimeOut : Cardinal = 1000);
begin
  PlayContinue([], audioOutput, audioOutputDeviceId, audioSetTimeOut);
end;

function TFmxPasLibVlcPlayer.GetMediaMrl(): string;
var
  p_md     : libvlc_media_t_ptr;
  p_ml     : libvlc_media_list_t_ptr;
  sub_p_md : libvlc_media_t_ptr;
  cnt      : Integer;
begin
  if (p_mi = NIL) then exit;

  p_md := libvlc_media_player_get_media(p_mi);
  if (p_md <> NIL) then
  begin
    p_ml := libvlc_media_subitems(p_md);
    if (p_ml <> NIL) then
    begin
      libvlc_media_list_lock(p_ml);
      cnt := libvlc_media_list_count(p_ml);
      if (cnt > 0) then
      begin
        sub_p_md := libvlc_media_list_item_at_index(p_ml, 0);
        Result := UTF8ToWideString(libvlc_media_get_mrl(sub_p_md));
        libvlc_media_release(sub_p_md);
      end;
      libvlc_media_list_unlock(p_ml);
      libvlc_media_list_release(p_ml);
    end
    else
    begin
      Result := UTF8ToWideString(libvlc_media_get_mrl(p_md));
    end;
    libvlc_media_release(p_md);
  end;
end;

procedure TFmxPasLibVlcPlayer.Pause();
begin
  if (p_mi = NIL) then exit;

  if (GetState() = plvPlayer_Playing) then
  begin
    libvlc_media_player_pause(p_mi);
  end;
end;

procedure TFmxPasLibVlcPlayer.Resume();
begin
  if (p_mi = NIL) then exit;

  if (GetState() = plvPlayer_Paused)  then
  begin
    libvlc_media_player_play(p_mi);
  end;
end;

function TFmxPasLibVlcPlayer.IsPlay(): Boolean;
begin
  Result := (GetState() = plvPlayer_Playing);
end;

function TFmxPasLibVlcPlayer.IsPause(): Boolean;
begin
  Result := (GetState() = plvPlayer_Paused);
end;

procedure TFmxPasLibVlcPlayer.Stop(const stopTimeOut : Cardinal = 1000);
const
  TIME_STEP = 50;
var
  timeElapsed : Cardinal;
begin
  Pause();
  if IsPlay() then
  begin
    libvlc_media_player_stop(p_mi);
    Sleep(TIME_STEP);
    timeElapsed := TIME_STEP;
    while IsPlay() do
    begin
      if (timeElapsed > stopTimeOut) then break;
      Sleep(TIME_STEP);
      Inc(timeElapsed, TIME_STEP);
    end;
  end;
end;

function TFmxPasLibVlcPlayer.GetState(): TFmxPasLibVlcPlayerState;
begin
  Result := plvPlayer_NothingSpecial;

  if (p_mi = NIL) then exit;
  
  case libvlc_media_player_get_state(p_mi) of
    libvlc_NothingSpecial: Result := plvPlayer_NothingSpecial;
    libvlc_Opening:        Result := plvPlayer_Opening;
    libvlc_Buffering:      Result := plvPlayer_Buffering;
    libvlc_Playing:        Result := plvPlayer_Playing;
    libvlc_Paused:         Result := plvPlayer_Paused;
    libvlc_Stopped:        Result := plvPlayer_Stopped;
    libvlc_Ended:          Result := plvPlayer_Ended;
    libvlc_Error:          Result := plvPlayer_Error;
  end;
end;

function TFmxPasLibVlcPlayer.GetStateName(): string;
begin
  if (p_mi <> NIL) then
  begin
    case GetState of
      plvPlayer_NothingSpecial: Result := 'Nothing Special';
      plvPlayer_Opening:        Result := 'Opening';
      plvPlayer_Buffering:      Result := 'Buffering';
      plvPlayer_Playing:        Result := 'Playing';
      plvPlayer_Paused:         Result := 'Paused';
      plvPlayer_Stopped:        Result := 'Stopped';
      plvPlayer_Ended:          Result := 'Ended';
      plvPlayer_Error:          Result := 'Error';
      else                      Result := 'Invalid State';
    end;
  end
  else Result := 'Player not initialised';
end;

(*
 * Get current video width in pixels
 * If autoscale (scale = 0) then return original video width
 * If not autoscale (scale = xxx) then return video width * scale
 *)

function TFmxPasLibVlcPlayer.GetVideoWidth(): LongInt;
var
  px, py: LongWord;
begin
  px := 0;
  py := 0;

  if (Assigned(p_mi) and (libvlc_video_get_size(p_mi, 0, px, py) = 0)) then
  begin
    Result  := px;
  end
  else
  begin
    Result := 0;
  end;
end;

(*
 * Get current video height in pixels
 * If autoscale (scale = 0) then return original video height
 * If not autoscale (scale = xxx) then return video height * scale
 *)

function TFmxPasLibVlcPlayer.GetVideoHeight(): LongInt;
var
  px, py: LongWord;
begin
  px := 0;
  py := 0;

  if (Assigned(p_mi) and (libvlc_video_get_size(p_mi, 0, px, py) = 0)) then
  begin
    Result  := py;
  end
  else
  begin
    Result := 0;
  end;
end;

function TFmxPasLibVlcPlayer.GetVideoDimension(var width, height: LongWord) : Boolean;
begin
  width := 0;
  height := 0;
  Result := (Assigned(p_mi) and (libvlc_video_get_size(p_mi, 0, width, height) = 0));
end;

(*
 * Get current video scale
 * I scale this by 100 (lib vlc return this im range 0..1)
 * If autoscale is on then return 0 else return actual scale
 *
 *)

function TFmxPasLibVlcPlayer.GetVideoScaleInPercent(): Single;
begin
  Result := -1;
  if (p_mi = NIL) then exit;
  Result := libvlc_video_get_scale(p_mi) * 100;
end;

(*
 * Set current video scale
 * I scale this by 100 (lib vlc return this im range 0..1)
 * If return 0 then autoscale is on
 *
 *)

procedure TFmxPasLibVlcPlayer.SetVideoScaleInPercent(newScaleInPercent: Single);
begin
  if (p_mi = NIL) then exit;
  libvlc_video_set_scale(p_mi, newScaleInPercent / 100);
end;

function TFmxPasLibVlcPlayer.GetVideoAspectRatio(): string;
var
  libvlcaspect : PAnsiChar;
begin
  Result := '';
  if (p_mi = NIL) then exit;
  libvlcaspect := libvlc_video_get_aspect_ratio(p_mi);
  if (libvlcaspect <> NIL) then
  begin
    Result := UTF8ToWideString(AnsiString(libvlcaspect));
    libvlc_free(libvlcaspect);
  end;
end;

function TFmxPasLibVlcPlayer.GetVideoSampleAspectRatio(var sar_num, sar_den : Longword): Boolean;
var
  md           : libvlc_media_t_ptr;
  tracks_ptr   : Pointer;
  tracks_list  : libvlc_media_track_list_t_ptr;
  tracks_count : Integer;
  tracks_idx   : Integer;
  track_record : libvlc_media_track_t_ptr;
begin
  Result := FALSE;
  if (p_mi = NIL) then exit;
  md := libvlc_media_player_get_media(p_mi);
  tracks_count := libvlc_media_tracks_get(md, tracks_ptr);
  if (tracks_count > 0) then
  begin
    tracks_list := libvlc_media_track_list_t_ptr(@tracks_ptr);
    for tracks_idx := 0 to tracks_count-1 do
    begin
      track_record := tracks_list^[tracks_idx];
      if (track_record^.i_type = libvlc_track_video) then
      begin
        sar_num := track_record^.u.video^.i_sar_num;
        sar_den := track_record^.u.video^.i_sar_den;
        Result := TRUE;
        break;
      end;
    end;
    libvlc_media_tracks_release(tracks_ptr, tracks_count);
  end;
end;

function TFmxPasLibVlcPlayer.GetVideoSampleAspectRatio() : Single;
var
  sar_num, sar_den : Longword;
begin
  Result := 0;
  if GetVideoSampleAspectRatio(sar_num, sar_den) and (sar_den > 0) then
  begin
    Result := sar_num / sar_den;
  end;
end;

procedure TFmxPasLibVlcPlayer.SetVideoAspectRatio(newAspectRatio: string);
begin
  if (p_mi = NIL) then exit;
  libvlc_video_set_aspect_ratio(p_mi, PAnsiChar(AnsiString(newAspectRatio)));
end;

(*
 * Return video time length in miliseconds
 *)
 
function TFmxPasLibVlcPlayer.GetVideoLenInMs(): Int64;
begin
  Result := 0;
  if (p_mi = NIL) then exit;
  Result := libvlc_media_player_get_length(p_mi);
end;

(*
 * Return current video time length as string hh:mm:ss
 *)

function TFmxPasLibVlcPlayer.GetVideoLenStr(fmt: string = 'hh:mm:ss'): string;
begin
  Result := time2str(GetVideoLenInMs(), fmt);
end;

(*
 * Return current video time position in miliseconds
 *)

function TFmxPasLibVlcPlayer.GetVideoPosInMs(): Int64;
begin
  Result := 0;
  if (p_mi = NIL) then exit;
  Result := libvlc_media_player_get_time(p_mi);
end;

(*
 * Return current video time position as string hh:mm:ss
 *)

function TFmxPasLibVlcPlayer.GetVideoPosStr(fmt: string = 'hh:mm:ss'): string;
begin
  Result := time2str(GetVideoPosInMs(), fmt);
end;

(*
 * Set current video time position in miliseconds
 * Not working for all media
 *)

procedure TFmxPasLibVlcPlayer.SetVideoPosInMs(newPos: Int64);
begin
  if (p_mi = NIL) then exit;
  libvlc_media_player_set_time(p_mi, newPos);
  if (GetState() <> plvPlayer_Playing) then
  	if Assigned(FOnMediaPlayerTimeChanged) then
	    FOnMediaPlayerTimeChanged(Self, newPos);
end;

(*
 * Return current video position where 0 - start, 100 - end
 * I scale this by 100 (lib vlc return this in range 0..1)
 *)

function TFmxPasLibVlcPlayer.GetVideoPosInPercent(): Single;
begin
  Result := 0;
  if (p_mi = NIL) then exit;
  Result := libvlc_media_player_get_position(p_mi) * 100;
end;

(*
 * Set current video position where 0 - start, 100 - end
 * I scale this by 100 (lib vlc return this in range 0..1)
 * Not working for all media
 *)

procedure TFmxPasLibVlcPlayer.SetVideoPosInPercent(newPos: Single);
begin
  if (p_mi = NIL) then exit;
  libvlc_media_player_set_position(p_mi, newPos / 100);
  if (GetState() <> plvPlayer_Playing) then
    if Assigned(FOnMediaPlayerPositionChanged) then
      FOnMediaPlayerPositionChanged(Self, newPos / 100);
end;

(*
 * Return frames per second
 *)

function TFmxPasLibVlcPlayer.GetVideoFps(): Single;
begin
  Result := -1;
  if (p_mi = NIL) then exit;
  Result := libvlc_media_player_get_fps(p_mi);
end;

(*
 * Return true if player can play
 *)

function TFmxPasLibVlcPlayer.CanPlay(): Boolean;
begin
  Result := FALSE;
  if (p_mi = NIL) then exit;
  Result := (libvlc_media_player_will_play(p_mi) > 0);
end;

(*
 * Return true if player can pause
 *)

function TFmxPasLibVlcPlayer.CanPause(): Boolean;
begin
  Result := FALSE;
  if (p_mi = NIL) then exit;
  Result := (libvlc_media_player_can_pause(p_mi) > 0);
end;

(*
 * Return true if player can seek (can set time or percent position)
 *)

function TFmxPasLibVlcPlayer.CanSeek(): Boolean;
begin
  Result := FALSE;
  if (p_mi = NIL) then exit;
  Result := (libvlc_media_player_is_seekable(p_mi) > 0);
end;

(*
 * Return true if player has video output
 *)
function TFmxPasLibVlcPlayer.HasVout() : Boolean;
begin
  Result := FALSE;
  if (p_mi = NIL) then exit;
  Result := (libvlc_media_player_has_vout(p_mi) > 0);
end;

(*
 * Return true if video is scrambled
 *)
function TFmxPasLibVlcPlayer.IsScrambled() : Boolean;
begin
  Result := FALSE;
  if (p_mi = NIL) then exit;
  Result := (libvlc_media_player_program_scrambled(p_mi) > 0)
end;

(*
 * Create snapshot of current video frame to specified fileName
 * The file is in PNG format
 *)
 
function TFmxPasLibVlcPlayer.Snapshot(fileName: WideString): Boolean;
var
  i_width, i_height: LongWord;
begin
  Result := FALSE;
  if (p_mi = NIL) then exit;
  i_width := 0;
  i_height := 0;
  if (libvlc_video_get_size(p_mi, 0, i_width, i_height) <> 0) then exit;
  Result := (libvlc_video_take_snapshot(p_mi, 0, PAnsiChar(Utf8Encode(fileName)), i_width, i_height) = 0);
end;

(*
 * Create snapshot of current video frame
 * to specified fileName with size width x heght
 * The file is in PNG format
 *)

function TFmxPasLibVlcPlayer.Snapshot(fileName: WideString; width, height: LongWord): Boolean;
begin
  Result := FALSE;
  if (p_mi = NIL) then exit;
  Result := (libvlc_video_take_snapshot(p_mi, 0, PAnsiChar(Utf8Encode(fileName)), width, height) = 0);
end;

procedure TFmxPasLibVlcPlayer.NextFrame();
begin
  if (p_mi = NIL) then exit;
  libvlc_media_player_next_frame(p_mi);
end;

function TFmxPasLibVlcPlayer.GetAudioMute(): Boolean;
begin
  Result := FMute;
end;

procedure TFmxPasLibVlcPlayer.SetAudioMute(mute: Boolean);
begin
  if (p_mi = NIL) then exit;
  if mute then libvlc_audio_set_mute(p_mi, 1)
  else         libvlc_audio_set_mute(p_mi, 0);
  FMute := mute;
end;

function TFmxPasLibVlcPlayer.GetAudioVolume(): Integer;
begin
  Result := -1;
  if (p_mi = NIL) then exit;
  Result := libvlc_audio_get_volume(p_mi);
end;

procedure TFmxPasLibVlcPlayer.SetAudioVolume(volumeLevel: Integer);
begin
  if (p_mi = NIL) then exit;
  if (volumeLevel < 0) then exit;
  if (volumeLevel > 200) then exit;
//  if (FVLC.VersionBin < $020100) then
  begin
    libvlc_audio_set_volume(p_mi, volumeLevel);
  end;
end;

procedure TFmxPasLibVlcPlayer.SetPlayRate(rate: Integer);
begin
  if (p_mi = NIL) then exit;
  if (rate < 1) then exit;
  if (rate > 1000) then exit;  
  libvlc_media_player_set_rate(p_mi, rate / 100);
end;

function TFmxPasLibVlcPlayer.GetPlayRate(): Integer;
begin
  Result := -1;
  if (p_mi = NIL) then exit;
  Result := Round(100 * libvlc_media_player_get_rate(p_mi));
end;

////////////////////////////////////////////////////////////////////////////////

function TFmxPasLibVlcPlayer.GetAudioFilterList(return_name_type : Integer = 0): TStringList;
var
  p_list : libvlc_module_description_t_ptr;
begin
  Result := TStringList.Create;
  if (p_mi = NIL) then exit;

  p_list := libvlc_audio_filter_list_get(p_mi);

  if (return_name_type = 0) then
  begin
    while (p_list <> NIL) do
    begin
      if (p_list^.psz_name <> NIL) then
      begin
        Result.AddObject(
          UTF8ToWideString(p_list^.psz_name),
          NIL);
      end;
      p_list := p_list^.p_next;
    end;
  end;

  if (return_name_type = 1) then
  begin
    while (p_list <> NIL) do
    begin
      if (p_list^.psz_shortname <> NIL) then
      begin
        Result.AddObject(
          UTF8ToWideString(p_list^.psz_shortname),
          NIL);
      end;
      p_list := p_list^.p_next;
    end;
  end;

  if (return_name_type = 2) then
  begin
    while (p_list <> NIL) do
    begin
      if (p_list^.psz_longname <> NIL) then
      begin
        Result.AddObject(
          UTF8ToWideString(p_list^.psz_longname),
          NIL);
      end;
      p_list := p_list^.p_next;
    end;
  end;

  if (return_name_type = 3) then
  begin
    while (p_list <> NIL) do
    begin
      if (p_list^.psz_help <> NIL) then
      begin
        Result.AddObject(
          UTF8ToWideString(p_list^.psz_help),
          NIL);
      end;
      p_list := p_list^.p_next;
    end;
  end;

  libvlc_module_description_list_release(p_list);
end;

function  TFmxPasLibVlcPlayer.GetVideoFilterList(return_name_type : Integer = 0): TStringList;
var
  p_list : libvlc_module_description_t_ptr;
begin
  Result := TStringList.Create;
  if (p_mi = NIL) then exit;

  p_list := libvlc_video_filter_list_get(p_mi);

  if (return_name_type = 0) then
  begin
    while (p_list <> NIL) do
    begin
      if (p_list^.psz_name <> NIL) then
      begin
        Result.AddObject(
          UTF8ToWideString(p_list^.psz_name),
          NIL);
      end;
      p_list := p_list^.p_next;
    end;
  end;

  if (return_name_type = 1) then
  begin
    while (p_list <> NIL) do
    begin
      if (p_list^.psz_shortname <> NIL) then
      begin
        Result.AddObject(
          UTF8ToWideString(p_list^.psz_shortname),
          NIL);
      end;
      p_list := p_list^.p_next;
    end;
  end;

  if (return_name_type = 2) then
  begin
    while (p_list <> NIL) do
    begin
      if (p_list^.psz_longname <> NIL) then
      begin
        Result.AddObject(
          UTF8ToWideString(p_list^.psz_longname),
          NIL);
      end;
      p_list := p_list^.p_next;
    end;
  end;

  if (return_name_type = 3) then
  begin
    while (p_list <> NIL) do
    begin
      if (p_list^.psz_help <> NIL) then
      begin
        Result.AddObject(
          UTF8ToWideString(p_list^.psz_help),
          NIL);
      end;
      p_list := p_list^.p_next;
    end;
  end;

  libvlc_module_description_list_release(p_list);
end;

////////////////////////////////////////////////////////////////////////////////

function TFmxPasLibVlcPlayer.GetAudioTrackList() : TStringList;
var
  p_track : libvlc_track_description_t_ptr;
begin
  Result := TStringList.Create;
  if (p_mi = NIL) then exit;

  p_track := libvlc_audio_get_track_description(p_mi);

  while (p_track <> NIL) do
  begin
    if (p_track^.psz_name <> NIL) then
    begin
      Result.AddObject(
        UTF8ToWideString(p_track^.psz_name),
        TObject(p_track^.i_id));
    end;
    p_track := p_track^.p_next;
  end;
end;

function TFmxPasLibVlcPlayer.GetAudioTrackCount(): Integer;
begin
  Result := -1;
  if (p_mi = NIL) then exit;
  Result := libvlc_audio_get_track_count(p_mi);
end;

function TFmxPasLibVlcPlayer.GetAudioTrackId(): Integer;
begin
  Result := -1;
  if (p_mi = NIL) then exit;
  Result := libvlc_audio_get_track(p_mi);
end;

procedure TFmxPasLibVlcPlayer.SetAudioTrackById(const track_id : Integer);
begin
  if (p_mi = NIL) then exit;
  if (track_id < 0) then exit;
  
  libvlc_audio_set_track(p_mi, track_id);
end;

function TFmxPasLibVlcPlayer.GetAudioTrackNo(): Integer;
var
  track_id : Integer;
  p_track  : libvlc_track_description_t_ptr;
begin
  Result := 0;

  if not Assigned(p_mi) then exit;

  track_id := libvlc_audio_get_track(p_mi);

  p_track := libvlc_audio_get_track_description(p_mi);

  while (p_track <> NIL) do
  begin
    if (p_track^.i_id = track_id) then exit;
    Inc(Result);
    p_track := p_track^.p_next;
  end;

  Result := -1;
end;

procedure TFmxPasLibVlcPlayer.SetAudioTrackByNo(track_no : Integer);
var
  p_track : libvlc_track_description_t_ptr;
begin
  if (p_mi = NIL) then exit;
  if (track_no < 0) then exit;

  p_track := libvlc_audio_get_track_description(p_mi);

  while ((track_no > 0) and (p_track <> NIL)) do
  begin
    Dec(track_no);
    p_track := p_track^.p_next;
  end;

  if (p_track <> NIL) then
  begin
    libvlc_audio_set_track(p_mi, p_track^.i_id);
  end;
end;

function TFmxPasLibVlcPlayer.GetAudioTrackDescriptionById(const track_id : Integer): WideString;
var
  p_track : libvlc_track_description_t_ptr;
begin
  Result := '';

  if (track_id < 0) then exit;
  
  if not Assigned(p_mi) then exit;

  p_track := libvlc_audio_get_track_description(p_mi);

  while (p_track <> NIL) do
  begin
    if (p_track^.i_id = track_id) then
    begin
      if (p_track^.psz_name <> NIL) then
      begin
        Result := UTF8ToWideString(p_track^.psz_name);
      end;
      break;
    end;
    p_track := p_track^.p_next;
  end;
end;

function TFmxPasLibVlcPlayer.GetAudioTrackDescriptionByNo(track_no: Integer): WideString;
var
  p_track : libvlc_track_description_t_ptr;
begin
  Result := '';

  if (track_no < 0) then exit;

  if not Assigned(p_mi) then exit;

  p_track := libvlc_audio_get_track_description(p_mi);

  while ((track_no > 0) and (p_track <> NIL)) do
  begin
    Dec(track_no);
    p_track := p_track^.p_next;
  end;

  if (p_track <> NIL) then
  begin
    if (p_track^.psz_name <> NIL) then
    begin
      Result := UTF8ToWideString(p_track^.psz_name);
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

function TFmxPasLibVlcPlayer.EqualizerGetPresetList(): TStringList;
var
  preset : PAnsiChar;
  count  : Word;
  index  : Word;
begin
  Result := TStringList.Create;

  if (VLC.Handle = NIL) then exit;

  count := libvlc_audio_equalizer_get_preset_count();
  index := 0;
  while (index < count) do
  begin
    preset := libvlc_audio_equalizer_get_preset_name(index);
    if ((preset <> NIL) and (preset <> '')) then
    begin
      Result.AddObject(
        UTF8ToWideString(preset),
        TObject(index)
      );
    end;
    Inc(index);
  end;
end;

function TFmxPasLibVlcPlayer.EqualizerGetBandCount(): unsigned_t;
begin
  Result := 0;
  if (VLC.Handle = NIL) then exit;
  Result := libvlc_audio_equalizer_get_band_count();
end;

function TFmxPasLibVlcPlayer.EqualizerGetBandFrequency(bandIndex : unsigned_t): Single;
begin
  Result := 0;
  if (VLC.Handle = NIL) then exit;
  Result := libvlc_audio_equalizer_get_band_frequency(bandIndex);
end;

function TFmxPasLibVlcPlayer.EqualizerCreate(APreset : unsigned_t = $FFFF) : TPasLibVlcEqualizer;
begin
  Result := TPasLibVlcEqualizer.Create(FVLC, APreset);
end;

procedure TFmxPasLibVlcPlayer.EqualizerApply(AEqualizer : TPasLibVlcEqualizer);
begin
  if (VLC.Handle = NIL) then exit;
  GetPlayerHandle();
  if not Assigned(p_mi) then exit;

  if (AEqualizer <> NIL) then
  begin
    libvlc_media_player_set_equalizer(p_mi, AEqualizer.GetHandle());
  end
  else
  begin
    libvlc_media_player_set_equalizer(p_mi, NIL);
  end;
end;

procedure TFmxPasLibVlcPlayer.EqualizerSetPreset(APreset : unsigned_t = $FFFF);
var
  equalizer : TPasLibVlcEqualizer;
begin
  if (VLC.Handle = NIL) then exit;
  GetPlayerHandle();
  if not Assigned(p_mi) then exit;
  if (APreset <> $FFFF) then
  begin
    equalizer := TPasLibVlcEqualizer.Create(FVLC, APreset);
    libvlc_media_player_set_equalizer(p_mi, equalizer.GetHandle());
    equalizer.Free;
  end
  else
  begin
    libvlc_media_player_set_equalizer(p_mi, NIL);
  end;
end;

////////////////////////////////////////////////////////////////////////////////

function TFmxPasLibVlcPlayer.GetAudioOutputList(withDescription : Boolean = FALSE; separator : string = '|'): TStringList;
var
  p_list_head : libvlc_audio_output_t_ptr;
  p_list_item : libvlc_audio_output_t_ptr;
begin
  Result := TStringList.Create;
  p_list_head := libvlc_audio_output_list_get(VLC.Handle);

  if (p_list_head <> NIL) then
  begin
    p_list_item := p_list_head;
    while (p_list_item <> NIL) do
    begin
      if (p_list_item^.psz_name <> NIL) then
      begin
        if (withDescription) then
        begin
          Result.Add(
            UTF8ToWideString(p_list_item^.psz_name)
            + separator +
            UTF8ToWideString(p_list_item^.psz_description)
          );
        end
        else
        begin
          Result.Add(UTF8ToWideString(p_list_item^.psz_name));
        end;
      end;
      p_list_item := p_list_item^.p_next;
    end;
    libvlc_audio_output_list_release(p_list_head);
  end;
end;

function TFmxPasLibVlcPlayer.GetAudioOutputDeviceList(aOut : WideString; withDescription : Boolean = FALSE; separator : string = '|'): TStringList;
var
  p_list_head : libvlc_audio_output_device_t_ptr;
  p_list_item : libvlc_audio_output_device_t_ptr;
begin
  Result := TStringList.Create;
  p_list_head := libvlc_audio_output_device_list_get(VLC.Handle, PAnsiChar(Utf8Encode(aOut)));

  if (p_list_head <> NIL) then
  begin
    p_list_item := p_list_head;
    while (p_list_item <> NIL) do
    begin
      if (p_list_item^.psz_device <> NIL) then
      begin
        if (withDescription) then
        begin
          Result.Add(
            UTF8ToWideString(p_list_item^.psz_device)
            + separator +
            UTF8ToWideString(p_list_item^.psz_description)
          );
        end
        else
        begin
          Result.Add(
            UTF8ToWideString(p_list_item^.psz_device)
          );
        end;
      end;
      p_list_item := p_list_item^.p_next;
    end;
    libvlc_audio_output_device_list_release(p_list_head);
  end;
end;

function TFmxPasLibVlcPlayer.GetAudioOutputDeviceEnum(withDescription : Boolean = FALSE; separator : string = '|') : TStringList;
var
  p_list_head : libvlc_audio_output_device_t_ptr;
  p_list_item : libvlc_audio_output_device_t_ptr;
begin
  Result := TStringList.Create;

  if (p_mi = NIL) then GetPlayerHandle();
  
  if not Assigned(p_mi) then exit;
  
  p_list_head := libvlc_audio_output_device_enum(p_mi);

  if (p_list_head <> NIL) then
  begin
    p_list_item := p_list_head;
    while (p_list_item <> NIL) do
    begin
      if (p_list_item^.psz_device <> NIL) then
      begin
        if (withDescription) then
        begin
          Result.Add(
            UTF8ToWideString(p_list_item^.psz_device)
            + separator +
            UTF8ToWideString(p_list_item^.psz_description)
          );
        end
        else
        begin
          Result.Add(
            UTF8ToWideString(p_list_item^.psz_device)
          );
        end;
      end;
      p_list_item := p_list_item^.p_next;
    end;
    libvlc_audio_output_device_list_release(p_list_head);
  end;
end;

function TFmxPasLibVlcPlayer.SetAudioOutput(aOut: WideString) : Boolean;
begin
  Result := FALSE;
  if (p_mi = NIL) then GetPlayerHandle();
  if (p_mi <> NIL) then
  begin
    Result := (libvlc_audio_output_set(p_mi, PAnsiChar(Utf8Encode(aOut))) = 0);
    if Result then
    begin
      FLastAudioOutput := aOut;
    end;
  end;
end;

procedure TFmxPasLibVlcPlayer.SetAudioOutputDevice(aOut: WideString; aOutDeviceId: WideString);
begin
  if (p_mi = NIL) then
  begin
    GetPlayerHandle();
  end;
  if (p_mi <> NIL) then
  begin
    if (aOut <> '') then
    begin
      libvlc_audio_output_device_set(p_mi, PAnsiChar(Utf8Encode(aOut)), PAnsiChar(Utf8Encode(aOutDeviceId)));
      FLastAudioOutput         := aOut;
      FLastAudioOutputDeviceId := aOutDeviceId;
    end
    else
    begin
      libvlc_audio_output_device_set(p_mi, NIL, PAnsiChar(Utf8Encode(aOutDeviceId)));
      FLastAudioOutput         := '';
      FLastAudioOutputDeviceId := aOutDeviceId;
    end;
  end;
end;

procedure TFmxPasLibVlcPlayer.SetAudioOutputDevice(aOutDeviceId: WideString);
begin
  if (p_mi = NIL) then
  begin
    GetPlayerHandle();
  end;
  if (p_mi <> NIL) then
  begin
    libvlc_audio_output_device_set(p_mi, NIL, PAnsiChar(Utf8Encode(aOutDeviceId)));
    FLastAudioOutput         := '';
    FLastAudioOutputDeviceId := aOutDeviceId;
  end;
end;

{$IFDEF USE_VLC_DEPRECATED_API}
function TFmxPasLibVlcPlayer.GetAudioOutputDeviceCount(aOut: WideString): Integer;
begin
  Result := libvlc_audio_output_device_count(VLC.Handle, PAnsiChar(Utf8Encode(aOut)));
end;

function TFmxPasLibVlcPlayer.GetAudioOutputDeviceId(aOut: WideString; deviceIdx : Integer) : WideString;
var
  device_id : PAnsiChar;
begin
  Result := '';
  device_id := libvlc_audio_output_device_id(VLC.Handle, PAnsiChar(Utf8Encode(aOut)), deviceIdx);
  if (device_id <> NIL) then
  begin
    Result := UTF8ToWideString(device_id);
    libvlc_free(device_id);
  end;
end;

function TFmxPasLibVlcPlayer.GetAudioOutputDeviceName(aOut: WideString; deviceIdx : Integer): WideString;
var
  device_name : PAnsiChar;
begin
  device_name := libvlc_audio_output_device_longname(VLC.Handle, PAnsiChar(Utf8Encode(aOut)), deviceIdx);
  Result := '';
  if (device_name <> NIL) then
  begin
    Result := UTF8ToWideString(device_name);
//    libvlc_free(device_name);
  end;
end;
{$ENDIF}

////////////////////////////////////////////////////////////////////////////////

procedure TFmxPasLibVlcPlayer.SetVideoAdjustEnable(value : Boolean);
begin
  if (p_mi = NIL) then exit;
  if (value) then libvlc_video_set_adjust_int(p_mi, libvlc_adjust_Enable, 1)
  else libvlc_video_set_adjust_int(p_mi, libvlc_adjust_Enable, 0);
end;

function TFmxPasLibVlcPlayer.GetVideoAdjustEnable(): Boolean;
begin
  Result := FALSE;
  if (p_mi = NIL) then exit;
  Result := (libvlc_video_get_adjust_int(p_mi, libvlc_adjust_Enable) <> 0);
end;

// Set the image contrast, between 0 and 2. Defaults to 1
procedure TFmxPasLibVlcPlayer.SetVideoAdjustContrast(value : Single);
begin
  if (p_mi = NIL) then exit;
  libvlc_video_set_adjust_float(p_mi, libvlc_adjust_Contrast, value);
end;

function TFmxPasLibVlcPlayer.GetVideoAdjustContrast(): Single;
begin
  Result := 0;
  if (p_mi = NIL) then exit;
  Result := libvlc_video_get_adjust_float(p_mi, libvlc_adjust_Contrast);
end;

// Set the image brightness, between 0 and 2. Defaults to 1.
procedure TFmxPasLibVlcPlayer.SetVideoAdjustBrightness(value : Single);
begin
  if (p_mi = NIL) then exit;
  libvlc_video_set_adjust_float(p_mi, libvlc_adjust_Brightness, value);
end;

function TFmxPasLibVlcPlayer.GetVideoAdjustBrightness(): Single;
begin
  Result := 0;
  if (p_mi = NIL) then exit;
  Result := libvlc_video_get_adjust_float(p_mi, libvlc_adjust_Brightness);
end;

// Set the image hue, between 0 and 360. Defaults to 0.
procedure TFmxPasLibVlcPlayer.SetVideoAdjustHue(value : Integer);
begin
  if (p_mi = NIL) then exit;
  libvlc_video_set_adjust_int(p_mi, libvlc_adjust_Hue, value);
end;

function TFmxPasLibVlcPlayer.GetVideoAdjustHue(): Integer;
begin
  Result := 0;
  if (p_mi = NIL) then exit;
  Result := libvlc_video_get_adjust_int(p_mi, libvlc_adjust_Hue);
end;

// Set the image saturation, between 0 and 3. Defaults to 1.
procedure TFmxPasLibVlcPlayer.SetVideoAdjustSaturation(value : Single);
begin
  if (p_mi = NIL) then exit;
  libvlc_video_set_adjust_float(p_mi, libvlc_adjust_Saturation, value);
end;

function TFmxPasLibVlcPlayer.GetVideoAdjustSaturation(): Single;
begin
  Result := 0;
  if (p_mi = NIL) then exit;
  Result := libvlc_video_get_adjust_float(p_mi, libvlc_adjust_Saturation);
end;

// Set the image gamma, between 0.01 and 10. Defaults to 1
procedure TFmxPasLibVlcPlayer.SetVideoAdjustGamma(value : Single);
begin
  if (p_mi = NIL) then exit;
  libvlc_video_set_adjust_float(p_mi, libvlc_adjust_Gamma, value);
end;

function TFmxPasLibVlcPlayer.GetVideoAdjustGamma(): Single;
begin
  Result := 0;
  if (p_mi = NIL) then exit;
  Result := libvlc_video_get_adjust_float(p_mi, libvlc_adjust_Gamma);
end;

////////////////////////////////////////////////////////////////////////////////

function TFmxPasLibVlcPlayer.GetVideoChapter(): Integer;
begin
  Result := -1;
  if (p_mi = NIL) then exit;
  Result := libvlc_media_player_get_chapter(p_mi);
end;

procedure TFmxPasLibVlcPlayer.SetVideoChapter(newChapter: Integer);
begin
  if (p_mi = NIL) then exit;
  libvlc_media_player_set_chapter(p_mi, newChapter);
end;

function TFmxPasLibVlcPlayer.GetVideoChapterCount(): Integer;
begin
  Result := -1;
  if (p_mi = NIL) then exit;
  Result := libvlc_media_player_get_chapter_count(p_mi);
end;

function TFmxPasLibVlcPlayer.GetVideoChapterCountByTitleId(const title_id : Integer): Integer;
begin
  Result := -1;
  if (p_mi = NIL) then exit;
  Result := libvlc_media_player_get_chapter_count_for_title(p_mi, title_id);
end;

////////////////////////////////////////////////////////////////////////////////

function TFmxPasLibVlcPlayer.GetVideoSubtitleList(): TStringList;
var
  p_track : libvlc_track_description_t_ptr;
begin
  Result := TStringList.Create;
  if (p_mi = NIL) then exit;

  p_track := libvlc_video_get_spu_description(p_mi);

  while (p_track <> NIL) do
  begin
    if (p_track^.psz_name <> NIL) then
    begin
      Result.AddObject(
        UTF8ToWideString(p_track^.psz_name),
        TObject(p_track^.i_id));
    end;
    p_track := p_track^.p_next;
  end;
end;

function TFmxPasLibVlcPlayer.GetVideoSubtitleCount(): Integer;
begin
  Result := -1;
  if (p_mi = NIL) then exit;
  Result := libvlc_video_get_spu_count(p_mi);
end;

function TFmxPasLibVlcPlayer.GetVideoSubtitleId(): Integer;
begin
  Result := -1;
  if (p_mi = NIL) then Exit;
  Result := libvlc_video_get_spu(p_mi);
end;

procedure TFmxPasLibVlcPlayer.SetVideoSubtitleById(const subtitle_id : Integer);
begin
  if (p_mi = NIL) then exit;
  libvlc_video_set_spu(p_mi, subtitle_id);
end;

function TFmxPasLibVlcPlayer.GetVideoSubtitleNo(): Integer;
var
  track_id : Integer;
  p_track  : libvlc_track_description_t_ptr;
begin
  Result := 0;

  if not Assigned(p_mi) then exit;

  track_id := libvlc_video_get_spu(p_mi);

  p_track := libvlc_video_get_spu_description(p_mi);

  while (p_track <> NIL) do
  begin
    if (p_track^.i_id = track_id) then exit;
    Inc(Result);
    p_track := p_track^.p_next;
  end;

  Result := -1;
end;

procedure TFmxPasLibVlcPlayer.SetVideoSubtitleByNo(subtitle_no: Integer);
var
  p_track: libvlc_track_description_t_ptr;
begin
  if (p_mi = NIL) then exit;
  if (subtitle_no < 0) then exit;

  p_track := libvlc_video_get_spu_description(p_mi);

  while ((subtitle_no > 0) and (p_track <> NIL)) do
  begin
    Dec(subtitle_no);
    p_track := p_track^.p_next;
  end;

  if (p_track <> NIL) then
  begin
    libvlc_video_set_spu(p_mi, p_track^.i_id);
  end;
end;

function TFmxPasLibVlcPlayer.GetVideoSubtitleDescriptionById(const subtitle_id : Integer): WideString;
var
  p_track: libvlc_track_description_t_ptr;
begin
  Result := '';

  if (subtitle_id < 0) then exit;
  
  if not Assigned(p_mi) then exit;

  p_track := libvlc_video_get_spu_description(p_mi);

  while (p_track <> NIL) do
  begin
    if (p_track^.i_id = subtitle_id) then
    begin
      if (p_track^.psz_name <> NIL) then
      begin
        Result := UTF8ToWideString(p_track^.psz_name);
      end;
      break;
    end;
    p_track := p_track^.p_next;
  end;
end;

function TFmxPasLibVlcPlayer.GetVideoSubtitleDescriptionByNo(subtitle_no: Integer): WideString;
var
  p_track: libvlc_track_description_t_ptr;
begin
  Result := '';

  if (subtitle_no < 0) then exit;

  if not Assigned(p_mi) then exit;

  p_track := libvlc_video_get_spu_description(p_mi);

  while ((subtitle_no > 0) and (p_track <> NIL)) do
  begin
    Dec(subtitle_no);
    p_track := p_track^.p_next;
  end;

  if (p_track <> NIL) then
  begin
    if (p_track^.psz_name <> NIL) then
    begin
      Result := UTF8ToWideString(p_track^.psz_name);
    end;
  end;
end;

procedure TFmxPasLibVlcPlayer.SetVideoSubtitleFile(subtitle_file : WideString);
begin
  if (p_mi = NIL) then exit;
  libvlc_video_set_subtitle_file(p_mi, PAnsiChar(UTF8Encode(subtitle_file)));
end;

////////////////////////////////////////////////////////////////////////////////

function TFmxPasLibVlcPlayer.GetVideoTitleList(): TStringList;
var
  p_track : libvlc_track_description_t_ptr;
begin
  Result := TStringList.Create;
  if (p_mi = NIL) then exit;

  p_track := libvlc_video_get_title_description(p_mi);

  while (p_track <> NIL) do
  begin
    if (p_track^.psz_name <> NIL) then
    begin
      Result.AddObject(
        UTF8ToWideString(p_track^.psz_name),
        TObject(p_track^.i_id));
    end;
    p_track := p_track^.p_next;
  end;
end;

function  TFmxPasLibVlcPlayer.GetVideoTitleCount(): Integer;
begin
  Result := -1;
  if (p_mi = NIL) then exit;
  Result := libvlc_media_player_get_title_count(p_mi);
end;

function  TFmxPasLibVlcPlayer.GetVideoTitleId():Integer;
begin
  Result := -1;
  if (p_mi = NIL) then exit;
  Result := libvlc_media_player_get_title(p_mi);
end;

procedure TFmxPasLibVlcPlayer.SetVideoTitleById(const title_id:Integer);
begin
  if (p_mi = NIL) then exit;
  libvlc_media_player_set_title(p_mi, title_id);
end;

function TFmxPasLibVlcPlayer.GetVideoTitleNo(): Integer;
var
  title_id : Integer;
  p_track  : libvlc_track_description_t_ptr;
begin
  Result := 0;

  if not Assigned(p_mi) then exit;

  title_id := libvlc_media_player_get_title(p_mi);

  p_track := libvlc_video_get_title_description(p_mi);

  while (p_track <> NIL) do
  begin
    if (p_track^.i_id = title_id) then exit;
    Inc(Result);
    p_track := p_track^.p_next;
  end;

  Result := -1;
end;

procedure TFmxPasLibVlcPlayer.SetVideoTitleByNo(title_no : Integer);
var
  p_track: libvlc_track_description_t_ptr;
begin
  if (p_mi = NIL) then exit;
  if (title_no < 0) then exit;

  p_track := libvlc_video_get_title_description(p_mi);

  while ((title_no > 0) and (p_track <> NIL)) do
  begin
    Dec(title_no);
    p_track := p_track^.p_next;
  end;

  if (p_track <> NIL) then
  begin
    libvlc_media_player_set_title(p_mi, p_track^.i_id);
  end;
end;

function TFmxPasLibVlcPlayer.GetVideoTitleDescriptionById(const track_id : Integer): WideString;
var
  p_track: libvlc_track_description_t_ptr;
begin
  Result := '';

  if (track_id < 0) then exit;
  
  if not Assigned(p_mi) then exit;

  p_track := libvlc_video_get_title_description(p_mi);

  while (p_track <> NIL) do
  begin
    if (p_track^.i_id = track_id) then
    begin
      if (p_track^.psz_name <> NIL) then
      begin
        Result := UTF8ToWideString(p_track^.psz_name);
      end;
      break;
    end;
    p_track := p_track^.p_next;
  end;
end;

function TFmxPasLibVlcPlayer.GetVideoTitleDescriptionByNo(title_no : Integer): WideString;
var
  p_track: libvlc_track_description_t_ptr;
begin
  Result := '';

  if (title_no < 0) then exit;

  if not Assigned(p_mi) then exit;

  p_track := libvlc_video_get_title_description(p_mi);

  while ((title_no > 0) and (p_track <> NIL)) do
  begin
    Dec(title_no);
    p_track := p_track^.p_next;
  end;

  if (p_track <> NIL) then
  begin
    if (p_track^.psz_name <> NIL) then
    begin
      Result := UTF8ToWideString(p_track^.psz_name);
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

function TFmxPasLibVlcPlayer.GetAudioChannel(): libvlc_audio_output_channel_t;
begin
  Result := libvlc_AudioChannel_Error;
  if not Assigned(p_mi) then exit;
  Result := libvlc_audio_get_channel(p_mi);
end;

procedure TFmxPasLibVlcPlayer.SetAudioChannel(chanel: libvlc_audio_output_channel_t);
begin
  if not Assigned(p_mi) then exit;
  libvlc_audio_set_channel(p_mi, chanel);
end;

function  TFmxPasLibVlcPlayer.GetAudioDelay(): Int64;
begin
  Result := 0;
  if not Assigned(p_mi) then exit;
  Result := libvlc_audio_get_delay(p_mi);
end;

procedure TFmxPasLibVlcPlayer.SetAudioDelay(delay: Int64);
begin
  if not Assigned(p_mi) then exit;
  libvlc_audio_set_delay(p_mi, delay);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TFmxPasLibVlcPlayer.SetTeleText(page: Integer);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_teletext(p_mi, page);
end;

function TFmxPasLibVlcPlayer.GetTeleText() : Integer;
begin
  Result := -1;
  if not Assigned(p_mi) then exit;
  Result := libvlc_video_get_teletext(p_mi);
end;

function TFmxPasLibVlcPlayer.ShowTeleText() : Boolean;
begin
  Result := FViewTeleText;
  if FViewTeleText then exit;
  if not Assigned(p_mi) then exit;
  if (libvlc_media_player_is_playing(p_mi) = 0) then exit;
  libvlc_toggle_teletext(p_mi);
  Result := FViewTeleText;
end;

function TFmxPasLibVlcPlayer.HideTeleText() : Boolean;
begin
  Result := FViewTeleText;
  if not FViewTeleText then exit;
  if not Assigned(p_mi) then exit;
  if (libvlc_media_player_is_playing(p_mi) = 0) then exit;
  libvlc_toggle_teletext(p_mi);
  Result := FViewTeleText;
end;

////////////////////////////////////////////////////////////////////////////////
//
// https://wiki.videolan.org/Documentation:Modules/logo/
//
////////////////////////////////////////////////////////////////////////////////

procedure TFmxPasLibVlcPlayer.LogoSetFile(file_name : WideString);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_logo_string(p_mi, libvlc_logo_File, PAnsiChar(UTF8Encode(file_name)));
end;

procedure TFmxPasLibVlcPlayer.LogoSetFiles(file_names : array of WideString; delay_ms : Integer = 1000; loop : Boolean = TRUE);
var
  file_name : WideString;
  file_indx : Integer;
begin
  file_name := '';
  for file_indx := Low(file_names) to High(file_names) do
  begin
    file_name := file_name + file_names[file_indx] + {$IFDEF MSWINDOWS} ';'; {$ELSE} ':'; {$ENDIF};
  end;
  // remove last PATH_SEPARATOR;
  if (file_name <> '') then SetLength(file_name, Length(file_name)-1);
  LogoSetFile(file_name);
  LogoSetDelay(delay_ms);
  LogoSetRepeat(loop);
end;

procedure TFmxPasLibVlcPlayer.LogoSetPosition(position_x, position_y : Integer);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_logo_int(p_mi, libvlc_logo_X, position_x);
  libvlc_video_set_logo_int(p_mi, libvlc_logo_Y, position_y);
end;

procedure TFmxPasLibVlcPlayer.LogoSetPosition(position : libvlc_position_t);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_logo_int(p_mi, libvlc_logo_Position, Ord(position));
end;

procedure TFmxPasLibVlcPlayer.LogoSetOpacity(opacity : libvlc_opacity_t);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_logo_int(p_mi, libvlc_logo_Opacity, opacity);
end;

procedure TFmxPasLibVlcPlayer.LogoSetDelay(delay_ms : Integer = 1000); // delay before show next logo file, default 1000
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_logo_int(p_mi, libvlc_logo_Delay, delay_ms);
end;

procedure TFmxPasLibVlcPlayer.LogoSetRepeat(loop : Boolean = TRUE);
begin
  if not Assigned(p_mi) then exit;
  if loop then libvlc_video_set_logo_int(p_mi, libvlc_logo_Repeat, -1) // -1 = loop,
  else         libvlc_video_set_logo_int(p_mi, libvlc_logo_Repeat, 0); // 0 - disable
end;

procedure TFmxPasLibVlcPlayer.LogoSetEnable(enable : Integer);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_logo_int(p_mi, libvlc_logo_Enable, enable); // not work
end;

procedure TFmxPasLibVlcPlayer.LogoShowFile(file_name : WideString; position_x, position_y : Integer; opacity: libvlc_opacity_t = libvlc_opacity_full);
begin
  LogoSetFile(file_name);
  LogoSetPosition(position_x, position_y);
  LogoSetOpacity(opacity);
  LogoSetEnable(1);
end;

procedure TFmxPasLibVlcPlayer.LogoShowFile(file_name : WideString; position: libvlc_position_t = libvlc_position_top; opacity: libvlc_opacity_t = libvlc_opacity_full);
begin
  LogoSetFile(file_name);
  LogoSetPosition(position);
  LogoSetOpacity(opacity);
  LogoSetEnable(1);
end;

procedure TFmxPasLibVlcPlayer.LogoShowFiles(file_names : array of WideString; position_x, position_y : Integer; opacity: libvlc_opacity_t = libvlc_opacity_full; delay_ms : Integer = 1000; loop : Boolean = TRUE);
begin
  LogoSetFiles(file_names);
  LogoSetPosition(position_x, position_y);
  LogoSetOpacity(opacity);
  LogoSetDelay(delay_ms);
  LogoSetRepeat(loop);
  LogoSetEnable(1);
end;

procedure TFmxPasLibVlcPlayer.LogoShowFiles(file_names : array of WideString; position: libvlc_position_t = libvlc_position_top; opacity: libvlc_opacity_t = libvlc_opacity_full; delay_ms : Integer = 1000; loop : Boolean = TRUE);
begin
  LogoSetFiles(file_names);
  LogoSetPosition(position);
  LogoSetOpacity(opacity);
  LogoSetDelay(delay_ms);
  LogoSetRepeat(loop);
  LogoSetEnable(1);
end;

procedure TFmxPasLibVlcPlayer.LogoHide();
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_logo_int   (p_mi, libvlc_logo_Enable, 1); // not work
  libvlc_video_set_logo_string(p_mi, libvlc_logo_File,   NIL); // this work
end;

////////////////////////////////////////////////////////////////////////////////
//
// https://wiki.videolan.org/Documentation:Modules/marq/
//
////////////////////////////////////////////////////////////////////////////////

procedure TFmxPasLibVlcPlayer.MarqueeSetText(marquee_text : WideString);
begin
  if not Assigned(p_mi) then exit;
  if (marquee_text = '') then libvlc_video_set_marquee_string(p_mi, libvlc_marquee_Text, NIL)
  else libvlc_video_set_marquee_string(p_mi, libvlc_marquee_Text, PAnsiChar(UTF8Encode(marquee_text)));
end;

procedure TFmxPasLibVlcPlayer.MarqueeSetPosition(position_x, position_y : Integer);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_marquee_int(p_mi, libvlc_marquee_X, position_x);
  libvlc_video_set_marquee_int(p_mi, libvlc_marquee_Y, position_y);
end;

procedure TFmxPasLibVlcPlayer.MarqueeSetPosition(position : libvlc_position_t);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_marquee_int(p_mi, libvlc_marquee_Position, Ord(position));
end;

procedure TFmxPasLibVlcPlayer.MarqueeSetColor(color : libvlc_video_marquee_color_t);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_marquee_int(p_mi, libvlc_marquee_Color, color);
end;

procedure TFmxPasLibVlcPlayer.MarqueeSetFontSize(font_size: Integer);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_marquee_int(p_mi, libvlc_marquee_Size, font_size);
end;

procedure TFmxPasLibVlcPlayer.MarqueeSetOpacity(opacity: libvlc_opacity_t);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_marquee_int(p_mi, libvlc_marquee_Opacity, opacity);
end;

procedure TFmxPasLibVlcPlayer.MarqueeSetTimeOut(time_out_ms: Integer);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_marquee_int(p_mi, libvlc_marquee_Timeout, time_out_ms);
end;

procedure TFmxPasLibVlcPlayer.MarqueeSetRefresh(refresh_after_ms: Integer);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_marquee_int(p_mi, libvlc_marquee_Refresh, refresh_after_ms);
end;

procedure TFmxPasLibVlcPlayer.MarqueeSetEnable(enable : Integer);
begin
  if not Assigned(p_mi) then exit;
  libvlc_video_set_marquee_int(p_mi, libvlc_marquee_Enable, enable); // not work
end;

procedure TFmxPasLibVlcPlayer.MarqueeShowText(marquee_text : WideString; position_x, position_y : Integer; color : libvlc_video_marquee_color_t = libvlc_video_marquee_color_White; font_size: Integer = libvlc_video_marquee_default_font_size; opacity: libvlc_opacity_t = libvlc_opacity_full; time_out_ms: Integer = 0);
begin
  MarqueeSetText(marquee_text);
  MarqueeSetPosition(position_x, position_y);
  MarqueeSetColor(color);
  MarqueeSetOpacity(opacity);
  MarqueeSetFontSize(font_size);
  MarqueeSetTimeOut(time_out_ms); // hide after timeout ms, 0 - show always
  MarqueeSetRefresh(0);
  MarqueeSetEnable(1);

  // handle dynamic strings in form %H:%M:%S
  if (Pos(WideString('%H'), marquee_text) > 0) then MarqueeSetRefresh(3600 * 1000);
  if (Pos(WideString('%M'), marquee_text) > 0) then MarqueeSetRefresh(  60 * 1000);
  if (Pos(WideString('%S'), marquee_text) > 0) then MarqueeSetRefresh(       1000);
end;

procedure TFmxPasLibVlcPlayer.MarqueeShowText(marquee_text : WideString; position : libvlc_position_t = libvlc_position_bottom; color : libvlc_video_marquee_color_t = libvlc_video_marquee_color_White; font_size: Integer = libvlc_video_marquee_default_font_size; opacity: libvlc_opacity_t = libvlc_opacity_full; time_out_ms: Integer = 0);
begin
  MarqueeSetText(marquee_text);
  MarqueeSetPosition(position);
  MarqueeSetColor(color);
  MarqueeSetOpacity(opacity);
  MarqueeSetFontSize(font_size);
  MarqueeSetTimeOut(time_out_ms); // hide after timeout ms, 0 - show always
  MarqueeSetRefresh(0);
  MarqueeSetEnable(1);

  // handle dynamic strings in form %H:%M:%S
  if (Pos(WideString('%H'), marquee_text) > 0) then MarqueeSetRefresh(3600 * 1000);
  if (Pos(WideString('%M'), marquee_text) > 0) then MarqueeSetRefresh(  60 * 1000);
  if (Pos(WideString('%S'), marquee_text) > 0) then MarqueeSetRefresh(       1000);
end;

procedure TFmxPasLibVlcPlayer.MarqueeHide();
begin
  MarqueeSetEnable(0);
  MarqueeSetRefresh(0);
  MarqueeSetText('');
end;

////////////////////////////////////////////////////////////////////////////////


procedure TFmxPasLibVlcPlayer.InternalHandleEvent_MediaChanged(p_md : libvlc_media_t_ptr);
var
  tmp  : PAnsiChar;
  mrl  : string;
begin
  if Assigned(FOnMediaPlayerMediaChanged) then
  begin
    if (p_md <> NIL) then
    begin
      tmp := libvlc_media_get_mrl(p_md);
      mrl := UTF8ToWideString(tmp);
    end
    else
    begin
      mrl := '';
    end;
    FOnMediaPlayerMediaChanged(SELF, mrl);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_NothingSpecial();
begin
  if Assigned(FOnMediaPlayerNothingSpecial) then
    FOnMediaPlayerNothingSpecial(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_Opening();
begin
  if Assigned(FOnMediaPlayerOpening) then
    FOnMediaPlayerOpening(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_Buffering();
begin
  if Assigned(FOnMediaPlayerBuffering) then
    FOnMediaPlayerBuffering(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_Playing();
begin
  if Assigned(FOnMediaPlayerPlaying) then
    FOnMediaPlayerPlaying(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_Paused();
begin
  if Assigned(FOnMediaPlayerPaused) then
    FOnMediaPlayerPaused(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_Stopped();
begin
  if Assigned(FOnMediaPlayerStopped) then
    FOnMediaPlayerStopped(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_Forward();
begin
  if Assigned(FOnMediaPlayerForward) then
    FOnMediaPlayerForward(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_Backward();
begin
  if Assigned(FOnMediaPlayerBackward) then
    FOnMediaPlayerBackward(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_EndReached();
begin
  if Assigned(FOnMediaPlayerEndReached) then
    FOnMediaPlayerEndReached(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_EncounteredError();
var
  tmp : PAnsiChar;
begin
  tmp := libvlc_errmsg();
  if (tmp <> NIL) then
  begin
    FError := UTF8ToWideString(tmp);
  end
  else
  begin
    FError := '';
  end;
  
  if Assigned(FOnMediaPlayerEncounteredError) then
    FOnMediaPlayerEncounteredError(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_TimeChanged(new_time : libvlc_time_t);
begin
  if Assigned(FOnMediaPlayerTimeChanged) then
  begin
    FOnMediaPlayerTimeChanged(SELF, new_time);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_PositionChanged(new_position : Single);
begin
  if Assigned(FOnMediaPlayerPositionChanged) then
  begin
    FOnMediaPlayerPositionChanged(SELF, new_position);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_SeekableChanged(new_seekable : Integer);
begin
  if Assigned(FOnMediaPlayerSeekableChanged) then
  begin
    FOnMediaPlayerSeekableChanged(SELF, new_seekable <> 0);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_PausableChanged(new_pausable : Integer);
begin
  if Assigned(FOnMediaPlayerPausableChanged) then
  begin
    FOnMediaPlayerPausableChanged(SELF, new_pausable <> 0);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_TitleChanged(new_title : Integer);
begin
  if Assigned(FOnMediaPlayerTitleChanged) then
  begin
    FOnMediaPlayerTitleChanged(SELF, new_title);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_SnapshotTaken(psz_filename : PAnsiChar);
begin
  if Assigned(FOnMediaPlayerSnapshotTaken) then
  begin
    FOnMediaPlayerSnapshotTaken(SELF, UTF8ToWideString(psz_filename));
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_LengthChanged(new_length : libvlc_time_t);
begin
  if Assigned(FOnMediaPlayerLengthChanged) then
  begin
    FOnMediaPlayerLengthChanged(SELF, new_length);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_VOutChanged(new_count : Integer);
begin
  if Assigned(FOnMediaPlayerVideoOutChanged) then
  begin
    FOnMediaPlayerVideoOutChanged(SELF, new_count);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_ScrambledChanged(new_scrambled : Integer);
begin
  if Assigned(FOnMediaPlayerScrambledChanged) then
  begin
    FOnMediaPlayerScrambledChanged(SELF, new_scrambled);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_Corked();
begin
  if Assigned(FOnMediaPlayerCorked) then
    FOnMediaPlayerCorked(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_UnCorked();
begin
  if Assigned(FOnMediaPlayerUnCorked) then
    FOnMediaPlayerUnCorked(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_Muted();
begin
  if Assigned(FOnMediaPlayerMuted) then
    FOnMediaPlayerMuted(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_Unmuted();
begin
  if Assigned(FOnMediaPlayerUnMuted) then
    FOnMediaPlayerUnMuted(SELF);
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_AudioVolumeChanged(volume : Single);
begin
  if Assigned(FOnMediaPlayerAudioVolumeChanged) then
  begin
    FOnMediaPlayerAudioVolumeChanged(SELF, volume);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_VideoSizeChanged(video_w, video_h, video_w_a32, video_h_a32 : LongWord);
begin
  if Assigned(FOnMediaPlayerVideoSizeChanged) then
  begin
    FOnMediaPlayerVideoSizeChanged(SELF, video_w, video_h, video_w_a32, video_h_a32);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_MediaPlayerEsAdded(i_type : libvlc_track_type_t; i_id : Integer);
begin
  if Assigned(FOnMediaPlayerEsAdded) then
  begin
    FOnMediaPlayerEsAdded(SELF, i_type, i_id);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_MediaPlayerEsDeleted(i_type : libvlc_track_type_t; i_id : Integer);
begin
  if Assigned(FOnMediaPlayerEsDeleted) then
  begin
    FOnMediaPlayerEsDeleted(SELF, i_type, i_id);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_MediaPlayerEsSelected(i_type : libvlc_track_type_t; i_id : Integer);
begin
  if Assigned(FOnMediaPlayerEsSelected) then
  begin
    FOnMediaPlayerEsSelected(SELF, i_type, i_id);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_MediaPlayerAudioDevice(audio_device : PAnsiChar);
begin
  if Assigned(FOnMediaPlayerAudioDevice) then
  begin
    FOnMediaPlayerAudioDevice(SELF, UTF8ToWideString(audio_device));
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_MediaPlayerChapterChanged(chapter : Integer);
begin
  if Assigned(FOnMediaPlayerChapterChanged) then
  begin
    FOnMediaPlayerChapterChanged(SELF, chapter);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_RendererDiscoveredItemAdded(item : libvlc_renderer_item_t_ptr);
begin
  if Assigned(FOnRendererDiscoveredItemAdded) then
  begin
    FOnRendererDiscoveredItemAdded(SELF, item);
  end;
end;

procedure TFmxPasLibVlcPlayer.InternalHandleEvent_RendererDiscoveredItemDeleted(item : libvlc_renderer_item_t_ptr);
begin
  if Assigned(FOnRendererDiscoveredItemDeleted) then
  begin
    FOnRendererDiscoveredItemDeleted(SELF, item);
  end;
end;

procedure TFmxPasLibVlcPlayer.Paint;
var
  bmp      : TBitmap;
  bmd      : TBitmapData;
  src_buff : PByte;
  dst_buff : PByte;
  pitch    : LongWord;
  video_l  : LongWord;
begin
  inherited Paint;

  if (FVideoCbCtx = NIL) then exit;

  with FVideoCbCtx do
  begin
    with vctx do
    begin
      bmp := TBitmap.Create(video_w, video_h);
      frame_lock.Enter();
      try
        if (frame_buff <> NIL) then
        begin
          if bmp.Map(TMapAccess.Write, bmd) then
          begin
            src_buff := frame_buff;
            dst_buff := bmd.GetScanline(0);
            if (video_h = LongWord(bmd.Height)) and (LongWord(bmd.Pitch) = pitch_w_a32) then
            begin
              System.Move(src_buff^, dst_buff^, bmd.Pitch * bmd.Height);
            end
            else
            begin
              pitch := pitch_w_a32;
              if (Integer(pitch) > bmd.Pitch) then
              begin
                pitch := bmd.Pitch;
              end;

              video_l := video_h;
              if (Integer(video_l) > bmd.Height) then
              begin
                video_l := bmd.Height;
              end;

              while (video_l > 0) do
              begin
                System.Move(src_buff^, dst_buff^, pitch);
                Inc(src_buff, pitch_w_a32);
                Inc(dst_buff, bmd.Pitch);
                Dec(video_l);
              end;
            end;
            bmp.Unmap(bmd);
          end;
        end
        else
        begin
          bmp.Clear(TAlphaColorRec.Black);
        end;
      finally
        frame_lock.Leave();
      end;
      Bitmap.Assign(bmp);
      FreeAndNil(bmp);
    end;
  end;

end;

////////////////////////////////////////////////////////////////////////////////

function fmx_libvlc_video_lock_cb(ptr : Pointer; planes : PVCBPlanes) : Pointer; cdecl;
var
  ctx  : TFmxPasLibVlcVideoCbCtx;
  pIdx : Integer;
begin
  Result := NIL;
  if (ptr = NIL) then exit;

  ctx := TFmxPasLibVlcVideoCbCtx(ptr);

  with ctx do
  begin
    with vctx do
    begin
      lock.Enter();
      for pIdx := 0 to VOUT_MAX_PLANES - 1 do
      begin
        planes^[pIdx] := buff_a32[pIdx];
      end;
      Result := buff_a32[0];
    end;
  end;
end;

procedure fmx_libvlc_video_unlock_cb(ptr : Pointer; picture : Pointer; planes : PVCBPlanes); cdecl;
var
  ctx : TFmxPasLibVlcVideoCbCtx;
begin
  if (ptr = NIL) then exit;

  ctx := TFmxPasLibVlcVideoCbCtx(ptr);

  with ctx do
  begin
    with vctx do
    begin
      lock.Leave();
    end;
  end;

end;

procedure fmx_libvlc_video_display_cb(ptr : Pointer; picture : Pointer); cdecl;
var
  ctx : TFmxPasLibVlcVideoCbCtx;
begin
  if (ptr = NIL) then exit;

  ctx := TFmxPasLibVlcVideoCbCtx(ptr);

  with ctx do
  begin
    with vctx do
    begin

      if frame_lock.TryEnter() then
      begin
        try
          // RV32, RGBA, BGRA we show only first plane
          if (frame_buff <> NIL) then
          begin
            if (buff_a32[0] <> NIL) then
            begin
              Move(buff_a32[0]^, frame_buff^, pitch_w_a32 * video_h);
            end;
          end;

        finally
          frame_lock.Leave();
        end;

        if (view <> NIL) then
        begin
          view.InvalidateRect(view.BoundsRect);
        end;
      end;
    end;
  end;

end;

function fmx_libvlc_video_format_cb(var ptr : Pointer; chroma : PAnsiChar; var width : LongWord; var height : LongWord; pitches : PVCBPitches; lines : PVCBLines) : LongWord; cdecl;
const
  // src/misc/fourcc.c: fourcc helpers functions
  PixelFormatChromas: array[FMX.Types.TPixelFormat] of string[4] = (
    { None      0}'RV32',
    { RGB       4}'RV32',
    { RGBA      4}'RGBA', // OSX 10.7.5, 32bits
    { BGR       4}'RV32',
    { BGRA      4}'BGRA', // Windows 7, 32bits
    { RGBA16    8}'RV32',
    { BGR_565   2}'RV32',
    { BGRA4     2}'RV32',
    { BGR4      2}'RV32',
    { BGR5_A1   2}'RV32',
    { BGR5      2}'RV32',
    { BGR10_A2  4}'RV32',
    { RGB10_A2  4}'RV32',
    { L         1}'RV32',
    { LA        2}'RV32',
    { LA4       1}'RV32',
    { L16       2}'RV32',
    { A         1}'RV32',
    { R16F      2}'RV32',
    { RG16F     4}'RV32',
    { RGBA16F   8}'RV32',
    { R32F      4}'RV32',
    { RG32F     8}'RV32',
    { RGBA32F  16}'RV32'
  );
type
  PChromaStr = ^TChromaStr;
  TChromaStr = packed array[0..3] of AnsiChar;
var
  ctx          : TFmxPasLibVlcVideoCbCtx;
  idx          : Integer;
begin
  Result := 0;

  if (ptr = NIL) then exit;

  ctx := TFmxPasLibVlcVideoCbCtx(ptr);

  with ctx do
  begin

    for idx := 1 to 4 do
    begin
      PChromaStr(chroma)^[idx-1] := AnsiChar(PixelFormatChromas[frame_pixel_format][idx]);
    end;

    with vctx do
    begin
      lock.Enter();

      try

        libvlc_video_cb_vctx_set_buffers(@vctx, width, height, PixelFormatBytes[frame_pixel_format], pitches, lines);

        frame_lock.Enter();

        try

          if (frame_buff <> NIL) then
          begin
            FreeMem(frame_buff);
            frame_buff := NIL;
          end;

          GetMem(frame_buff, pitch_w_a32 * video_h_a32);

        finally
          frame_lock.Leave();
        end;

        (view as TFmxPasLibVlcPlayer).InternalHandleEvent_VideoSizeChanged(video_w, video_h, video_w_a32, video_h_a32);

        if (view <> NIL) then
        begin
          view.InvalidateRect(view.BoundsRect);
        end;

      finally
        lock.Leave();
      end;

    end; // with vctx do

  end; // with ctx do

  Result := 1;
end;

procedure fmx_libvlc_video_cleanup_cb(ptr : Pointer); cdecl;
var
  ctx : TFmxPasLibVlcVideoCbCtx;
begin
  if (ptr = NIL) then exit;

  ctx := TFmxPasLibVlcVideoCbCtx(ptr);

  with ctx do
  begin

    with vctx do
    begin

      lock.Enter();

      try

        libvlc_video_cb_vctx_clr_buffers(@vctx);

        frame_lock.Enter();

        try

          if (frame_buff <> NIL) then
          begin
            FreeMem(frame_buff);
            frame_buff := NIL;
          end;

        finally
          frame_lock.Leave();
        end;

      finally
        lock.Leave();
      end

    end; // with vctx do

  end; // with ctx do

end;

procedure fmx_lib_vlc_player_event_hdlr(p_event: libvlc_event_t_ptr; data: Pointer); cdecl;
var
  player: TFmxPasLibVlcPlayer;
begin
  if (data = NIL) then exit;

  player := TFmxPasLibVlcPlayer(data);

  if not Assigned(player) then exit;

  if Assigned(player.FOnMediaPlayerEvent) then
    player.FOnMediaPlayerEvent(p_event, data);

  with p_event^ do
  begin
    case event_type of
      libvlc_MediaPlayerMediaChanged:
        player.InternalHandleEvent_MediaChanged(media_player_media_changed.new_media);

      libvlc_MediaPlayerTimeChanged:
        player.InternalHandleEvent_TimeChanged(media_player_time_changed.new_time);

      libvlc_MediaPlayerSnapshotTaken:
        player.InternalHandleEvent_SnapshotTaken(media_player_snapshot_taken.psz_filename);

      libvlc_MediaPlayerLengthChanged:
        player.InternalHandleEvent_LengthChanged(media_player_length_changed.new_length);

      libvlc_MediaPlayerPositionChanged:
        player.InternalHandleEvent_PositionChanged(media_player_position_changed.new_position);

      libvlc_MediaPlayerSeekableChanged:
        player.InternalHandleEvent_SeekableChanged(media_player_seekable_changed.new_seekable);

      libvlc_MediaPlayerPausableChanged:
        player.InternalHandleEvent_PausableChanged(media_player_pausable_changed.new_pausable);

      libvlc_MediaPlayerTitleChanged:
        player.InternalHandleEvent_TitleChanged(media_player_title_changed.new_title);

      libvlc_MediaPlayerNothingSpecial:
        player.InternalHandleEvent_NothingSpecial();

      libvlc_MediaPlayerOpening:
        player.InternalHandleEvent_Opening();

      libvlc_MediaPlayerBuffering:
        player.InternalHandleEvent_Buffering();

      libvlc_MediaPlayerPlaying:
        player.InternalHandleEvent_Playing();

      libvlc_MediaPlayerPaused:
        player.InternalHandleEvent_Paused();

      libvlc_MediaPlayerStopped:
        player.InternalHandleEvent_Stopped();

      libvlc_MediaPlayerForward:
        player.InternalHandleEvent_Forward();

      libvlc_MediaPlayerBackward:
        player.InternalHandleEvent_Backward();

      libvlc_MediaPlayerEndReached:
        player.InternalHandleEvent_EndReached();

      libvlc_MediaPlayerEncounteredError:
        player.InternalHandleEvent_EncounteredError();

      libvlc_MediaPlayerVout:
        player.InternalHandleEvent_VoutChanged(media_player_vout.new_count);

      libvlc_MediaPlayerScrambledChanged:
        player.InternalHandleEvent_ScrambledChanged(media_player_scrambled_changed.new_scrambled);

      libvlc_MediaPlayerCorked:
        player.InternalHandleEvent_Corked();

      libvlc_MediaPlayerUncorked:
        player.InternalHandleEvent_Uncorked();

      libvlc_MediaPlayerMuted:
        player.InternalHandleEvent_Muted();

      libvlc_MediaPlayerUnmuted:
        player.InternalHandleEvent_Unmuted();

      libvlc_MediaPlayerAudioVolume:
        player.InternalHandleEvent_AudioVolumeChanged(media_player_audio_volume.volume);

      libvlc_MediaPlayerESAdded:
        player.InternalHandleEvent_MediaPlayerEsAdded(media_player_es_changed.i_type, media_player_es_changed.i_id);

      libvlc_MediaPlayerESDeleted:
        player.InternalHandleEvent_MediaPlayerEsDeleted(media_player_es_changed.i_type, media_player_es_changed.i_id);

      libvlc_MediaPlayerESSelected:
        player.InternalHandleEvent_MediaPlayerEsSelected(media_player_es_changed.i_type, media_player_es_changed.i_id);

      libvlc_MediaPlayerAudioDevice:
        player.InternalHandleEvent_MediaPlayerAudioDevice(media_player_audio_device.device);

      libvlc_MediaPlayerChapterChanged:
        player.InternalHandleEvent_MediaPlayerChapterChanged(media_player_chapter_changed.new_chapter);

      libvlc_RendererDiscovererItemAdded:
        player.InternalHandleEvent_RendererDiscoveredItemAdded(renderer_discoverer_item_added.item);

      libvlc_RendererDiscovererItemDeleted:
        player.InternalHandleEvent_RendererDiscoveredItemDeleted(renderer_discoverer_item_deleted.item);

    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TFmxPasLibVlcVideoCbCtx.Create(AView : FMX.Objects.TImage; aWidth : Integer = 320; aHeight : Integer = 160);
var
  bmpt : TBitmap;
  bmpd : TBitmapData;
begin
  inherited Create;

  frame_lock := TCriticalSection.Create;

  with vctx do
  begin
    lock := TCriticalSection.Create;
    libvlc_video_cb_vctx_set_buffers(@vctx, aWidth, aHeight);
  end;

  GetMem(frame_buff, vctx.pitch_w_a32 * vctx.video_h_a32);

  view := AView;

  frame_pixel_format := TPixelFormat.BGRA;

  bmpt := TBitmap.Create(vctx.video_w_a32, vctx.video_h_a32);
  bmpt.Clear(TAlphaColorRec.Black);
  if (bmpt.Map(TMapAccess.Read, bmpd)) then
  begin
    frame_pixel_format := bmpd.PixelFormat;
    System.Move(bmpd.GetScanline(0)^, frame_buff^, vctx.pitch_w_a32 * vctx.video_h_a32);
    bmpt.Unmap(bmpd);
  end;
  FreeAndNil(bmpt);
end;

destructor TFmxPasLibVlcVideoCbCtx.Destroy;
begin
  view := NIL;

  FreeAndNil(frame_lock);

  if (frame_buff <> NIL) then
  begin
    FreeMem(frame_buff);
    frame_buff := NIL;
  end;

  libvlc_video_cb_vctx_clr_buffers(@vctx);

  with vctx do
  begin
    FreeAndNil(lock);
  end;

  inherited Destroy;
end;

initialization

finalization

end.
