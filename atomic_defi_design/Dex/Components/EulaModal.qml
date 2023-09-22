// Qt Imports
import QtQuick 2.15
import QtQuick.Layouts 1.15

// Project Imports
import "../Constants"
import App 1.0 //> API.app_name

MultipageModal
{
    id: root

    onClosed:
    {
        accept_eula.checked = false
        accept_tac.checked = false
    }

    property
    var onConfirm: () =>
    {}
    property bool close_only: false

    MultipageModalContent
    {
        titleText: qsTr("Disclaimer & Terms of Service")

        InnerBackground
        {
            id: eula_rect

            height: 400
            Layout.fillWidth: true

            DefaultFlickable
            {
                anchors.fill: parent
                anchors.margins: 20
                anchors.rightMargin: 0

                contentWidth: eula_text.width - 10
                contentHeight: eula_text.height

                DefaultText
                {
                    id: eula_text
                    font: DexTypo.body1
                    text_value: getEula()

                    width: eula_rect.width - 40
                }
            }
        }

        // Checkboxes
        DefaultCheckBox
        {
            id: accept_eula
            Layout.preferredWidth: parent.width
            visible: !close_only
            labelWidth: eula_rect.width - 80
            text: qsTr("Accept EULA")
        }

        DefaultCheckBox
        {
            id: accept_tac
            Layout.preferredWidth: parent.width
            visible: !close_only
            labelWidth: eula_rect.width - 80
            text: qsTr("Accept Terms and Conditions")
        }

        // Buttons
        footer: [
            RowLayout
            {
                width: root.width - 40
                height: 50
                spacing: 10
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight


                CancelButton
                {
                    text: close_only ? qsTr("Close") : qsTr("Cancel")
                    radius: 18
                    leftPadding: 30
                    rightPadding: 30
                    onClicked: root.close()
                }

                Item
                {
                    height: 1
                    Layout.fillWidth: true

                }

                GradientButton
                {
                    visible: !close_only
                    text: qsTr("Confirm")
                    radius: 18
                    height: 40
                    leftPadding: 30
                    rightPadding: 30
                    enabled: accept_eula.checked && accept_tac.checked
                    onClicked:
                    {
                        onConfirm()
                        root.close()
                    }
                }


            }
        ]
    }

    function getEula()
    {
        return "<h2>This End-User License Agreement ('EULA') is a legal agreement between you and Komodo Platform.</h2>
<p>This EULA agreement governs your acquisition and use of our %1 software ('Software', 'Mobile Application', 'Application' or 'App') directly from Komodo Platform or indirectly through a Komodo Platform authorized entity, reseller or distributor (a 'Distributor').</p>
<p>Please read this EULA agreement carefully before completing the installation process and using the %1 software. It provides a license to use the %1 software and contains warranty information and liability disclaimers.</p>
<p>If you register for the beta program of the %1 software, this EULA agreement will also govern that trial. By clicking 'accept' or installing and/or using the %1 software, you are confirming your acceptance of the Software and agreeing to become bound by the terms of this EULA agreement.</p>
<p>If you are entering into this EULA agreement on behalf of a company or other legal entity, you represent that you have the authority to bind such entity and its affiliates to these terms and conditions. If you do not have such authority or if you do not agree with the terms and conditions of this EULA agreement, do not install or use the Software, and you must not accept this EULA agreement.</p>
<p>This EULA agreement shall apply only to the Software supplied by Komodo Platform herewith regardless of whether other software is referred to or described herein. The terms also apply to any Komodo Platform updates, supplements, Internet-based services, and support services for the Software, unless other terms accompany those items on delivery. If so, those terms apply.</p>
<h3>License Grant</h3>
<p>Komodo Platform hereby grants you a personal, non-transferable, non-exclusive licence to use the %1 software on your devices in accordance with the terms of this EULA agreement.</p>
<p>You are permitted to load the %1 software (for example a PC, laptop, mobile or tablet) under your control. You are responsible for ensuring your device meets the minimum security and resource requirements of the %1 software.</p>
<p><b>You are not permitted to:</b></p>
<ul>
<li>Edit, alter, modify, adapt, translate or otherwise change the whole or any part of the Software nor permit the whole or any part of the Software to be combined with or become incorporated in any other software, nor decompile, disassemble or reverse engineer the Software or attempt to do any such things</li>
<li>Reproduce, copy, distribute, resell or otherwise use the Software for any commercial purpose</li>
<li>Use the Software in any way which breaches any applicable local, national or international law</li>
<li>Use the Software for any purpose that Komodo Platform considers is a breach of this EULA agreement</li>
</ul>
<h3>Intellectual Property and Ownership</h3>
<p>Komodo Platform shall at all times retain ownership of the Software as originally downloaded by you and all subsequent downloads of the Software by you. The Software (and the copyright, and other intellectual property rights of whatever nature in the Software, including any modifications made thereto) are and shall remain the property of Komodo Platform.</p>
<p>Komodo Platform reserves the right to grant licences to use the Software to third parties.</p>
<h3>Termination</h3>
<p>This EULA agreement is effective from the date you first use the Software and shall continue until terminated. You may terminate it at any time upon written notice to Komodo Platform.</p>
<p>It will also terminate immediately if you fail to comply with any term of this EULA agreement. Upon such termination, the licenses granted by this EULA agreement will immediately terminate and you agree to stop all access and use of the Software. The provisions that by their nature continue and survive will survive any termination of this EULA agreement.</p>
<h3>Governing Law</h3>
<p>This EULA agreement, and any dispute arising out of or in connection with this EULA agreement, shall be governed by and construed in accordance with the laws of Vietnam.</p>
<p><b>This document was last updated on January 31st, 2020</b></p>"
            .arg(API.app_name)
    }
}
