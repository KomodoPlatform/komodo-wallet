/******************************************************************************
 * Copyright © 2013-2022 The Komodo Platform Developers.                      *
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

#pragma once

#include <QObject>

//! Deps
#include <entt/core/attribute.h>

namespace atomic_dex
{
    class ENTT_API CoinTypeGadget
    {
      public:
        Q_GADGET

      public:
        enum CoinTypeEnum
        {
            QRC20           = 0,
            ERC20           = 1,
            BEP20           = 2,
            UTXO            = 3,
            SmartChain      = 4,
            SLP             = 5,
            Matic           = 6,
            Optimism        = 7,
            Arbitrum        = 8,
            AVX20           = 9,
            FTM20           = 10,
            HRC20           = 11,
            Ubiq            = 12,
            KRC20           = 13,
            Moonriver       = 14,
            Moonbeam        = 15,
            HecoChain       = 16,
            SmartBCH        = 17,
            EthereumClassic = 18,
            RSK             = 19,
            ZHTLC           = 20,
            TENDERMINT      = 21,
            TENDERMINTTOKEN = 22,
            EWT             = 23,
            Disabled        = 24,
            Invalid         = 25,
            All             = 26,
            Size            = 27
        };

        Q_ENUM(CoinTypeEnum)

      private:
        explicit CoinTypeGadget();
    };
} // namespace atomic_dex

using CoinType = atomic_dex::CoinTypeGadget::CoinTypeEnum;
