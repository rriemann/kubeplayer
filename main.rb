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

require 'lib/Video'
require 'lib/List'
require 'lib/MainWindow'

if $0 == __FILE__
  about = KDE::AboutData.new(
    "kubeplayer",
    "kubeplayer",
    KDE.ki18n("Kube Player"),
    "0.1",
    KDE::ki18n("A video player dedicated to play online videos."),
    KDE::AboutData::License_GPL_V3,
    KDE::ki18n("(c) 2010, Robert Riemann"),
    KDE::ki18n("Kube Player is a dedicated to play online videos without the need of flash.\nIf you find a bug, please report it to <a href=\"http://github.com/saLOUt/kubeplayer/issues\">http://github.com/saLOUt/kubeplayer/issues</a>."),
    "http://github.com/saLOUt/kubeplayer", "saloution@googlemail.com" )
  about.setProgramIconName  "plasma" # use the plasma-icon instead of question mark

  KDE::CmdLineArgs.init(ARGV, about)

#   unless KDE::UniqueApplication.start
#     STDERR.puts "is already running."
#   else
#     a = KDE::UniqueApplication.new
#     w = Kube::MainWindow.new
#     a.exec
#   end
  a = KDE::Application.new
  w = KubePlayer::MainWindow.new
  a.exec
end
