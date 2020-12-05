// Copyright Olivier Le Doeuff 2020 (C)

import QtQuick 2.15
import Qaterial 1.0 as Qaterial
import Qaterial.HotReload 1.0 as HR

Qaterial.SplashScreenWindow
{
  id: splash

  image: Qaterial.Style.theme === Qaterial.Style.Theme.Dark ? HR.Images.qaterialHotreloadWhite : HR.Images.qaterialHotreloadBlack
  padding: Qaterial.Style.card.horizontalPadding

  text: "Loading ..."
  version: Qaterial.Version.readable

  property int dots: 1

  Timer
  {
    interval: 1000;running: true;repeat: true
    onTriggered: function()
    {
      ++splash.dots
      let text = "Loading "
      for(let i = 0; i < splash.dots; ++i)
        text += '.'

      splash.text = text
      if(splash.dots == 3)
        splash.dots = 0
    }
  }
}
