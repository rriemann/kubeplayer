=begin
** Form generated from reading ui file 'DlgYoutubeBase.ui'
**
** Created: Do. Aug 19 12:09:32 2010
**      by: Qt User Interface Compiler version 4.6.3
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
=end

class Ui_DlgYoutubeBase
    attr_reader :verticalLayout
    attr_reader :groupBox
    attr_reader :verticalLayout_2
    attr_reader :horizontalLayout
    attr_reader :label
    attr_reader :kcfg_Quality
    attr_reader :spacer

    def setupUi(dlgYoutubeBase)
    if dlgYoutubeBase.objectName.nil?
        dlgYoutubeBase.objectName = "dlgYoutubeBase"
    end
    dlgYoutubeBase.resize(429, 209)
    @verticalLayout = Qt::VBoxLayout.new(dlgYoutubeBase)
    @verticalLayout.objectName = "verticalLayout"
    @groupBox = Qt::GroupBox.new(dlgYoutubeBase)
    @groupBox.objectName = "groupBox"
    @groupBox.minimumSize = Qt::Size.new(0, 0)
    @verticalLayout_2 = Qt::VBoxLayout.new(@groupBox)
    @verticalLayout_2.objectName = "verticalLayout_2"
    @horizontalLayout = Qt::HBoxLayout.new()
    @horizontalLayout.objectName = "horizontalLayout"
    @label = Qt::Label.new(@groupBox)
    @label.objectName = "label"
    @label.alignment = Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter

    @horizontalLayout.addWidget(@label)

    @kcfg_Quality = KDE::ComboBox.new(@groupBox)
    @kcfg_Quality.objectName = "kcfg_Quality"

    @horizontalLayout.addWidget(@kcfg_Quality)


    @verticalLayout_2.addLayout(@horizontalLayout)


    @verticalLayout.addWidget(@groupBox)

    @spacer = Qt::SpacerItem.new(20, 133, Qt::SizePolicy::Minimum, Qt::SizePolicy::Expanding)

    @verticalLayout.addItem(@spacer)

    @label.buddy = @kcfg_Quality

    retranslateUi(dlgYoutubeBase)

    Qt::MetaObject.connectSlotsByName(dlgYoutubeBase)
    end # setupUi

    def setup_ui(dlgYoutubeBase)
        setupUi(dlgYoutubeBase)
    end

    def retranslateUi(dlgYoutubeBase)
    dlgYoutubeBase.windowTitle = KDE::i18n("Form", nil)
    @groupBox.title = KDE::i18n("Quality", nil)
    @label.text = KDE::i18n("Maximum Video Quality:", nil)
    @kcfg_Quality.insertItems(0, [KDE::i18n("400x240", nil),
        KDE::i18n("640x360", nil),
        KDE::i18n("854x480", nil),
        KDE::i18n("480x360", nil),
        KDE::i18n("1280x720", nil),
        KDE::i18n("1920x1080", nil),
        KDE::i18n("4096x3072", nil)])
    end # retranslateUi

    def retranslate_ui(dlgYoutubeBase)
        retranslateUi(dlgYoutubeBase)
    end

end

module Ui
    class DlgYoutubeBase < Ui_DlgYoutubeBase
    end
end  # module Ui

