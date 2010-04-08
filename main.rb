#!/usr/bin/env ruby
# kate: remove-trailing-space on; replace-trailing-space-save on; indent-width 2; indent-mode ruby; syntax ruby;

require 'korundum4'

require 'phonon'

=begin
Dragon::VolumeAction::VolumeAction( QObject *receiver, const char *slot, KActionCollection *ac )
        : KToggleAction( i18nc( "Volume of sound output", "Volume"), ac )
{
    setObjectName( "volume" );
    setIcon( KIcon( "player-volume" ) );
    setShortcut( Qt::Key_V );
    ac->addAction( objectName(), this );
    connect( this, SIGNAL( triggered( bool ) ), receiver, slot );
    connect( engine(), SIGNAL( mutedChanged( bool ) ), this, SLOT( mutedChanged( bool ) ) );
}

void
Dragon::VolumeAction::mutedChanged( bool mute )
{
    if( mute )
        setIcon( KIcon( "player-volume-muted" ) );
    else
        setIcon( KIcon( "player-volume" ) );
}
=end

module KDE
  class ToogleAction < KDE::Action
  end
end

module MT
  class VolumeAction < KDE::ToogleAction

    slots 'muted_changed(bool)'

    def initialize *args
      super

      set_object_name 'volume'
      set_icon KDE::Icon.new 'player-volume'
      set_shortcut KDE::Shortcut.new Qt::Key_V
    end

    def muted_changed mute
      set_icon KDE::Icon.new mute ? 'player-volume-muted' : 'player-volume'
    end

  end

=begin
    muteAction = new KAction(i18nc("'Audio' menu", "Mute Volume"), this);
    mutedIcon = KIcon("audio-volume-muted");
    unmutedIcon = KIcon("audio-volume-medium");
    muteAction->setIcon(unmutedIcon);
    muteAction->setShortcut(KShortcut(Qt::Key_M, Qt::Key_VolumeMute));
=end
#   class MuteAction < KDE::ToogleAction
#     slots 'is_muted(bool)'
#
#     def initialize *args
#       super *args
#
#       set_object_name 'mutedAction'
#       set_shortcut KDE::Shortcut.new Qt::Key_M, Qt::Key_VolumeMute
#       set_text = i18n 'Mute Volume'
#       connect SIGNAL :triggered, self, SLOT
#
#     def is_muted muted
#
#     end
#   end
end

class Video < Qt::Object
  attr_accessor :author, :title, :description, :webpage, :duration, :views, \
                :published_datetime
  attr_reader :thumbnailUrls, :thumbnail, :hd_enabled
  slots 'set_thumbnail(QByteArray)', 'got_video_info(QByteArray)', \
        'error_video_info(QNetworkReply)', 'scrap_web_page(QByteArray)', \
        'got_hd_headers(QNetworkReply)'

  def initialize *args
    super *args

    @view = nil
    @duration = 0
    @hd_enabled = nil
    @thumbnailUrls = Array.new # expects QUrl elements
    @thumbnail = nil
  end

  def push_thumbnailUrl url
    @thumbnailUrls.push url
  end

  def preload_thumbnail
    unless @thumbnailUrls.empty?
      #...
    end
  end

  def load_stream_url
  end

  def set_thumbnail str # slot
  end

  private

  def got_video_info str # slot
  end

  def error_video_info networkReply # slot
  end

  def scrap_web_page str # slot
  end

  def got_hd_headers networkReply # slot
  end

end

class VideoMimeData < Qt::MimeData
  attr_reader :videos

  def initialize *args
    super *args

    @videos = Array.new # expects Video elements
  end

  def push_video video
    @videos.push video
  end

  MIME_TYPE = 'application/x-minitube-video'

  def has_video_mimetype? mimeType
    mimeType == MIME_TYPE
  end

#   alias formats_QMimeData formats

  def formats
#     formats = formats_QMimeData # is QStringList
#     formats.push MIME_TYPE
    [MIME_TYPE]
  end


end
class CustomWidget < KDE::MainWindow

  slots 'toogleVolumeSlider(bool)', 'setFullScreen(bool)', 'pausedChanged(bool)'

  def addAction action
    @actionCollection.addAction action.object_name, action
  end

  def toogleVolumeSlider show
  end


  def setFullScreen full
  end

  def pausedChanged paused
  end

  def ini_phonon
    @videoPlayer = Phonon::VideoPlayer.new Phonon::VideoCategory, self

    @seekSlider = Phonon::SeekSlider.new @videoPlayer.mediaObject, self

    @volumeSlider = Phonon::VolumeSlider.new @videoPlayer.audioOutput, self
    @volumeSlider.setMuteVisible false

    @muteAction = KDE::Action.new KDE::Icon.new( 'audio-volume-medium' ), i18n( 'Mute Volume' ), self
    @actionCollection.addAction 'volume-mute', @muteAction
    @muteAction.checkable = true
    @muteAction.connect( SIGNAL('toggled(bool)') ) do |muted|
      @muteAction.set_icon KDE::Icon.new muted ? 'audio-volume-muted' : 'audio-volume-medium'
      @videoPlayer.audioOutput.muted = muted
    end
#     connect @muteAction, SIGNAL('toggled(bool)'), @videoPlayer.audioOutput, SLOT('setMuted(bool)')
  end

  def initialize

    super

#     @config = KDE::Global.config
#     configGroup = @config.group "Settings"
#     b = Qt::DateTime.currentDateTime
#     a = configGroup.readEntry "time", b
#     puts "was: " + a.toString
#     puts "now: " + b.toString
#     configGroup.writeEntry "time", b
#     @config.sync


    ##### Prepare Central Widget
#     @centralwidget = KDE::TextEdit.new self
    @actionCollection = KDE::ActionCollection.new self
    ini_phonon
    setCentralWidget @videoPlayer

#     @mediaObject = Phonon::MediaObject.new self
#     @mediaObject.setCurrentSource Phonon::MediaSource.new('/home/rriemann/Documents/Videos/Sita_Sings_the_Blues.ogv')
#     @centralwidget.play @mediaObject
    @videoPlayer.play Phonon::MediaSource.new('/home/rriemann/Documents/Videos/Sita_Sings_the_Blues.ogv')
#       @centralwidget.play Phonon::MediaSource.new('http://videos.mozilla.org/firefox/3.6/meetfirefox/FF3.6_Screencast_FINAL.ogv')

    #### prepare menus

    menu = KDE::Menu.new i18n('&File'), self
    menuBar.addMenu menu
    playerMenu = KDE::Menu.new i18n('&Play'), self
    menuBar.addMenu playerMenu
    controlBar = KDE::ToolBar.new 'control_bar', self, Qt::BottomToolBarArea

    ##### Prepare the Actions

#     volumeAction = MT::VolumeAction.new i18nc( 'Volume of sound output', 'Volume' ), @actionCollection
#     addAction volumeAction

    closeAction = KDE::StandardAction::quit( self, SLOT( :close ), @actionCollection )
    menu.addAction closeAction
    controlBar.addAction closeAction

    actionPrevious = KDE::Action.new KDE::Icon.new( 'media-skip-backward' ), i18n( 'Previous' ), self
    actionPrevious.set_shortcut KDE::Shortcut.new Qt::Key_PageUp, Qt::Key_MediaPrevious
    @actionCollection.add_action 'controls_previous', actionPrevious
    playerMenu.add_action actionPrevious
    controlBar.add_action actionPrevious

    @actionPlayPause = KDE::Action.new self
    @actionPlayPause.checkable = true
    Qt::Object.connect(@actionPlayPause, SIGNAL('triggered(bool)'), self, SLOT('pausedChanged(bool)'))
    @statusPause = [ KDE::Icon.new( 'media-playback-pause' ), i18n( 'Pause' ) ]
    @statusPlay = [ KDE::Icon.new( 'media-playback-start' ), i18n( 'Plaz' ) ]
    @actionPlayPause.set_shortcut KDE::Shortcut.new( Qt::Key_Backspace, Qt::Key_MediaStop )
    @actionCollection.add_action 'controls_play_pause', @actionPlayPause
    playerMenu.add_action @actionPlayPause
    controlBar.add_action @actionPlayPause

    actionStop = KDE::Action.new KDE::Icon.new( 'media-playback-stop' ), i18n( 'Stop' ), self
    actionStop.set_shortcut KDE::Shortcut.new Qt::Key_Backspace, Qt::Key_MediaStop
    @actionCollection.add_action 'controls_stop', actionStop
    playerMenu.add_action actionStop
    controlBar.add_action actionStop

    actionForward = KDE::Action.new KDE::Icon.new( 'media-skip-forward' ), i18n( 'Forward' ), self
    actionForward.set_shortcut KDE::Shortcut.new Qt::Key_PageUp, Qt::Key_MediaPrevious
    @actionCollection.add_action 'controls_forward', actionForward
    playerMenu.add_action actionForward
    controlBar.add_action actionForward

    playerMenu.add_separator

    actionFullScreen = KDE::Action.new KDE::Icon.new( 'view-fullscreen' ), i18n( 'Full Screen Mode' ), self
    actionFullScreen.set_shortcut KDE::Shortcut.new Qt::Key_F
    @actionCollection.add_action 'view_fullscren', actionFullScreen
    playerMenu.add_action actionFullScreen
#     controlBar.add_action actionFullScreen

    playerMenu.add_separator

    audioMenu = KDE::Menu.new i18nc( 'Playback menu', 'Audio' ), self
    playerMenu.add_menu audioMenu


    audioMenu.add_action @muteAction
    controlBar.add_action @muteAction

    volumeSliderAction = KDE::Action.new i18n( 'Volume Slider' ), self
    volumeSliderAction.default_widget = @volumeSlider
    @actionCollection.add_action 'controls_volume_slider', volumeSliderAction
    controlBar.add_action volumeSliderAction

    positionSlider = KDE::Action.new i18n( 'Position Slider' ), self
    positionSlider.default_widget = @seekSlider
    @actionCollection.add_action 'controls_position_slider', positionSlider
    controlBar.add_action positionSlider




    @actionCollection.associate_widget self
    @actionCollection.read_settings
    set_auto_save_settings

    menuBar.show
    controlBar.show


    controlBar.set_tool_button_style Qt::ToolButtonIconOnly


#     @actionQuit = KDE::Action.new( self ) {
#       setIcon KDE::Icon.new "application-exit"
#     }
#     connect( @actionQuit, SIGNAL( :triggered ), SLOT( :close ) )

#     ##### Prepare the Menu
#     @menuBar = menuBar
#     @menuFile = Qt::Menu.new @menuBar
#     @menuFile.addAction @actionQuit
#     @menuBar.addAction @menuFile.menuAction
#     @helpMenu = helpMenu
#     @menuBar.addAction @helpMenu.menuAction
#
#     setMenuBar(@menuBar)
#
#     ##### Prepare Statusbar
#     @statusBar = statusBar
#     setStatusBar @statusBar
#
    ##### Prepare Toolbar
#     @toolBar = toolBar
#     @toolBar.addAction @actionQuit
#     addToolBar(Qt::TopToolBarArea, @toolBar)



    retranslateUi

    self.show
  end

  def retranslateUi
#     @menuFile.title = i18n "File"
    setWindowTitle i18n "MainWindow"
    # @statusBar.showMessage i18n "Loading"
#     @actionQuit.text = i18n "Quit"
#     @actionQuit.shortcut =  KDE::Shortcut.new i18nc( "Quit", "Ctrl+Q" )
  end

  private :setFullScreen

end

if $0 == __FILE__

  about = KDE::AboutData.new(
    "kminitube",                           # internal application name
    # language catlog name for i10n (konqueror's catalog for the beginning is better than no catalog)
    "konqueror",
    KDE.ki18n("KMiniTube"),                 # application name in the about menu and everywhere else
    "0.1",                             # application version
    KDE::ki18n("A Tool to easily create HTML formatted Code"),  # short description
    KDE::AboutData::License_GPL_V3,    # license
    KDE::ki18n("(c) 1999-2000, Name"), # copyright info
    # text in the about box - maybe with \n line breaks
    KDE::ki18n("just some text in the about box"),
    # project homepage and eMail adress for bug reports - attention: homepage changes standard dbus/dcop name!
    "http://homepage.de", "bugs@homepage.de" )
  about.setProgramIconName  "plasma" # use the plasma-icon instead of question mark

  KDE::CmdLineArgs.init(ARGV, about)

#   unless KDE::UniqueApplication.start
#     STDERR.puts "is already running."
#   else
#     a = KDE::UniqueApplication.new
#     w = CustomWidget.new
#     a.exec
#   end
  a = KDE::Application.new
  w = CustomWidget.new
  a.exec
end