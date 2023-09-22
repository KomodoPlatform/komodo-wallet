/******************************************************************************
 * Copyright © 2013-2021 The Komodo Platform Developers.                      *
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

//! Deps
#include <nlohmann/json.hpp>
#include <boost/algorithm/string/trim.hpp>

//! Project Headers
#include "atomicdex/api/mm2/orderbook.order.contents.hpp"
#include "atomicdex/utilities/global.utilities.hpp"
#include "atomicdex/pages/qt.trading.page.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"
#include "atomicdex/services/price/orderbook.scanner.service.hpp"

namespace atomic_dex::mm2
{
    void
    from_json(const nlohmann::json& j, order_contents& contents)
    {

        j.at("coin").get_to(contents.coin);
        if (contents.coin.find("-segwit") != std::string::npos)
        {
            std::string uuid = j["uuid"];
            contents.uuid = uuid + "-segwit";
        }
        else
        {
            j.at("uuid").get_to(contents.uuid);
        }
        if (j.at("address").contains("address_data"))
        {
            j.at("address").at("address_data").get_to(contents.address);
        }
        else
        {
            contents.address = "Shielded";
        }
        j.at("pubkey").get_to(contents.pubkey);
        j.at("is_mine").get_to(contents.is_mine);

        j.at("price").at("decimal").get_to(contents.price);
        j.at("price").at("fraction").at("numer").get_to(contents.price_fraction_numer);
        j.at("price").at("fraction").at("denom").get_to(contents.price_fraction_denom);

        j.at("base_min_volume").at("decimal").get_to(contents.base_min_volume);
        j.at("base_min_volume").at("fraction").at("numer").get_to(contents.base_min_volume_numer);
        j.at("base_min_volume").at("fraction").at("denom").get_to(contents.base_min_volume_denom);
        j.at("base_max_volume").at("decimal").get_to(contents.base_max_volume);
        j.at("base_max_volume").at("fraction").at("numer").get_to(contents.base_max_volume_numer);
        j.at("base_max_volume").at("fraction").at("denom").get_to(contents.base_max_volume_denom);

        j.at("rel_min_volume").at("decimal").get_to(contents.rel_min_volume);
        j.at("rel_min_volume").at("fraction").at("numer").get_to(contents.rel_min_volume_numer);
        j.at("rel_min_volume").at("fraction").at("denom").get_to(contents.rel_min_volume_denom);
        j.at("rel_max_volume").at("decimal").get_to(contents.rel_max_volume);
        j.at("rel_max_volume").at("fraction").at("numer").get_to(contents.rel_max_volume_numer);
        j.at("rel_max_volume").at("fraction").at("denom").get_to(contents.rel_max_volume_denom);

        // Not in v2 RPC
        // j.at("age").get_to(contents.age);
        // j.at("zcredits").get_to(contents.zcredits);
    }

    std::string
    order_contents::to_string() const noexcept
    {
        std::stringstream ss;
        ss << "coin: " << coin << " ";
        ss << "address: " << address << " ";
        ss << "price: " << price << " ";
        ss << "depth_percent: " << depth_percent << " ";
        ss << "base_max_volume: " << base_max_volume << " ";
        ss << "rel_max_volume: " << rel_max_volume << " ";
        ss << "base_min_volume: " << base_min_volume << " ";
        ss << "rel_min_volume: " << rel_min_volume << " ";
        return ss.str();
    }
} // namespace atomic_dex::mm2