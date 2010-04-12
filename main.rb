#!/usr/bin/env ruby1.9
# kate: remove-trailing-space on; replace-trailing-space-save on; indent-width 2; indent-mode ruby; syntax ruby;

require 'korundum4'
require 'phonon'
require 'json'
require 'net/http'
require 'cgi'

class Video < Qt::Object

  slots 'get_thumbnail()', 'get_video()', 'get_video_link()', 'destroy_video()'
  signals 'got_thumbnail(bool)', 'loading_video(bool)', 'got_video_link(bool)'

  def initialize entry
    @id = entry["id"]["$t"]
    @published = entry["published"]["$t"]
    @updated = entry["updated"]["$t"]
    @title = entry["title"]["$t"]
    @author = entry["author"][0]["name"]["$t"]
    @author_uri = entry["author"][0]["uri"]["$t"]
    @link = entry["link"][0]["href"] # "rel"=>"alternate"
    @video_url = nil
    @video = nil
    @link_responses = entry["link"][1]["href"] # "rel"=>"responses", xml-file
    @link_related = entry["link"][2]["href"] # "rel"=>"related", xml-file
    @duration = entry["media$group"]["yt$duration"]["seconds"]
    @thumbnail_url = entry["media$group"]["media$thumbnail"][-1]["url"]
    @thumbnail = nil
    @description = entry["content"]["$t"]
  end

  def get_thumbnail
    res = false
    emit got_thumbnail res
  end

  def get_video_link
    unless @video_url == false
      msg = `python youtube-dl -gb #{@link}`.strip # e= title, b=best quality, g = url
      @video_url = (msg =~ /ERROR/) ? false : msg
    end
    emit got_video_link( @video_url != false )
  end
end

class CustomWidget < KDE::MainWindow

  slots 'toogleVolumeSlider(bool)', 'setFullScreen(bool)', \
        'stateChanged(Phonon::State, Phonon::State)'

  def addAction action
    @actionCollection.addAction action.object_name, action
  end

  def toogleVolumeSlider show
  end


  def setFullScreen full
  end

  def stateChanged state, stateBefore
#     if state == Phonon::PlayingState
#       action.checked = true
#     elsif state == Phonon::PausedState
#       action.checked = false
#     else
#       #...
#     end
  end

  def ini_phonon collection, menu, controlBar
    @videoPlayer = Phonon::VideoPlayer.new Phonon::VideoCategory, self
    volumeSlider = Phonon::VolumeSlider.new @videoPlayer.audioOutput, self
    seekSlider = Phonon::SeekSlider.new @videoPlayer.mediaObject, self

    # action play pause
    action = collection.add_action 'switch-pause', KDE::Action.new( self )
    action.checkable = true
    action.shortcut = KDE::Shortcut.new Qt::Key_Backspace, Qt::Key_MediaStop
    action.connect( SIGNAL('toggled(bool)') ) do |playing|
      if playing
        @playPauseAction.text = i18n '&Play'
        @playPauseAction.icon = KDE::Icon.new 'media-playback-pause'
        @videoPlayer.play
      else
        @playPauseAction.text = i18n '&Pause'
        @playPauseAction.icon = KDE::Icon.new 'media-playback-start'
        @videoPlayer.pause
      end
    end
    connect(@videoPlayer.mediaObject, SIGNAL('stateChanged(Phonon::State, Phonon::State)'), self, SLOT('stateChanged(Phonon::State, Phonon::State)'))
    menu.add_action action
    controlBar.add_action action

    # action previous
    action = collection.add_action 'controls-previous', KDE::Action.new( KDE::Icon.new( 'media-skip-backward' ), i18n( 'Previous' ), self )
    action.shortcut = KDE::Shortcut.new Qt::Key_PageUp, Qt::Key_MediaPrevious
    menu.add_action action
    controlBar.add_action action

    # action stop
    action = collection.add_action 'controls-stop', KDE::Action.new( KDE::Icon.new( 'media-playback-stop' ), i18n( 'Stop' ), self )
    action.shortcut = KDE::Shortcut.new Qt::Key_Backspace, Qt::Key_MediaStop
    menu.add_action action
    controlBar.add_action action

    # action forward
    action = collection.add_action 'controls-forward', KDE::Action.new( KDE::Icon.new( 'media-skip-forward' ), i18n( 'Forward' ), self )
    action.shortcut = KDE::Shortcut.new Qt::Key_PageDown, Qt::Key_MediaNext
    menu.add_action action
    controlBar.add_action action

    menu.add_separator

    # action volume mute
    audioMenu = KDE::Menu.new i18nc( 'Playback menu', 'Audio' ), self
    menu.add_menu audioMenu

    action = collection.add_action 'volume-mute', KDE::Action.new( KDE::Icon.new( 'player-volume' ), i18n( 'Mute Volume' ), self)
    action.checkable = true
    action.shortcut = KDE::Shortcut.new Qt::Key_M, Qt::Key_VolumeMute
    action.connect( SIGNAL('toggled(bool)') ) do |muted|
      action.set_icon KDE::Icon.new muted ? 'player-volume-muted' : 'player-volume' # audio-volume-muted' : 'audio-volume-medium'
      @videoPlayer.audioOutput.muted = muted
    end
    connect(volumeSlider.audioOutput, SIGNAL('mutedChanged(bool)'), action, SLOT('setChecked(bool)') )
    audioMenu.add_action action

    menu.add_separator

    # action fullscreen
#     action = collection.add_action 'switch-fullscreen', KDE::StandardAction::fullScreen( @videoPlayer.video_widget, SLOT( 'setFullScreen(bool)' ), self, collection)
    action = collection.add_action 'switch-fullscreen', KDE::StandardAction::fullScreen( self, SLOT( 'setFullScreen(bool)' ), self, collection)
    menu.add_action action
    controlBar.add_action action

    action = collection.add_action 'volume-slider', KDE::Action.new( i18n( 'Volume Slider' ), self )
    action.default_widget = volumeSlider
    controlBar.add_action action

    action = collection.add_action 'seek-slider', KDE::Action.new( i18n( 'Position Slider' ), self )
    action.default_widget = seekSlider
    controlBar.add_action action

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


    #### prepare menus
    collection = KDE::ActionCollection.new self
    controlBar = KDE::ToolBar.new 'control_bar', self, Qt::BottomToolBarArea
    controlBar.tool_button_style = Qt::ToolButtonIconOnly

    menu = KDE::Menu.new i18n('&File'), self
    menuBar.add_menu menu

    action = collection.add_action 'quit', KDE::StandardAction::quit( self, SLOT( :close ), collection )
    menu.add_action action
    controlBar.add_action action

    menu = KDE::Menu.new i18n('&Play'), self
    menuBar.add_menu menu

    ini_phonon collection, menu, controlBar

    menu = KDE::Menu.new i18n('&Settings'), self
    menuBar.add_menu menu

    action = collection.add_action 'configure-keys', KDE::StandardAction::keyBindings( self, SLOT( :configureKeys ), collection )
    menu.add_action action

    menuBar.add_menu helpMenu

    collection.associate_widget self
    collection.read_settings
    set_auto_save_settings

    menuBar.show
    controlBar.show

    setCentralWidget @videoPlayer
    youtube_url = 'http://www.youtube.com/watch?v=lg8LfoyDFUM'
    a = Time.now
    title,video_url = `python youtube-dl -geb #{youtube_url}`.strip.split $/
    puts (Time.now - a)
    setWindowTitle title
    @videoPlayer.play Phonon::MediaSource.new video_url

#     retranslateUi

    self.show
  end

  def retranslateUi
#     @menuFile.title = i18n "File"
#     setWindowTitle i18n "MainWindow"
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