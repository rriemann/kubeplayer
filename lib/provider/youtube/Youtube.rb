class Hash
  def custom_revert
    r = Hash.new
    each {|k,v| v.each {|v| r[v] = k} }
    r
  end
end

module Youtube

class Video < KubePlayer::Video

  VALID_URL = Qt::RegExp.new 'http://www\.youtube\.com/watch\?v=[^&]+.*'

  # http://en.wikipedia.org/wiki/YouTube#Quality_and_codecs
  FORMAT2NUMBER = {:flv => [5, 6, 34, 35], :mp4 => [18, 22, 37, 38, 83, 82, 85, 84], :webm => [43, 44, 45, 100, 101, 46, 102] , :'3gp' => [13, 17]}
  NUMBER2FORMAT = FORMAT2NUMBER.custom_revert

  RESOLUTION2NUMBER = {224 => [5, 6], 240 => [83], 360 => [34, 18, 82, 43, 100], 480 => [35, 44, 101], 520 => [85], 540 => [46], 720 => [22, 84, 45, 102], 1080 => [37], 2304 => [38]}
  NUMBER2RESOLUTION = RESOLUTION2NUMBER.custom_revert

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
        qDebug KDE::i18n('No Videos found')
      end
    end
  end

  SUGGEST_URL = 'http://suggestqueries.google.com/complete/search?hl=en&ds=yt&nolabels=t&json=t&output=firefox&q=%s'
  def self.suggest searchWidget, query
    suggestUrl = KDE::Url.new(SUGGEST_URL % (KDE::Url.to_percent_encoding query))
    suggestRequestJob = KIO::storedGet suggestUrl , KIO::NoReload, KIO::HideProgressInfo
    connect(suggestRequestJob, SIGNAL( 'result( KJob* )' ), searchWidget) do |aJob|
      searchWidget.completed_items = JSON.parse(aJob.data.data)[1]
    end
  end

  def initialize kurl
    super(kurl)

    @el_mode_index = 0
  end

  REQUEST_URL  = 'http://www.youtube.com/get_video_info?&video_id=%s&el=%s&ps=default&eurl=&gl=US&hl=en'
  EL_MODE = %w{embedded vevo detailpage}
  def request_video_url
    if @video_url == nil
      @video_url = false
      @id = @url.url.match(/\bv=([^&]+)/)[1]
      infoRequestUrl = KDE::Url.new(REQUEST_URL % [@id, EL_MODE[@el_mode_index]])
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
        if metaInfo[:fmt_url_map]
          metaInfo[:fmt_url_map].scan(/(\d+)\|([^,]+)/).each {|quality,url| @fmtUrlMap[quality.to_i] = url}
        elsif metaInfo[:url_encoded_fmt_stream_map]
          (','+KDE::Url::fromPercentEncoding(Qt::ByteArray.new(metaInfo[:url_encoded_fmt_stream_map]))).split(',url=')[2..-1].each do |w|
            @fmtUrlMap[w.match(/\d+$/).to_s.to_i] = w.sub(/&type.*$/,'')
          end
        end
        @fmtUrlMap.delete_if {|fmt,url| NUMBER2FORMAT[fmt] == :webm} # FIXME to bypass problems with webm (phonon?)
        if metaInfo[:status] == "ok" and not @fmtUrlMap.empty?
          # TODO Let the user prefere different formats (not using @fmtUrlMap.max automatically)
          # STDERR.puts "available formats: #{@fmtUrlMap.keys.map {|k| NUMBER2FORMAT[k]}.join(' ')}"
          fmtUrlMap_by_Resolution = {}
          @fmtUrlMap.each {|k,v| fmtUrlMap_by_Resolution[NUMBER2RESOLUTION[k]] = [k, v] }
          # STDERR.puts fmtUrlMap_by_Resolution.inspect
          @resolution, video = fmtUrlMap_by_Resolution.max
          @fileextension = NUMBER2FORMAT[video[0]]
          @filename = "#{metaInfo[:title].gsub('+','_')}.#{@fileextension}"
          # STDERR.puts "#{resolution}p, #{@filename}"
          @video_url = KDE::Url.new video[1]
          emit got_video_url(Qt::Variant.from_value(self))
        else
          if @el_mode_index < EL_MODE.size - 1
            @el_mode_index += 1
            @video_url = nil
            request_video_url # try same request with another el parameter see video.cpp from minitube
          else
            if metaInfo[:reason]
              msg = KDE::i18n "<strong>Youtube reports:</strong><br/><br/> %1", metaInfo[:reason].gsub('+',' ')
            else
              msg = KDE::i18n "It was not possible to grap an accessible video."
            end
            STDERR.puts msg
            KDE::MessageBox.messageBox(nil, KDE::MessageBox::Sorry, msg, "Youtube Video Plugin")
          end
        end
      end
    elsif @video_url != false
      emit got_video_url(Qt::Variant.from_value(self))
    end
  end
end

end