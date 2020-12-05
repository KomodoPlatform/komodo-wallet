// MIT License
//
// Copyright (c) 2020 Olivier Le Doeuff
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#ifndef __QATERIAL_HOTRELOAD_PCH_HPP__
#define __QATERIAL_HOTRELOAD_PCH_HPP__

#include <memory>
#include <set>

#include <spdlog/spdlog.h>
#include <spdlog/sinks/sink.h>

#include <QOlm/QOlm.hpp>
#include <Qaterial/Qaterial.hpp>

#include <QObject>
#include <QFile>
#include <QSaveFile>
#include <QObject>
#include <QString>
#include <QFileInfo>
#include <QUrl>
#include <QGuiApplication>
#include <QDir>
#include <QFontDatabase>

#include <QQmlEngine>
#include <QQmlFile>

#include <QQuickStyle>

#ifdef major
#    undef major
#endif
#ifdef minor
#    undef minor
#endif

#endif
