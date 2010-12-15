module Youtube

class Video < KubePlayer::Video

  VALID_URL = Qt::RegExp.new 'http://www\.youtube\.com/watch\?v=[^&]+.*'
  #:call-seq:
  #  accept?(KDE::Url) => bool
  def self.accept? kurl
    VALID_URL.exact_match kurl.url
  end

  def self.get_type kurl
    self.new kurl if self.accept? kurl
  end

  QUERY_URL = 'http://gdata.youtube.com/feeds/api/videos?q=%s&max-results=%d&start-index=%d&alt=json'
  def self.query videoList, query, start, minimum_size
    max_results = [6, minimum_size].max
    videoList.queryVeto = max_results
    queryUrl = KDE::Url.new(QUERY_URL % [(KDE::Url.to_percent_encoding query), max_results, start+1])
    queryJob = KIO::storedGet queryUrl , KIO::NoReload, KIO::HideProgressInfo
    connect(queryJob, SIGNAL( 'result( KJob* )' ), videoList) do |aJob|
      begin
        JSON.parse( aJob.data.data )["feed"]["entry"].each do |entry|
          if (video = self.get( KDE::Url.new(entry["link"][0]["href"]) ))
            video.title = entry["title"]["$t"]
            video.thumbnail_url = KDE::Url.new(entry["media$group"]["media$thumbnail"][-1]["url"])
            video.duration = entry["media$group"]["yt$duration"]["seconds"].to_f
            video.author = entry["author"][0]["name"]["$t"]
            videoList.push video
            videoList.queryVeto -= 1
          end
        end
      rescue NoMethodError
        qDebug 'No Videos found'
      end
    end
  end

  SUGGEST_URL = 'http://suggestqueries.google.com/complete/search?hl=en&ds=yt&nolabels=t&json=t&q=%s'
  def self.suggest searchWidget, query
    suggestUrl = KDE::Url.new(SUGGEST_URL % (KDE::Url.to_percent_encoding query))
    suggestRequestJob = KIO::storedGet suggestUrl , KIO::NoReload, KIO::HideProgressInfo
    connect(suggestRequestJob, SIGNAL( 'result( KJob* )' ), searchWidget) do |aJob|
      searchWidget.completed_items = JSON.parse(aJob.data.data)[1]
    end
  end

  def initialize kurl
    super(kurl)
  end

  REQUEST_URL  = 'http://www.youtube.com/get_video_info?&video_id=%s&el=embedded&ps=default&eurl=&gl=US&hl=en'
  def request_video_url
    if @video_url == nil
      @video_url = false
      @id = @url.url.match(/\bv=([^&]+)/)[1]
      infoRequestUrl = KDE::Url.new(REQUEST_URL % @id)
      # infoRequestUrl.add_query_item 'video_id', @id
      infoRequestJob = KIO::storedGet infoRequestUrl , KIO::NoReload, KIO::HideProgressInfo
      infoRequestJob.add_meta_data 'cookies', 'none'
      connect(infoRequestJob, SIGNAL( 'result( KJob* )' )) do |aJob|
        metaInfo = {}
        aJob.data.data.split('&').each do |s|
          match = /=/.match s
          metaInfo[match.pre_match.to_sym] = KDE::Url::fromPercentEncoding(Qt::ByteArray.new match.post_match)
        end
        @fmtUrlMap = {}
        metaInfo[:fmt_url_map].scan(/(\d+)\|([^,]+)/).each {|quality,url| @fmtUrlMap[quality.to_i] = url}
        @video_url = KDE::Url.new @fmtUrlMap.max[1]
        emit got_video_url(Qt::Variant.from_value(self))
      end
    elsif @video_url != false
      emit got_video_url(Qt::Variant.from_value(self))
    end
  end

  def self.dlg_setup dialog
    youtubepage = DlgYoutube.new dialog
    dialog.add_page youtubepage, YoutubeSettings.instance, 'Youtube', '', i18n('Youtube Settings')
  end
end

class DlgYoutube < Qt::Widget
  def initialize parent
    super

    ui = Ui::DlgYoutubeBase.new
    ui.setup_ui self
  end
end

end