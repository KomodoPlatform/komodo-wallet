/******************************************************************************
 * Copyright © 2013-2019 The Komodo Platform Developers.                      *
 *                                                                            *
 * See the AUTHORS, DEVELOPER-AGREEMENT and LICENSE files at                  *
 * the top-level directory of this distribution for the individual copyright  *
 * holder information and the developer policies on copyright and licensing.  *
 *                                                                            *
 * Unless otherwise agreed in a custom licensing agreement, no part of the    *
 * Komodo Platform software, including this file may be copied, modified,     *
 * propagated or distributed except according to the terms contained in the   *
 * LICENSE file                                                               *
 *                                                                            *
 * Removal or modification of this copyright notice is prohibited.            *
 *                                                                            *
 ******************************************************************************/

//! QT
#include <QJsonDocument>
#include <QJsonObject>

//! Deps
#include <nlohmann/json.hpp>

//! Project Headers
#include "atomicdex/models/qt.candlestick.charts.model.hpp"
#include "atomicdex/services/ohlc/ohlc.provider.hpp"

namespace atomic_dex
{
    candlestick_charts_model::candlestick_charts_model(ag::ecs::system_manager& system_manager, QObject* parent) :
        QAbstractTableModel(parent), m_system_manager(system_manager)
    {
        SPDLOG_DEBUG("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());
        SPDLOG_DEBUG("candlestick charts model created");
    }

    candlestick_charts_model::~candlestick_charts_model() noexcept
    {
        SPDLOG_DEBUG("{} l{} f[{}]", __FUNCTION__, __LINE__, fs::path(__FILE__).filename().string());
        SPDLOG_DEBUG("candlestick charts model destroyed");
    }

    int
    candlestick_charts_model::rowCount([[maybe_unused]] const QModelIndex& parent) const
    {
        if (m_model_data.empty())
        {
            return 0;
        }
        return m_model_data.size();
    }

    int
    candlestick_charts_model::columnCount([[maybe_unused]] const QModelIndex& parent) const
    {
        return 12;
    }

    QVariant
    candlestick_charts_model::data([[maybe_unused]] const QModelIndex& index, [[maybe_unused]] int role) const
    {
        Q_UNUSED(role)

        if (!index.isValid())
        {
            return QVariant();
        }

        if (index.row() >= rowCount() || index.row() < 0)
        {
            return QVariant();
        }

        switch (index.column())
        {
        case 0:
            return m_model_data.at(index.row()).at("timestamp").get<unsigned long long>() * 1000ull;
        case 1:
            return m_model_data.at(index.row()).at("open").get<double>();
        case 2:
            return m_model_data.at(index.row()).at("high").get<double>();
        case 3:
            return m_model_data.at(index.row()).at("low").get<double>();
        case 4:
            return m_model_data.at(index.row()).at("close").get<double>();
        case 5:
            return m_model_data.at(index.row()).at("volume").get<double>();

        // Volume Candlestick chart
        case 6: // Open
            return m_model_data.at(index.row()).at("close").get<double>() >= m_model_data.at(index.row()).at("open").get<double>()
                       ? 0
                       : m_model_data.at(index.row()).at("volume").get<double>();
        case 7: // High
            return m_model_data.at(index.row()).at("volume").get<double>();
        case 8: // Low
            return 0;
        case 9: // Close
            return m_model_data.at(index.row()).at("close").get<double>() >= m_model_data.at(index.row()).at("open").get<double>()
                       ? m_model_data.at(index.row()).at("volume").get<double>()
                       : 0;

        //! MA 20
        case 10:
            return m_model_data.at(index.row()).contains("ma_20") ? m_model_data.at(index.row()).at("ma_20").get<double>()
                                                                  : m_model_data.at(index.row()).at("open").get<double>();
        //! MA 50
        case 11:
            return m_model_data.at(index.row()).contains("ma_50") ? m_model_data.at(index.row()).at("ma_50").get<double>()
                                                                  : m_model_data.at(index.row()).at("open").get<double>();
        default:
            return QVariant();
        }
    }

    bool
    candlestick_charts_model::common_reset_data()
    {
        auto& provider = this->m_system_manager.get_system<ohlc_provider>();
        if (not provider.is_ohlc_data_available())
        {
            this->clear_data();
            return false;
        }

        this->beginResetModel();
        this->m_model_data = provider.get_ohlc_data(m_current_range);
        this->endResetModel();
        this->set_is_currently_fetching(false);

        return true;
    }

    void
    candlestick_charts_model::init_data()
    {
        if (not common_reset_data())
        {
            return;
        }
        emit chartFullyModelReset();

        if (m_model_data.empty())
        {
            // this->set_is_currently_fetching(false);
            return;
        }
        double max_value = std::numeric_limits<double>::min();
        double min_value = std::numeric_limits<double>::max();

        for (auto&& cur: m_model_data)
        {
            if (auto min_to_compare = cur.at("low").get<double>(); min_value > min_to_compare)
            {
                min_value = min_to_compare;
            }
            if (auto max_to_compare = cur.at("high").get<double>(); max_value < max_to_compare)
            {
                max_value = max_to_compare;
            }
        }
        SPDLOG_DEBUG("new range value IS: min: {} / max: {}", min_value, max_value);
        this->set_global_min_value(min_value);
        this->set_global_max_value(max_value);

        auto date_start       = m_model_data[int(this->m_model_data.size() * 0.9)].at("timestamp").get<int>();
        auto date_end         = m_model_data.back().at("timestamp").get<int>();
        auto date_diff        = date_end - date_start;
        auto date_init_margin = date_diff * 0.1;
        date_start += date_init_margin;
        date_end += date_init_margin;
        QDateTime from, to;
        from.setSecsSinceEpoch(date_start);
        to.setSecsSinceEpoch(date_end);
        this->set_series_from(from);
        this->set_series_to(to);
        this->set_min_value(m_visible_min_value);
        this->set_max_value(m_visible_max_value);

        emit seriesSizeChanged(get_series_size());
    }

    void
    candlestick_charts_model::update_data()
    {
        if (not common_reset_data())
        {
            return;
        }

        emit seriesSizeChanged(get_series_size());
    }

    int
    candlestick_charts_model::get_series_size() const noexcept
    {
        return rowCount();
    }

    void
    candlestick_charts_model::clear_data()
    {
        //! If it's already empty dont reset the model
        if (this->m_model_data.empty())
        {
            SPDLOG_DEBUG("already empty, skipping");
            return;
        }

        SPDLOG_DEBUG("clearing the chart candlestick model");
        beginResetModel();
        this->m_model_data.clear();
        this->set_min_value(0);
        this->set_max_value(0);
        endResetModel();
        emit seriesFromChanged(get_series_from());
        emit seriesToChanged(get_series_to());
        emit seriesSizeChanged(get_series_size());
    }

    QString
    candlestick_charts_model::get_current_range() const noexcept
    {
        return QString::fromStdString(m_current_range);
    }

    void
    candlestick_charts_model::set_current_range(const QString& range) noexcept
    {
        this->m_current_range = range.toStdString();
        init_data();
        emit rangeChanged();
    }

    QDateTime
    atomic_dex::candlestick_charts_model::get_series_to() const noexcept
    {
        if (this->m_model_data.empty())
        {
            return QDateTime();
        }
        return m_series_to;
    }

    QDateTime
    atomic_dex::candlestick_charts_model::get_series_from() const noexcept
    {
        if (this->m_model_data.empty())
        {
            return QDateTime();
        }
        return m_series_from;
    }

    double
    candlestick_charts_model::get_min_value() const noexcept
    {
        return m_min_value;
    }

    double
    candlestick_charts_model::get_max_value() const noexcept
    {
        return m_max_value;
    }

    double
    candlestick_charts_model::get_global_min_value() const noexcept
    {
        return m_global_min_value;
    }

    double
    candlestick_charts_model::get_global_max_value() const noexcept
    {
        return m_global_max_value;
    }

    void
    candlestick_charts_model::set_global_max_value(double value)
    {
        if (qFuzzyCompare(m_global_max_value, value))
        {
            return;
        }

        m_global_max_value = value;
        emit globalMaxValueChanged(m_global_max_value);
    }

    void
    candlestick_charts_model::set_global_min_value(double value)
    {
        if (qFuzzyCompare(m_global_min_value, value))
        {
            return;
        }

        m_global_min_value = value;
        emit globalMinValueChanged(m_global_min_value);
    }

    void
    candlestick_charts_model::set_max_value(double value)
    {
        if (qFuzzyCompare(m_max_value, value))
        {
            return;
        }

        m_max_value = value;
        emit maxValueChanged(m_max_value);
    }

    void
    candlestick_charts_model::set_min_value(double value)
    {
        if (qFuzzyCompare(m_min_value, value))
        {
            return;
        }

        m_min_value = value;
        emit minValueChanged(m_min_value);
    }

    void
    candlestick_charts_model::set_series_from(QDateTime value)
    {
        m_series_from = std::move(value);
        emit seriesFromChanged(m_series_from);
    }

    void
    candlestick_charts_model::set_series_to(QDateTime value)
    {
        m_series_to = std::move(value);
        emit seriesToChanged(m_series_to);
        this->update_visible_range();
    }

    void
    candlestick_charts_model::update_visible_range()
    {
        auto from_timestamp  = get_series_from().toSecsSinceEpoch();
        auto first_timestamp = m_model_data[0].at("timestamp").get<int>();
        if (from_timestamp < first_timestamp)
        {
            from_timestamp = first_timestamp;
        }

        auto to_timestamp   = get_series_to().toSecsSinceEpoch();
        auto last_timestamp = m_model_data[m_model_data.size() - 1].at("timestamp").get<int>();
        if (to_timestamp > last_timestamp)
        {
            to_timestamp = last_timestamp;
        }

        auto from_it = std::lower_bound(begin(m_model_data), end(m_model_data), from_timestamp, [](const nlohmann::json& current_json, int timestamp) {
            int res = current_json.at("timestamp").get<int>();
            return res < timestamp;
        });

        auto to_it = std::lower_bound(begin(m_model_data), end(m_model_data), to_timestamp, [](const nlohmann::json& current_json, int timestamp) {
            int res = current_json.at("timestamp").get<int>();
            return res < timestamp;
        });

        if (from_it != m_model_data.end() && to_it != m_model_data.end())
        {
            auto min_value_j = std::min_element(from_it, to_it, [](nlohmann::json& left, nlohmann::json& right) {
                auto left_value  = left.at("low").get<double>();
                auto right_value = right.at("low").get<double>();
                return left_value < right_value;
            });

            auto max_value_j = std::max_element(from_it, to_it, [](nlohmann::json& left, nlohmann::json& right) {
                auto left_value  = left.at("high").get<double>();
                auto right_value = right.at("high").get<double>();
                return left_value < right_value;
            });

            auto max_volume_j = std::max_element(from_it, to_it, [](nlohmann::json& left, nlohmann::json& right) {
                auto left_value  = left.at("volume").get<double>();
                auto right_value = right.at("volume").get<double>();
                return left_value < right_value;
            });

            auto min_value  = min_value_j->at("low").get<double>();
            auto max_value  = max_value_j->at("high").get<double>();
            auto max_volume = max_volume_j->at("volume").get<double>();
            this->set_visible_min_value(min_value);
            this->set_visible_max_value(max_value);
            this->set_visible_max_volume(max_volume);
        }
    }

    double
    candlestick_charts_model::get_visible_max_volume() const noexcept
    {
        return m_visible_max_volume;
    }

    double
    candlestick_charts_model::get_visible_max_value() const noexcept
    {
        return m_visible_max_value;
    }

    double
    candlestick_charts_model::get_visible_min_value() const noexcept
    {
        return m_visible_min_value;
    }

    void
    candlestick_charts_model::set_visible_max_volume(double value)
    {
        if (qFuzzyCompare(m_visible_max_volume, value))
        {
            return;
        }

        m_visible_max_volume = value;
        emit visibleMaxVolumeChanged(m_visible_max_volume);
    }

    void
    candlestick_charts_model::set_visible_max_value(double value)
    {
        if (qFuzzyCompare(m_visible_max_value, value))
        {
            return;
        }

        m_visible_max_value = value;
        emit visibleMaxValueChanged(m_visible_max_value);
    }

    void
    candlestick_charts_model::set_visible_min_value(double value)
    {
        if (qFuzzyCompare(m_visible_min_value, value))
        {
            return;
        }

        m_visible_min_value = value;
        emit visibleMinValueChanged(m_visible_min_value);
    }

    bool
    candlestick_charts_model::is_pair_supported() const noexcept
    {
        return m_current_pair_supported;
    }

    void
    candlestick_charts_model::set_is_pair_supported(bool is_support)
    {
        if (is_support != m_current_pair_supported)
        {
            m_current_pair_supported = is_support;
            emit pairSupportedChanged(m_current_pair_supported);
        }
    }

    bool
    candlestick_charts_model::is_currently_fetching() const noexcept
    {
        return m_currently_fetching;
    }

    void
    candlestick_charts_model::set_is_currently_fetching(bool is_fetching)
    {
        if (is_fetching != m_currently_fetching)
        {
            this->m_currently_fetching = is_fetching;
            emit fetchingStatusChanged(m_currently_fetching);
        }
    }

    QVariantMap
    candlestick_charts_model::find_closest_ohlc_data(int timestamp)
    {
        QVariantMap out;

        auto it = std::lower_bound(rbegin(m_model_data), rend(m_model_data), timestamp, [](const nlohmann::json& current_json, int timestamp) {
            int res = current_json.at("timestamp").get<int>();
            return timestamp < res;
        });

        if (it != m_model_data.rend())
        {
            QJsonDocument q_json = QJsonDocument::fromJson(QString::fromStdString(it->dump()).toUtf8());
            out                  = q_json.object().toVariantMap();
        }
        return out;
    }
} // namespace atomic_dex
