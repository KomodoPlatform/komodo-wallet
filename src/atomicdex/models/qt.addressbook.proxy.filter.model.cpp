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

//! Project Headers
#include "atomicdex/models/qt.addressbook.model.hpp"
#include "atomicdex/models/qt.addressbook.proxy.filter.model.hpp"

namespace atomic_dex
{
    //! Constructor
    addressbook_proxy_model::addressbook_proxy_model(QObject* parent) : QSortFilterProxyModel(parent)
    {
    }

    //! Destructor
    addressbook_proxy_model::~addressbook_proxy_model()
    {
    }

    //! Protected members override
    bool
    addressbook_proxy_model::lessThan(const QModelIndex& source_left, const QModelIndex& source_right) const
    {
        int      role       = this->sortRole();
        QVariant left_data  = sourceModel()->data(source_left, role);
        QVariant right_data = sourceModel()->data(source_right, role);

        switch (static_cast<atomic_dex::addressbook_model::AddressBookRoles>(role))
        {
        case addressbook_model::SubModelRole:
            QObject*       left_obj      = qvariant_cast<QObject*>(left_data);
            contact_model* left_contact  = qobject_cast<contact_model*>(left_obj);
            QObject*       right_obj     = qvariant_cast<QObject*>(right_data);
            contact_model* right_contact = qobject_cast<contact_model*>(right_obj);
            return left_contact->get_name().toLower() < right_contact->get_name().toLower();
        }
        return false;
    }
} // namespace atomic_dex
