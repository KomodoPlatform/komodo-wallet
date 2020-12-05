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

//! Project
#include "atomicdex/models/qt.contact.model.hpp"

namespace atomic_dex
{
    contact_model::contact_model(atomic_dex::qt_wallet_manager& wallet_manager_, QObject* parent) noexcept :
        QAbstractListModel(parent), m_wallet_manager(wallet_manager_)
    {
    }

    contact_model::~contact_model() noexcept
    {
    }

    QString
    atomic_dex::contact_model::get_name() const noexcept
    {
        return m_name;
    }

    void
    atomic_dex::contact_model::set_name(const QString& name) noexcept
    {
        if (name != m_name)
        {
            this->m_wallet_manager.update_or_insert_contact_name(m_name, name);
            this->m_wallet_manager.update_wallet_cfg();
            m_name = name;
            emit nameChanged();
        }
    }

    QVariant
    contact_model::data(const QModelIndex& index, int role = Qt::DisplayRole) const
    {
        if (!hasIndex(index.row(), index.column(), index.parent()))
        {
            return {};
        }

        const qt_contact_address_contents& item = m_addresses.at(index.row());
        switch (role)
        {
        case TypeRole:
            return item.type;
        case AddressRole:
            return item.address;
        default:
            return {};
        }
    }

    bool
    atomic_dex::contact_model::setData(const QModelIndex& index, const QVariant& value, int role)
    {
        if (!hasIndex(index.row(), index.column(), index.parent()) || !value.isValid())
        {
            return false;
        }

        qt_contact_address_contents& item = m_addresses[index.row()];
        switch (role)
        {
        case TypeRole:
            if (value.toString() != item.type)
            {
                this->m_wallet_manager.update_contact_ticker(this->m_name, item.type, value.toString());
                this->m_wallet_manager.update_wallet_cfg();
                item.type = value.toString();
            }
            break;
        case AddressRole:
            if (value.toString() != item.address)
            {
                item.address = value.toString();
                this->m_wallet_manager.update_contact_address(this->m_name, item.type, item.address);
                this->m_wallet_manager.update_wallet_cfg();
                emit addressesChanged();
            }
            break;
        default:
            return false;
        }

        emit dataChanged(index, index, {role});
        return true;
    }

    QVariantList
    atomic_dex::contact_model::get_addresses() const noexcept
    {
        QVariantList out;
        out.reserve(this->m_addresses.count());
        for (auto&& cur: this->m_addresses)
        {
            nlohmann::json j{{"type", cur.type.toStdString()}, {"address", cur.address.toStdString()}};
            QJsonDocument  q_json = QJsonDocument::fromJson(QString::fromStdString(j.dump()).toUtf8());
            out.push_back(q_json.toVariant());
        }
        return out;
    }

    bool
    atomic_dex::contact_model::insertRows(int position, int rows, [[maybe_unused]] const QModelIndex& parent)
    {
        beginInsertRows(QModelIndex(), position, position + rows - 1);

        for (int row = 0; row < rows; ++row) { this->m_addresses.insert(position, qt_contact_address_contents{}); }

        endInsertRows();
        emit addressesChanged();
        return true;
    }

    bool
    atomic_dex::contact_model::removeRows(int position, int rows, [[maybe_unused]] const QModelIndex& parent)
    {
        beginRemoveRows(QModelIndex(), position, position + rows - 1);

        for (int row = 0; row < rows; ++row)
        {
            auto contact_contents = this->m_addresses.at(position);
            this->m_wallet_manager.remove_address_entry(this->m_name, contact_contents.type);
            this->m_wallet_manager.update_wallet_cfg();
            this->m_addresses.removeAt(position);
        }

        endRemoveRows();
        emit addressesChanged();
        return true;
    }

    void
    atomic_dex::contact_model::add_address_content()
    {
        insertRow(0);
    }

    void
    atomic_dex::contact_model::remove_at(int position)
    {
        removeRow(position);
    }

    int
    contact_model::rowCount([[maybe_unused]] const QModelIndex& parent = QModelIndex()) const
    {
        return m_addresses.size();
    }

    QHash<int, QByteArray>
    atomic_dex::contact_model::roleNames() const
    {
        return {
            {TypeRole, "type"},
            {AddressRole, "address"},
        };
    }
} // namespace atomic_dex
