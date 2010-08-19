=begin
** Form generated from reading ui file 'DlgYoutubeBase.ui'
**
** Created: Mi. Aug 18 23:56:09 2010
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
    dlgYoutubeBase.windowTitle = Qt::Application.translate("DlgYoutubeBase", "Form", nil, Qt::Application::UnicodeUTF8)
    @groupBox.title = Qt::Application.translate("DlgYoutubeBase", "Quality", nil, Qt::Application::UnicodeUTF8)
    @label.text = Qt::Application.translate("DlgYoutubeBase", "Maximum Video Quality:", nil, Qt::Application::UnicodeUTF8)
    @kcfg_Quality.insertItems(0, [Qt::Application.translate("DlgYoutubeBase", "400x240", "5", Qt::Application::UnicodeUTF8),
        Qt::Application.translate("DlgYoutubeBase", "640x360", "34", Qt::Application::UnicodeUTF8),
        Qt::Application.translate("DlgYoutubeBase", "854x480", "35", Qt::Application::UnicodeUTF8),
        Qt::Application.translate("DlgYoutubeBase", "480x360", "18", Qt::Application::UnicodeUTF8),
        Qt::Application.translate("DlgYoutubeBase", "1280x720", "22", Qt::Application::UnicodeUTF8),
        Qt::Application.translate("DlgYoutubeBase", "1920x1080", "37", Qt::Application::UnicodeUTF8),
        Qt::Application.translate("DlgYoutubeBase", "4096x3072", "38", Qt::Application::UnicodeUTF8)])
    end # retranslateUi

    def retranslate_ui(dlgYoutubeBase)
        retranslateUi(dlgYoutubeBase)
    end

end

module Ui
    class DlgYoutubeBase < Ui_DlgYoutubeBase
    end
end  # module Ui

