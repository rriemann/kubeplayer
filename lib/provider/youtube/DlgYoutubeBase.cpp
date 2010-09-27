/********************************************************************************
** Form generated from reading UI file 'DlgYoutubeBase.ui'
**
** Created
**      by: Qt User Interface Compiler version 4.6.3
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef DLGYOUTUBEBASE_H
#define DLGYOUTUBEBASE_H

#include <QtCore/QVariant>
#include <QtGui/QAction>
#include <QtGui/QApplication>
#include <QtGui/QButtonGroup>
#include <QtGui/QGroupBox>
#include <QtGui/QHBoxLayout>
#include <QtGui/QHeaderView>
#include <QtGui/QLabel>
#include <QtGui/QSpacerItem>
#include <QtGui/QVBoxLayout>
#include <QtGui/QWidget>
#include "kcombobox.h"

QT_BEGIN_NAMESPACE

class Ui_DlgYoutubeBase
{
public:
    QVBoxLayout *verticalLayout;
    QGroupBox *groupBox;
    QVBoxLayout *verticalLayout_2;
    QHBoxLayout *horizontalLayout;
    QLabel *label;
    KComboBox *kcfg_Quality;
    QSpacerItem *spacer;

    void setupUi(QWidget *DlgYoutubeBase)
    {
        if (DlgYoutubeBase->objectName().isEmpty())
            DlgYoutubeBase->setObjectName(QString::fromUtf8("DlgYoutubeBase"));
        DlgYoutubeBase->resize(429, 209);
        verticalLayout = new QVBoxLayout(DlgYoutubeBase);
        verticalLayout->setObjectName(QString::fromUtf8("verticalLayout"));
        groupBox = new QGroupBox(DlgYoutubeBase);
        groupBox->setObjectName(QString::fromUtf8("groupBox"));
        groupBox->setMinimumSize(QSize(0, 0));
        verticalLayout_2 = new QVBoxLayout(groupBox);
        verticalLayout_2->setObjectName(QString::fromUtf8("verticalLayout_2"));
        horizontalLayout = new QHBoxLayout();
        horizontalLayout->setObjectName(QString::fromUtf8("horizontalLayout"));
        label = new QLabel(groupBox);
        label->setObjectName(QString::fromUtf8("label"));
        label->setAlignment(Qt::AlignRight|Qt::AlignTrailing|Qt::AlignVCenter);

        horizontalLayout->addWidget(label);

        kcfg_Quality = new KComboBox(groupBox);
        kcfg_Quality->insertItems(0, QStringList()
         << QString::fromUtf8("400x240")
         << QString::fromUtf8("640x360")
         << QString::fromUtf8("854x480")
         << QString::fromUtf8("480x360")
         << QString::fromUtf8("1280x720")
         << QString::fromUtf8("1920x1080")
         << QString::fromUtf8("4096x3072")
        );
        kcfg_Quality->setObjectName(QString::fromUtf8("kcfg_Quality"));

        horizontalLayout->addWidget(kcfg_Quality);


        verticalLayout_2->addLayout(horizontalLayout);


        verticalLayout->addWidget(groupBox);

        spacer = new QSpacerItem(20, 133, QSizePolicy::Minimum, QSizePolicy::Expanding);

        verticalLayout->addItem(spacer);

#ifndef QT_NO_SHORTCUT
        label->setBuddy(kcfg_Quality);
#endif // QT_NO_SHORTCUT

        retranslateUi(DlgYoutubeBase);

        QMetaObject::connectSlotsByName(DlgYoutubeBase);
    } // setupUi

    void retranslateUi(QWidget *DlgYoutubeBase)
    {
        DlgYoutubeBase->setWindowTitle(i18n("Form", 0));
        groupBox->setTitle(i18n("Quality", 0));
        label->setText(i18n("Maximum Video Quality:", 0));
    } // retranslateUi

};

namespace Ui {
    class DlgYoutubeBase: public Ui_DlgYoutubeBase {};
} // namespace Ui

QT_END_NAMESPACE

#endif // DLGYOUTUBEBASE_H
