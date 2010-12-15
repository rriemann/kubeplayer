require 'korundum4'

module KubePlayer

class Video < Qt::Object
  # contains the list with all known providers
  @@provider = []
  def self.register_provider aProvider
    @@provider.push aProvider
  end

  def self.dlg_setup dialog
    @@provider.each do |aProvider|
      aProvider.dlg_setup dialog
    end
  end

  # contains the list with all videos
  @@videoCollection = Hash.new do |collection,kurl|
    if kurl.valid?
      video =  self.get_type kurl
      collection[kurl] = video unless video.nil?
    end
  end

  #:call-seq:
  #  accept?(KDE::Url) => bool
  #
  # this function has to be reimplemented by its subclasses
  def self.accept? kurl
    false
  end

  #:call-seq:
  # new(KDE::Url) => Opject of a subclass of Video
  #
  # you get a subclass back or nil
  def self.get_type kurl
    @@provider.each do |aProvider|
      video = aProvider.get_type kurl
      return video unless video.nil?
    end
    return nil
  end

  def self.get kurl
    @@videoCollection[kurl]
  end

=begin
  def == aVideo
    self.url == aVideo.url
  end
=end


  # get the title of the video
  attr_accessor :title


  signals :got_thumbnail, 'got_video_url(QVariant)'

  #:call-seq:
  # thumbnail_url() => KDE::Url
  #
  # get the url to the image of the thumbnail
  attr_reader :thumbnail_url
  def thumbnail_url= kurl
    if kurl.valid?
      @thumbnail_url = kurl
      job = KIO::storedGet kurl , KIO::NoReload, KIO::HideProgressInfo
      connect(job, SIGNAL( 'result( KJob* )' )) do |aJob|
        if aJob.error == 0
          @thumbnail = Qt::Image.from_data aJob.data
          emit got_thumbnail
        else
          qDebug 'Warning: loading thumbnail failed for' + @url + ' : ' + @thumbnail_url
        end
      end
    end
  end

  def thumbnail_job_result aJob
  end

  def video_url= kurl
    @video_url = kurl if kurl.valid?
  end

  #:call-seq:
  # title() => KDE::Url
  #
  # get the internet page of this video
  attr_reader :url

  #:call-seq:
  # title() => string
  #
  # get the author of this video
  attr_accessor :author


  # QDateTime
  attr_accessor :published

  #:call-seq:
  # duration() => Float
  #
  # get the duration in s
  attr_accessor :duration

  #:method: getVideoInfo(QVariant)
  #slots 'get_video_info()'

  attr_reader :thumbnail

  attr_reader :video_url

  def initialize kurl
    super()
    @url = kurl
    @title = nil
    @thumbnail_url = nil
    @thumbnail = nil
    @video_url = nil
    @author = nil
    @published = Qt::DateTime.new # dateTime # FIXME
    @duration = nil
  end

  def to_s
    @title or '[unbenannt]'
  end

   # FIXME (this implementation doesn't work to protect the constructor
  protected :initialize
end

end

require 'provider/youtube/Youtube'
KubePlayer::Video.register_provider Youtube::Video