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

#ifndef __QATERIAL_HOT_RELOAD_HPP__
#define __QATERIAL_HOT_RELOAD_HPP__

// ──── INCLUDE ────

#include <spdlog/sinks/base_sink.h>

#include <QQmlEngine>
#include <QtQml>
#include <QFileSystemWatcher>

// ──── DECLARATION ────

namespace qaterial {

class HotReloadSink : public spdlog::sinks::base_sink<std::mutex>
{
public:
    class HotReload* _hotReload = nullptr;

    void sink_it_(const spdlog::details::log_msg& msg) override;
    void flush_() override {}
};

class HotReload : public QObject
{
    Q_OBJECT

public:
    HotReload(QQmlEngine* engine, QObject* parent);

private:
    QQmlEngine* _engine;
    QFileSystemWatcher _watcher;
    static const std::shared_ptr<HotReloadSink> _sink;
    QStringList _defaultImportPaths;

    Q_PROPERTY(QStringList importPaths READ importPaths WRITE setImportPaths RESET resetImportPaths NOTIFY importPathsChanged)

public:
    QStringList importPaths() const { return _engine->importPathList(); }
    void setImportPaths(const QStringList& paths)
    {
        _engine->setImportPathList(paths);
        Q_EMIT importPathsChanged();
    }
    void resetImportPaths() { setImportPaths(_defaultImportPaths); }

Q_SIGNALS:
    void importPathsChanged();

public Q_SLOTS:
    void clearCache() const;

    void watchFile(const QString& path);
    void unWatchFile(const QString& path);
Q_SIGNALS:
    void watchedFileChanged();
    void newLog(QString s);

public:
    static std::shared_ptr<HotReloadSink> sink();

public:
    static void registerSingleton();
};

}

#endif
