module KubePlayer

class HistoryComboBox < KDE::ComboBox # < KDE::HistoryComboBox
  def initialize parent
    super(true, parent)
    self.set_size_policy(Qt::SizePolicy::Fixed, Qt::SizePolicy::Fixed)
    self.set_minimum_size(200,0)
    self.duplicates_enabled = false
#     self.completion_mode = KDE::GlobalSettings::CompletionPopupAuto # TODO let configure
    self.completion_mode = KDE::GlobalSettings::CompletionPopup
  end
end

class MainWindow < KDE::MainWindow

  slots 'toogleVolumeSlider(bool)', 'stateChanged(Phonon::State, Phonon::State)', 'handle_video_request(KUrl)'

  def stateChanged state, stateBefore
    case state
    when Phonon::PlayingState then
      @seekSlider.mediaObject = @videoPlayer.mediaObject
      @playPauseAction.checked = true
      @playPauseAction.enabled = true
    when Phonon::PausedState then
      @playPauseAction.checked = false
      @playPauseAction.enabled = true
    when Phonon::ErrorState then
      qDebug 'Phonon Error: ' + @videoPlayer.media_object.error_string + ' (' + @videoPlayer.media_object.error_type.to_s + ')'
    else
      @playPauseAction.enabled = false # unless state == Phonon::BufferingState
    end
  end

  def ini_phonon collection, menu, controlBar
    @videoPlayer = Phonon::VideoPlayer.new Phonon::VideoCategory, self
    @videoPlayer.media_object.tick_interval = 100
    @volumeSlider = Phonon::VolumeSlider.new @videoPlayer.audioOutput, self
    @volumeSlider.set_size_policy(Qt::SizePolicy::Fixed, Qt::SizePolicy::Fixed)
    @seekSlider = Phonon::SeekSlider.new @videoPlayer.mediaObject, self
    @seekSlider.set_size_policy(Qt::SizePolicy::Expanding, Qt::SizePolicy::Expanding)

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
    connect(@volumeSlider.audioOutput, SIGNAL('mutedChanged(bool)'), action, SLOT('setChecked(bool)') )
    audioMenu.add_action action

    menu.add_separator

    action = collection.add_action 'volume-slider', KDE::Action.new( i18n( 'Volume Slider' ), self )
    action.default_widget = @volumeSlider
    controlBar.add_action action

    action = collection.add_action 'seek-slider', KDE::Action.new( i18n( 'Position Slider' ), self )
    action.default_widget = @seekSlider
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
    @listDock = Qt::DockWidget.new self
    action = collection.add_action 'toogle-listwidgetcontainer-dock', @listDock.toggle_view_action
    menu.add_action action
    @listDock.objectName = "listWidgetContainerDock"
    @listDock.windowTitle = "Clips"
    @listDock.allowedAreas = Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea
    self.add_dock_widget Qt::LeftDockWidgetArea, @listDock

    # add search field
    @suggestTimer = Qt::Timer.new self
    @suggestTimer.single_shot = true
    connect(@suggestTimer,SIGNAL(:timeout)) do
      unless @searchWidget.line_edit.text.empty?
        Youtube::Video.suggest(@searchWidget, @searchWidget.line_edit.text)
      end
    end
    @searchWidget = HistoryComboBox.new self
    connect(@searchWidget.line_edit,SIGNAL('userTextChanged(QString)')) do
      @suggestTimer.stop if @suggestTimer.active?
      @suggestTimer.start 400 # in ms
    end
    @searchWidget.set_size_policy(Qt::SizePolicy::Fixed, Qt::SizePolicy::Fixed)
    controlBar.add_widget @searchWidget

    @listWidget = ListView.new @listDock, Youtube::Video, @videoPlayer, @searchWidget, @listDock
    @listDock.widget = @listWidget

    self.show
  end

  def handle_video_request kurl
      video = Video::get_type kurl
      if video
        connect(video, SIGNAL('got_video_url(QVariant)')) do |variant|
          video = variant.value
          @videoPlayer.play Phonon::MediaSource.new video.video_url
        end
        video.request_video_url
        @listDock.hide
      else
        msg = KDE::i18n "The given URL <a href='%1'>%1</a> is not supported, because there is appropriate website plugin.<br />You may want to file a feature request.", kurl.url
        STDERR.puts msg
        KDE::MessageBox.messageBox nil, KDE::MessageBox::Sorry, msg, i18n("No supported URL")
      end
  end

end

end