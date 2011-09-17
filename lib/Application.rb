module KubePlayer

class UniqueApplication < KDE::UniqueApplication

  signals 'got_video_request(KUrl)'

  def newInstance
    args = KDE::CmdLineArgs::parsedArgs
    if args.count > 0
      kurl = args.url(0)
      emit got_video_request(kurl)
    end
    return 0
  end

end

end