module KubePlayer

  UserRole = Qt::UserRole.to_i
  ItemTypeRole, VideoRole, ActiveTrackRole = *(UserRole...(UserRole+3))
  ItemTypeVideo,ItemTypeShowMore = 1,2

class VideoList < Qt::AbstractListModel

  slots :update_thumbnail
  signals 'active_row_changed(int)'
  signals 'play_this(QVariant)'

  attr_reader :videos
  attr_accessor :queryVeto

  def initialize providerClass, minimumSize = 0
    super()
    @videos = []
    @provider = providerClass
    @minimumSize = minimumSize
    @activeVideo = nil
    @activeRow = nil
    @autostart = false
    @query = nil
    @queryVeto = 0 # allow new query when @queryVeto == 0
  end

  # inherited from Qt::AbstractListModel
  def data modelIndex, role
    row = modelIndex.row
    if include? row
      video = @videos[row]
      case role
      when VideoRole then
        return Qt::Variant.from_value video
      when ActiveTrackRole then
        return Qt::Variant.new(video == @activeVideo)
      when Qt::DisplayRole, Qt::StatusTipRole then
          return Qt::Variant.new video.to_s
      end
    end
    Qt::Variant.new
  end

  # inherited from Qt::AbstractListModel
  def row_count modelIndex
    @videos.size
  end
  alias :rowCount :row_count

  # inherited from Qt::AbstractListModel
  def remove_rows position, rows, modelIndex
    begin_remove_rows Qt::ModelIndex.new, position, position+rows-1
    for row in (0...rows)
      @videos.delete_at row
    end
    end_remove_rows
    return true
  end
  alias :removeRows :remove_rows

  def clear
    begin_remove_rows Qt::ModelIndex.new, 0, @videos.size - 1
    @videos.clear
    end_remove_rows
  end

  def include? row
    (0...@videos.size).include? row
  end

  def [] index
    @videos[index]
  end

  def active= row

    if include? row
      @activeRow = row
      @activeVideo = @videos[row]

      emit dataChanged(create_index(row, 0), create_index(row, column_count()-1))
      emit active_row_changed(row)
    else
      @activeRow = nil
      @activeVideo = nil
    end
  end

  def next_row
    nextRow = @activeRow + 1
    if include? nextRow
      nextRow
    end
  end

  def active_video
    @activeVideo
  end

  def push video
    connect video, SIGNAL(:got_thumbnail), self, SLOT(:update_thumbnail)
    connect(video, SIGNAL('got_video_url(QVariant)')) do |variant|
      emit play_this(variant)
    end

    begin_insert_rows Qt::ModelIndex.new, @videos.size, @videos.size
    @videos.push video
    end_insert_rows

    if @videos.size == 1 and @autostart
      self.active = 0
    end
  end

  def update_thumbnail
    video = sender()
    if video.class <= Video
      row = row_for_video video
      emit dataChanged(create_index(row, 0), create_index(row, column_count()-1))
    else
      qDebug 'Cannot get sender'
    end
  end


  #:call-seq: => int
  def row_for_video video
    @videos.index video
  end

  #:call-seq: => Qt::ModelIndex
  def index_for_video video
    create_index @videos.index(video), 0
  end

  def query query = nil
    if not (query.nil? or query.empty?) and query != @query
      self.clear
      @queryVeto = 0
      @query = query
    end
    if not @query.nil? and @queryVeto == 0
      @provider.query self, @query, self.videos.size, @minimumSize
    end
  end

  def minimum_size= size
    @minimumSize = size
    if @minimumSize > @videos.size
      self.query
    end
  end

end

class ListView < Qt::ListView

  attr_accessor :videoList

  def initialize parent, providerClass, videoPlayer, searchWidget
    super(parent)
    # self.view_mode = Qt::ListView::ListMode
    self.item_delegate = VideoItemDelegate.new(self)
    # self.selection_mode = Qt::AbstractItemView::ExtendedSelection
    self.vertical_scroll_mode = Qt::AbstractItemView::ScrollPerPixel
    self.frame_shape = Qt::Frame::NoFrame
    # self.attribute = Qt::WA_MacShowFocusRect, false FIXME
    self.minimum_size = Qt::Size.new 320, 240
    self.uniform_item_sizes = true

    @provider = providerClass
    @videoPlayer = videoPlayer
    @searchWidget = searchWidget

    @videoList =  VideoList.new @provider
    self.model = @videoList

    connect(self, SIGNAL('activated(QModelIndex)')) do |modelIndex|
      @videoList.active = modelIndex.row
    end

    self.vertical_scroll_bar.tracking = true
    connect(self.vertical_scroll_bar, SIGNAL('valueChanged(int)')) do |pos|
      if self.vertical_scroll_bar.maximum == pos
        @videoList.query
      end
    end

    connect(@videoList, SIGNAL('active_row_changed(int)')) do |row|
      video = @videoList[row]
      @active_video = video
      video.request_video_url
    end

    connect(@videoList, SIGNAL('play_this(QVariant)')) do |variant|
      video = variant.value
      if @active_video == video
        @videoPlayer.play Phonon::MediaSource.new video.video_url
      end
    end

    @searchWidget.connect( SIGNAL :returnPressed ) do
      @videoList.query @searchWidget.line_edit.text
      @searchWidget.line_edit.clear
    end
  end

  def resize_event event
    @videoList.minimum_size = event.size.height/VideoItemDelegate::THUMBNAIL_SIZE[1] + 1
  end
  alias :resizeEvent :resize_event

end

class VideoItemDelegate < Qt::StyledItemDelegate
  THUMBNAIL_SIZE = [120, 90]
  PADDING = 10

  def initialize parent

    super

    @boldFont = Qt::Font.new
    @boldFont.bold = true

    @smallerFont = Qt::Font.new
    @smallerFont.point_size = @smallerFont.point_size*0.85

    @smallerBoldFont = Qt::Font.new
    @smallerBoldFont.bold = true
    @smallerBoldFont.point_size = @smallerBoldFont.point_size*0.85

    fontInfo = Qt::FontInfo.new @smallerFont
    if fontInfo.pixel_size < 10
      @smallerFont.pixel_size = 10
      @smallerBoldFont.pixel_size = 10
    end

    @playIcon = Qt::Pixmap.new *THUMBNAIL_SIZE
    @playIcon.fill Qt::Color.new(Qt::transparent)
    painter = Qt::Painter.new @playIcon
    polygon = Qt::Polygon.new [Qt::Point.new(PADDING*4, PADDING*4), Qt::Point.new(THUMBNAIL_SIZE[0]-PADDING*4, THUMBNAIL_SIZE[1]/2), Qt::Point.new(PADDING*4, THUMBNAIL_SIZE[1]-PADDING*2)]
    # painter.render_hint = Qt::Painter::Antialiasing FIXME
    painter.brush = Qt::white
    pen = Qt::Pen.new
    pen.color = Qt::Color.new Qt::white
    pen.width = PADDING
    pen.join_style = Qt::RoundJoin
    pen.cap_style = Qt::RoundCap
    painter.pen = pen
    painter.draw_polygon polygon
  end

  def size_hint styleOptionViewItem, modelIndex
    Qt::Size.new 256, THUMBNAIL_SIZE[1]+1
  end
  alias :sizeHint :size_hint

  def paint painter, styleOptionViewItem, modelIndex
    KDE::Application.style.drawPrimitive Qt::Style::PE_PanelItemViewItem, styleOptionViewItem, painter
    video = modelIndex.data(VideoRole).value
    paint_body painter, styleOptionViewItem, modelIndex
  end

  def paint_body painter, styleOptionViewItem, modelIndex
    painter.save
    painter.translate styleOptionViewItem.rect.top_left

    line = Qt::RectF.new 0, 0, styleOptionViewItem.rect.width, styleOptionViewItem.rect.height
    painter.clip_rect = line


    isActive = modelIndex.data(ActiveTrackRole).to_bool
    # isSelected = !((Qt::Style::State_Selected.to_i & styleOptionViewItem.state) > 0)

    # puts Qt::Style::State_Selected.inspect + ' ' + styleOptionViewItem.state.inspect
    # puts isActive.inspect + ' ' + isSelected.inspect
    if isActive
      paint_active_overlay painter, line.x, line.y, line.width, line.height
    end
    video = modelIndex.data(VideoRole).value
    #puts isSelected.inspect + " " + video.title

    unless video.thumbnail.nil?
      painter.draw_image(Qt::Rect.new(0, 0, *THUMBNAIL_SIZE), video.thumbnail)
      # paint_play_icon painter if isActive FIXME

      if video.duration > 3600 # more than 1 h
        format = 'h:mm:ss'
      else
        format = 'm:ss'
      end
      draw_time painter, Qt::Time.new.add_secs(video.duration).to_string(format), line
    end

    painter.font = @boldFont if isActive
    fm = Qt::FontMetricsF.new painter.font
    boldMetrics = Qt::FontMetricsF.new @boldFont

    painter.pen = Qt::Pen.new(styleOptionViewItem.palette.brush(false ? Qt::Palette::HighlightedText : Qt::Palette::Text),0)

    title = video.title
    textBox = Qt::RectF.new line.adjusted PADDING+THUMBNAIL_SIZE[0], PADDING, -2*PADDING, -PADDING
    alignHints = (Qt::AlignLeft | Qt::AlignTop | Qt::TextWordWrap)
    textBox = painter.boundingRect textBox, alignHints, title
    painter.draw_text textBox, alignHints, title

=begin
    painter.font = @smallerFont
    published = video.published.date.to_string Qt::DefaultLocaleShortDate
    publishedSize = Qt::SizeF.new(Qt::FontMetrics.new(painter.font).size(Qt::TextSingleLine, published))
    textLocation = Qt::PointF.new PADDING+THUMBNAIL_SIZE[0], PADDING*2+textBox.height
    publishedTextBox = Qt::RectF.new textLocation, publishedSize
    painter.draw_text publishedTextBox, alignHints, published

    painter.save
    painter.font = @smallerBoldFont

    painter.pen(Qt::Pen.new(styleOptionViewItem.palette.brush(Qt::Palette::Mid), 0)) if not isSelected and not isActive
    author = video.author
    authorSize = Qt::SizeF.new(Qt::FontMetrics.new(painter.font).size(Qt::TextSingleLine, author))
    textLocation.x = textLocation.x + publishedSize.width + PADDING
    authorTextBox = Qt::RectF.new textLocation, authorSize
    painter.draw_text authorTextBox, alignHints, author
    painter.restore

=end
    painter.pen = styleOptionViewItem.palette.color(Qt::Palette::Midlight)
    painter.draw_line THUMBNAIL_SIZE[0], THUMBNAIL_SIZE[1], line.width, THUMBNAIL_SIZE[1]
    painter.pen = Qt::Color.new(Qt::black) unless video.thumbnail.nil?
    painter.draw_line 0, THUMBNAIL_SIZE[1], THUMBNAIL_SIZE[0]-1, THUMBNAIL_SIZE[1]

    painter.restore
  end

  def paint_active_overlay painter, x, y, w, h
    palette = Qt::Palette.new
    highlightColor = palette.color Qt::Palette::Highlight
    backgroundColor = palette.color Qt::Palette::Base

    animation = 0.25
    gradientRange = 16

    color2 = Qt::Color.fromHsv(highlightColor.hue,
                               (backgroundColor.saturation*(1-animation)+highlightColor.saturation*animation).to_i,
                               (backgroundColor.value*(1-animation)+highlightColor.value*animation).to_i)
    color1 = Qt::Color.fromHsv(color2.hue,[color2.saturation-gradientRange,0].max,[color2.value+gradientRange,255].min)
    rect = Qt::Rect.new x.to_i, y.to_i, w.to_i, h.to_i
    painter.save
    painter.pen = Qt::Pen.new(Qt::NoPen)
    linearGradient = Qt::LinearGradient.new 0, 0, 0, rect.height
    linearGradient.setColorAt(0, color1) # FIXME why not color_at= ?
    linearGradient.setColorAt(1, color2)
    painter.brush = Qt::Brush.new(linearGradient)
    painter.draw_rect rect
    painter.restore
  end


  def draw_time painter, time, line
    timePadding = 4
    textBox = painter.bounding_rect line, Qt::AlignLeft | Qt::AlignTop, time
    textBox.adjust 0, 0, timePadding, 0
    textBox.translate THUMBNAIL_SIZE[0]-textBox.width, THUMBNAIL_SIZE[1]-textBox.height

    painter.save
    painter.pen = Qt::Pen.new(Qt::NoPen)
    painter.brush = Qt::Brush.new(Qt::black)
    painter.opacity = 0.5
    painter.draw_rect textBox
    painter.restore

    painter.save
    painter.pen = Qt::Color.new(Qt::white)
    painter.draw_text textBox, Qt::AlignCenter, time
    painter.restore
  end

  def paint_play_icon painter
    painter.save
    painter.opacity = 0.5
    painter.draw_pixmap @playIcon.rect, @playIcon
    painter.restore
  end
end

end