#!/usr/bin/env ruby1.9
# kate: remove-trailing-space on; replace-trailing-space-save on; indent-width 2; indent-mode ruby; syntax ruby;

require 'korundum4'
require 'phonon'
require 'rubygems'
require 'json'
require 'net/http'
require 'cgi'

class Video

  attr_reader :title

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

  def to_s
    @title
  end

  def video_url
    unless @video_url == false
      msg = `python youtube-dl -gb #{@link}`.strip # e= title, b=best quality, g = url
      @video_url = (msg =~ /ERROR/) ? false : msg
    end
    @video_url
  end

end

class Videos < Qt::AbstractListModel

  attr_reader :videos

  def initialize videos
    super()
    @videos = videos
  end

  def data modelIndex, role
    if modelIndex.is_valid and role == Qt::DisplayRole and modelIndex.row < @videos.size
      Qt::Variant.new @videos[modelIndex.row].title
    else
      Qt::Variant.new
    end
  end

  def rowCount modelIndex
    @videos.size
  end

end

class CustomWidget < KDE::MainWindow

  slots 'toogleVolumeSlider(bool)', 'stateChanged(Phonon::State, Phonon::State)'

  def toogleVolumeSlider show
  end

  def stateChanged state, stateBefore
    if state == Phonon::PlayingState
      @seekSlider.mediaObject = @videoPlayer.mediaObject
      @playPauseAction.checked = true
      @playPauseAction.enabled = true
    elsif state == Phonon::PausedState
      @playPauseAction.checked = false
      @playPauseAction.enabled = true
    else
      @playPauseAction.enabled = false # unless state == Phonon::BufferingState
    end
  end

  def ini_phonon collection, menu, controlBar
    @videoPlayer = Phonon::VideoPlayer.new Phonon::VideoCategory, self
    volumeSlider = Phonon::VolumeSlider.new @videoPlayer.audioOutput, self
    seekSlider = Phonon::SeekSlider.new @videoPlayer.mediaObject, self
    @seekSlider = seekSlider

    # action play pause
    @playPauseAction = collection.add_action 'switch-pause', KDE::Action.new( self )
    @playPauseAction.checkable = true
    @playPauseAction.shortcut = KDE::Shortcut.new Qt::Key_Backspace, Qt::Key_MediaStop
    @playPauseAction.icon = KDE::Icon.new 'media-playback-pause'
    @playPauseAction.text = i18n '&Pause'
    @playPauseAction.enabled = false
    @playPauseAction.connect( SIGNAL('toggled(bool)') ) do |playing|
      if playing
        @videoPlayer.play
      else
        @videoPlayer.pause
      end
    end
    connect(@videoPlayer.mediaObject, SIGNAL('stateChanged(Phonon::State, Phonon::State)'), self, SLOT('stateChanged(Phonon::State, Phonon::State)'))
    menu.add_action @playPauseAction
    controlBar.add_action @playPauseAction

    # action previous
    action = collection.add_action 'controls-previous', KDE::Action.new( KDE::Icon.new( 'media-skip-backward' ), i18n( 'Previous' ), self )
    action.shortcut = KDE::Shortcut.new Qt::Key_PageUp, Qt::Key_MediaPrevious
    menu.add_action action
    controlBar.add_action action

    # action stop
    action = collection.add_action 'controls-stop', KDE::Action.new( KDE::Icon.new( 'media-playback-stop' ), i18n( 'Stop' ), self )
    action.shortcut = KDE::Shortcut.new Qt::Key_Backspace, Qt::Key_MediaStop
    action.connect( SIGNAL( :triggered ) ) do
      @videoPlayer.stop
    end
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

    action = collection.add_action 'volume-slider', KDE::Action.new( i18n( 'Volume Slider' ), self )
    action.default_widget = volumeSlider
    controlBar.add_action action

    action = collection.add_action 'seek-slider', KDE::Action.new( i18n( 'Position Slider' ), self )
    action.default_widget = seekSlider
    controlBar.add_action action

  end

  def initialize

    super

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

    menu = KDE::Menu.new i18n('&View'), self
    menuBar.add_menu menu

    # add clip list dock widget
    dock = Qt::DockWidget.new self
    action = collection.add_action 'toogle-listwidgetcontainer-dock', dock.toggle_view_action
    menu.add_action action
    dock.objectName = "listWidgetContainerDock"
    dock.windowTitle = "Clips"
    dock.allowedAreas = Qt::LeftDockWidgetArea, Qt::RightDockWidgetArea
    self.add_dock_widget Qt::LeftDockWidgetArea, dock
    @listWidget = Qt::ListView.new dock
    @listWidget.view_mode = Qt::ListView::ListMode
    dock.widget = @listWidget
    @listWidget.connect( SIGNAL('doubleClicked(const QModelIndex&)') ) do |modelIndex|
      @videoPlayer.play Phonon::MediaSource.new @listWidget.model.videos[modelIndex.row].video_url
    end

    # add search field
    @searchWidget = KDE::LineEdit.new self
    @searchWidget.clear_button_shown = true
    @searchWidget.connect( SIGNAL :returnPressed ) do
      query @searchWidget.text, 0
      @searchWidget.clear
    end
    controlBar.add_widget @searchWidget

    video_url = 'http://www.youtube.com/get_video?video_id=BU9w9ZtiO8I&t=vjVQa1PpcFPXqhCZqn_V_fcSdspsKvB16IM6uoGvNug=&eurl=&el=embedded&ps=default&fmt=18'
#     video_url = '/home/rriemann/Documents/Videos/Player/Austin_Powers_Goldstaender_08.08.15_20-15_rtl2_115_TVOON_DE.mpg.mp4-cut.avi'
    @videoPlayer.play Phonon::MediaSource.new video_url

    self.show
  end

  def query query, start
    max_results = 10
    uri = URI.parse "http://gdata.youtube.com/feeds/api/videos?q=#{CGI.escape query}&max-results=#{max_results}&start-index=#{start+1}&alt=json"
    response, body = Net::HTTP.start(uri.host, uri.port) do |http|
      http.get(uri.path+'?'+uri.query)
    end
    videos = Videos.new( JSON.parse( body )["feed"]["entry"].collect { |entry| Video.new entry } )
    @listWidget.model = videos
  end

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