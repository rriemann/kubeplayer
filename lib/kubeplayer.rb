#!/usr/bin/env ruby1.9
# kate: remove-trailing-space on; replace-trailing-space-save on; indent-width 2; indent-mode ruby; syntax ruby; space-indent on;

require 'korundum4'
require 'phonon'
require 'kio'
require 'rubygems'
require 'json'
require 'pp'

$basedir = File.dirname(__FILE__)
$:.unshift($basedir)

require 'Application'
require 'Video'
require 'List'
require 'MainWindow'

def start_kubeplayer
  about = KDE::AboutData.new(
    "kubeplayer",
    "kubeplayer",
    KDE.ki18n("Kube Player"),
    "1.0",
    KDE::ki18n("A video player dedicated to play online videos."),
    KDE::AboutData::License_GPL_V3,
    KDE::ki18n("(c) 2010, Robert Riemann"),
    KDE::ki18n("Kube Player is a dedicated to play online videos without the need of flash.\nIf you find a bug, please report it to <a href=\"http://github.com/saLOUt/kubeplayer/issues\">http://github.com/saLOUt/kubeplayer/issues</a>."),
    "http://github.com/saLOUt/kubeplayer", "saloution@googlemail.com" )
  # about.setProgramIconName  "" # use the plasma-icon instead of question mark

  KDE::CmdLineArgs.init(ARGV, about)

  options = KDE::CmdLineOptions.new
  options.add "+[url]", KDE::ki18n("URL to open")
  KDE::CmdLineArgs::addCmdLineOptions options

  unless KubePlayer::UniqueApplication.start
    STDERR.puts "is already running."
  else
    a = KubePlayer::UniqueApplication.new
    w = KubePlayer::MainWindow.new
    Qt::Object.connect(a, SIGNAL('got_video_request(KUrl)'), w, SLOT('handle_video_request(KUrl)'))
    a.exec
  end
#   a = KDE::Application.new
#   w = KubePlayer::MainWindow.new
#   a.exec
end
