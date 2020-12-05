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

//! Qt
#include <QJsonDocument>

//! Project headers
#include "atomicdex/models/qt.addressbook.model.hpp"

//! Addressbook model
namespace atomic_dex
{
    addressbook_model::addressbook_model(atomic_dex::qt_wallet_manager& wallet_manager_, QObject* parent) noexcept :
        QAbstractListModel(parent), m_wallet_manager(wallet_manager_), m_addressbook_proxy(new addressbook_proxy_model(this))
    {
        this->m_addressbook_proxy->setSourceModel(this);
        this->m_addressbook_proxy->setSortRole(SubModelRole);
        this->m_addressbook_proxy->setDynamicSortFilter(true);
        this->m_addressbook_proxy->sort(0);
    }

    addressbook_model::~addressbook_model() noexcept
    {
    }

    int
    atomic_dex::addressbook_model::rowCount([[maybe_unused]] const QModelIndex& parent) const
    {
        return m_addressbook.count();
    }

    QVariant
    atomic_dex::addressbook_model::data(const QModelIndex& index, int role) const
    {
        if (!hasIndex(index.row(), index.column(), index.parent()))
        {
            return {};
        }

        switch (static_cast<AddressBookRoles>(role))
        {
        case SubModelRole:
            return QVariant::fromValue(m_addressbook.at(index.row()));
        default:
            return {};
        }
    }

    bool
    atomic_dex::addressbook_model::insertRows(int position, int rows, [[maybe_unused]] const QModelIndex& parent)
    {
        beginInsertRows(QModelIndex(), position, position + rows - 1);

        for (int row = 0; row < rows; ++row) { this->m_addressbook.insert(position, new contact_model(this->m_wallet_manager, this)); }

        endInsertRows();
        return true;
    }

    bool
    atomic_dex::addressbook_model::removeRows(int position, int rows, [[maybe_unused]] const QModelIndex& parent)
    {
        beginRemoveRows(QModelIndex(), position, position + rows - 1);

        for (int row = 0; row < rows; ++row)
        {
            contact_model* element = this->m_addressbook.at(position);
            if ((element->rowCount(QModelIndex()) == 0 && not element->get_name().isEmpty()) ||
                (this->m_should_delete_contacts && not element->get_name().isEmpty()))
            {
                this->m_wallet_manager.delete_contact(element->get_name());
                this->m_wallet_manager.update_wallet_cfg();
            }
            delete element;
            this->m_addressbook.removeAt(position);
        }

        endRemoveRows();
        return true;
    }

    void
    atomic_dex::addressbook_model::initializeFromCfg()
    {
        this->m_addressbook.clear();
        auto functor = [this](const atomic_dex::contact& cur_contact) {
            int position = 0;
            int rows     = 1;

            auto* contact_ptr = new contact_model(this->m_wallet_manager, nullptr);
            contact_ptr->set_name(QString::fromStdString(cur_contact.name));
            for (auto&& contact_contents: cur_contact.contents)
            {
                contact_ptr->m_addresses.push_back(qt_contact_address_contents{
                    .type = QString::fromStdString(contact_contents.type), .address = QString::fromStdString(contact_contents.address)});
            }
            beginInsertRows(QModelIndex(), this->m_addressbook.count(), this->m_addressbook.count());

            for (int row = 0; row < rows; ++row)
            {
                //! Insert contact
                this->m_addressbook.push_back(contact_ptr);
            }

            endInsertRows();
        };
        const wallet_cfg& cfg = this->m_wallet_manager.get_wallet_cfg();
        for (auto&& cur: cfg.address_book) { functor(cur); }
    }

    void
    atomic_dex::addressbook_model::add_contact_entry()
    {
        insertRow(0);
    }

    void
    atomic_dex::addressbook_model::remove_at(int position)
    {
        this->m_should_delete_contacts = true;
        removeRow(position);
        this->m_should_delete_contacts = false;
    }

    QHash<int, QByteArray>
    atomic_dex::addressbook_model::roleNames() const
    {
        return {
            {SubModelRole, "contacts"},
        };
    }

    addressbook_proxy_model*
    addressbook_model::get_addressbook_proxy_mdl() const noexcept
    {
        return m_addressbook_proxy;
    }

    void
    addressbook_model::cleanup()
    {
        int nb_rows = this->rowCount(QModelIndex()) - 1;
        for (int cur_contact_idx = 0; cur_contact_idx < nb_rows; ++cur_contact_idx)
        {
            QVariant       value       = this->data(index(cur_contact_idx, 0), SubModelRole);
            QObject*       obj         = qvariant_cast<QObject*>(value);
            contact_model* cur_contact = qobject_cast<contact_model*>(obj);
            for (int cur_idx = 0; cur_idx < cur_contact->rowCount(QModelIndex()); ++cur_idx)
            {
                if (cur_contact->data(index(cur_idx), contact_model::ContactRoles::AddressRole).toString().isEmpty())
                {
                    cur_contact->remove_at(cur_idx);
                }
            }
            if (cur_contact->get_addresses().isEmpty())
            {
                this->remove_at(cur_contact_idx);
            }
        }
    }
} // namespace atomic_dex
