#pragma once

//! Deps
#include <entt/core/attribute.h>

#include <QObject>

namespace atomic_dex
{
    class ENTT_API MarketModeGadget
    {
        Q_GADGET

      public:
        enum MarketModeEnum
        {
            Sell = 0,
            Buy  = 1
        };

        Q_ENUM(MarketModeEnum)

      private:
        explicit MarketModeGadget();
    };

    class ENTT_API TradingErrorGadget
    {
        Q_GADGET

      public:
        enum TradingErrorEnum
        {
            None                         = 0,
            TradingFeesNotEnoughFunds    = 1, ///< If trading_fee_ticker != transaction_fee_ticker this error can happens BAT <-> ETH (not enough BAT)
            BaseNotEnoughFunds           = 2, ///< can be set only if trading_fee_ticker == transaction_fee_ticker <-> KMD <-> BTC (not enough KMD)
            BaseTransactionFeesNotEnough = 3, ///< If trading_fee_ticker != transaction_fee_ticker this error can happens BAT <-> ETH (not enough ETH)
            RelTransactionFeesNotEnough  = 4, ///< KMD <-> ETH (not enough ETH)
            BalanceIsLessThanTheMinimalTradingAmount = 5, ///< max_trading_vol < 0.00777
            PriceFieldNotFilled                      = 6, ///< Price empty or 0
            VolumeFieldNotFilled                     = 7, ///< Volume empty or 0
            VolumeIsLowerThanTheMinimum              = 8, ///< Volume field < 0.00777
            ReceiveVolumeIsLowerThanTheMinimum       = 9
        };

        Q_ENUM(TradingErrorEnum)

      private:
        explicit TradingErrorGadget();
    };
} // namespace atomic_dex

using MarketMode   = atomic_dex::MarketModeGadget::MarketModeEnum;
using TradingError = atomic_dex::TradingErrorGadget::TradingErrorEnum;