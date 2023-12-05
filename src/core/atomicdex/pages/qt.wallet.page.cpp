#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>

//! Deps
#include <QrCode.hpp>
#include <antara/app/net/http.code.hpp>
#include <antara/gaming/core/security.authentification.hpp>

//! Project Headers
#include "atomicdex/api/faucet/faucet.hpp"
#include "atomicdex/api/mm2/rpc.convertaddress.hpp"
#include "atomicdex/api/mm2/rpc.electrum.hpp"
#include "atomicdex/api/mm2/rpc.validate.address.hpp"
#include "atomicdex/api/mm2/rpc2.withdraw.hpp"
#include "atomicdex/api/mm2/rpc2.task.withdraw.init.hpp"
#include "atomicdex/api/mm2/rpc2.task.withdraw.status.hpp"
#include "atomicdex/services/mm2/mm2.service.hpp"
#include "atomicdex/services/price/global.provider.hpp"
#include "atomicdex/services/price/komodo_prices/komodo.prices.provider.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"
#include "qt.portfolio.page.hpp"
#include "qt.settings.page.hpp"
#include "qt.wallet.page.hpp"

namespace atomic_dex
{
    wallet_page::wallet_page(entt::registry& registry, ag::ecs::system_manager& system_manager, QObject* parent) :
        QObject(parent), system(registry), m_system_manager(system_manager), m_transactions_mdl(new transactions_model(system_manager, this))
    {
        this->dispatcher_.sink<tx_fetch_finished>().connect<&wallet_page::on_tx_fetch_finished>(*this);
        this->dispatcher_.sink<ticker_balance_updated>().connect<&wallet_page::on_ticker_balance_updated>(*this);
    }

    void
    wallet_page::update()
    {
        if (!m_page_open)
        {
            return;
        }
        using namespace std::chrono_literals;

        const auto now = std::chrono::high_resolution_clock::now();
        const auto s   = std::chrono::duration_cast<std::chrono::seconds>(now - m_update_clock);
        if (s >= 1s)
        {
            check_send_availability();
            m_update_clock = std::chrono::high_resolution_clock::now();
        }
    }
} // namespace atomic_dex

//! Private API
namespace atomic_dex
{
    void
    wallet_page::check_send_availability()
    {
        auto& mm2              = m_system_manager.get_system<mm2_service>();
        auto  global_coins_cfg = m_system_manager.get_system<portfolio_page>().get_global_cfg();
        auto  ticker_info      = global_coins_cfg->get_coin_info(mm2.get_current_ticker());

        m_send_available                   = true;
        m_send_availability_state          = "";
        m_current_ticker_fees_coin_enabled = true;
        if (not mm2.get_balance(ticker_info.ticker) > 0)
        {
            m_send_available                   = false;
            m_send_availability_state          = tr("You do not have enough funds.");
            m_current_ticker_fees_coin_enabled = true;
        }
        else if (ticker_info.has_parent_fees_ticker)
        {
            auto parent_ticker_info = global_coins_cfg->get_coin_info(ticker_info.fees_ticker);

            if (!parent_ticker_info.currently_enabled)
            {
                m_send_available = true;
                m_send_availability_state =
                    tr("%1 is not activated: click on the button to enable it or enable it manually").arg(QString::fromStdString(parent_ticker_info.ticker));
                m_current_ticker_fees_coin_enabled = false;
            }
            else if (not mm2.get_balance(parent_ticker_info.ticker) > 0)
            {
                m_send_available          = false;
                m_send_availability_state = tr("You need to have %1 to pay the gas for %2 transactions.")
                                                .arg(QString::fromStdString(parent_ticker_info.ticker))
                                                .arg(QString::fromStdString(parent_ticker_info.type));
                m_current_ticker_fees_coin_enabled = true;
            }
        }
        emit sendAvailableChanged();
        emit sendAvailabilityStateChanged();
        emit currentTickerFeesCoinEnabledChanged();
    }
} // namespace atomic_dex

//! Getters/Setters
namespace atomic_dex
{
    QString wallet_page::get_current_ticker() const
    {
        const auto& mm2_system = m_system_manager.get_system<mm2_service>();
        return QString::fromStdString(mm2_system.get_current_ticker());
    }

    void wallet_page::set_current_ticker(const QString& ticker, bool force)
    {
        auto& mm2_system = m_system_manager.get_system<mm2_service>();
        auto  coin_info  = mm2_system.get_coin_info(ticker.toStdString());
        if (mm2_system.set_current_ticker(ticker.toStdString()) || force)
        {
            SPDLOG_INFO("new ticker: {}", ticker.toStdString());
            m_transactions_mdl->reset();
            this->set_tx_fetching_busy(true);
            mm2_system.fetch_infos_thread(true, true);
            emit currentTickerChanged();
            refresh_ticker_infos();
            check_send_availability();
        }
    }

    bool
    wallet_page::is_rpc_claiming_busy() const
    {
        return m_is_claiming_busy.load();
    }

    void
    wallet_page::set_claiming_is_busy(bool status)
    {
        if (m_is_claiming_busy != status)
        {
            m_is_claiming_busy = status;
            emit rpcClaimingStatusChanged();
        }
    }

    bool
    wallet_page::is_claiming_faucet_busy() const
    {
        return m_is_claiming_faucet_busy.load();
    }

    void
    wallet_page::set_claiming_faucet_is_busy(bool status)
    {
        if (m_is_claiming_faucet_busy != status)
        {
            m_is_claiming_faucet_busy = status;
            emit claimingFaucetStatusChanged();
        }
    }

    void
    wallet_page::set_send_busy(bool status)
    {
        if (m_is_send_busy != status)
        {
            m_is_send_busy = status;
            emit sendStatusChanged();
        }
    }

    bool
    wallet_page::is_send_busy() const
    {
        return m_is_send_busy.load();
    }

    bool
    wallet_page::is_broadcast_busy() const
    {
        return m_is_broadcast_busy.load();
    }

    void
    wallet_page::set_broadcast_busy(bool status)
    {
        if (m_is_broadcast_busy != status)
        {
            m_is_broadcast_busy = status;
            emit broadCastStatusChanged();
        }
    }

    bool
    wallet_page::is_convert_address_busy() const
    {
        return m_convert_address_busy.load();
    }

    void
    wallet_page::set_convert_address_busy(bool status)
    {
        if (m_convert_address_busy != status)
        {
            m_convert_address_busy = status;
            emit convertAddressBusyChanged();
        }
    }

    bool
    wallet_page::is_validate_address_busy() const
    {
        return m_validate_address_busy.load();
    }

    void
    wallet_page::set_validate_address_busy(bool status)
    {
        if (m_validate_address_busy != status)
        {
            m_validate_address_busy = status;
            emit validateAddressBusyChanged();
        }
    }

    bool atomic_dex::wallet_page::is_tx_fetching_busy() const
    {
        return m_tx_fetching_busy;
    }

    void atomic_dex::wallet_page::set_tx_fetching_busy(bool status)
    {
        if (m_tx_fetching_busy != status)
        {
            m_tx_fetching_busy = status;
            emit txFetchingStatusChanged();
        }
    }

    bool atomic_dex::wallet_page::is_tx_fetching_failed() const
    {
        return m_tx_fetching_failed;
    }

    void atomic_dex::wallet_page::set_tx_fetching_failed(bool status)
    {
        if (m_tx_fetching_failed != status)
        {
            m_tx_fetching_failed = status;
            emit txFetchingOutcomeChanged();
        }
    }

    QVariant wallet_page::get_ticker_infos() const
    {
        QJsonObject obj{
            {"balance", "0"},
            {"name", "Komodo"},
            {"type", "SmartChain"},
            {"is_claimable", true},
            {"address", "foo"},
            {"minimal_balance_asking_rewards", "10.00"},
            {"explorer_url", "foo"},
            {"current_currency_ticker_price", "0.00"},
            {"change_24h", "0"},
            {"tx_state", "InProgress"},
            {"fiat_amount", "0.00"},
            {"trend_7d", QJsonArray()},
            {"activation_status", QJsonObject()},
            {"fee_ticker", DEX_PRIMARY_COIN},
            {"blocks_left", 1},
            {"transactions_left", 0},
            {"current_block", 1},
            {"is_faucet_coin", false},
            {"qrcode_address", ""},
            {"segwit_supported", false}};
        std::error_code ec;
        auto&           mm2_system = m_system_manager.get_system<mm2_service>();
        if (mm2_system.is_mm2_running())
        {
            auto&       price_service                 = m_system_manager.get_system<global_price_service>();
            const auto& settings_system               = m_system_manager.get_system<settings_page>();
            const auto& provider                      = m_system_manager.get_system<komodo_prices_provider>();
            const auto& ticker                        = mm2_system.get_current_ticker();
            const auto& coin_info                     = mm2_system.get_coin_info(ticker);
            const auto& config                        = settings_system.get_cfg();
            obj["balance"]                            = QString::fromStdString(mm2_system.my_balance(ticker, ec));
            obj["name"]                               = QString::fromStdString(coin_info.name);
            obj["type"]                               = QString::fromStdString(coin_info.type);
            obj["segwit_supported"]                   = coin_info.segwit;
            obj["has_parent_fees_ticker"]             = coin_info.has_parent_fees_ticker;
            obj["fees_ticker"]                        = QString::fromStdString(coin_info.fees_ticker);
            obj["is_claimable"]                       = coin_info.is_claimable;
            obj["minimal_balance_for_asking_rewards"] = QString::fromStdString(coin_info.minimal_claim_amount);
            obj["explorer_url"]                       = QString::fromStdString(coin_info.explorer_url);
            obj["current_currency_ticker_price"]      = QString::fromStdString(price_service.get_rate_conversion(config.current_currency, ticker, true));
            obj["change_24h"]                         = retrieve_change_24h(provider, coin_info, config, m_system_manager);
            const auto& tx_state                      = mm2_system.get_tx_state(ec);
            obj["tx_state"]                           = QString::fromStdString(tx_state.state);
            obj["fiat_amount"]                        = QString::fromStdString(price_service.get_price_in_fiat(config.current_currency, ticker, ec));
            obj["activation_status"]                  = nlohmann_json_object_to_qt_json_object(coin_info.activation_status);
            obj["trend_7d"]                           = nlohmann_json_array_to_qt_json_array(provider.get_ticker_historical(ticker));
            obj["fee_ticker"]                         = QString::fromStdString(coin_info.fees_ticker);
            obj["blocks_left"]                        = static_cast<qint64>(tx_state.blocks_left);
            obj["transactions_left"]                  = static_cast<qint64>(tx_state.transactions_left);
            obj["current_block"]                      = static_cast<qint64>(tx_state.current_block);
            obj["is_faucet_coin"]                     = coin_info.is_faucet_coin;

            std::error_code   ec;
            if (!mm2_system.is_zhtlc_coin_ready(coin_info.ticker))
            {
                obj["address"]        = "activating";
                obj["qrcode_address"] = "";

            }
            else
            {
                obj["address"]        = QString::fromStdString(mm2_system.address(ticker, ec));
                qrcodegen::QrCode qr0 = qrcodegen::QrCode::encodeText(mm2_system.address(ticker, ec).c_str(), qrcodegen::QrCode::Ecc::MEDIUM);
                std::string       svg = qr0.toSvgString(2);
                obj["qrcode_address"] = QString::fromStdString("data:image/svg+xml;base64,") + QString::fromStdString(svg).toLocal8Bit().toBase64();
            }
        }
        return obj;
    }

    QVariant
    wallet_page::get_validate_address_data() const
    {
        return m_validate_address_result.get();
    }

    void
    wallet_page::set_validate_address_data(QVariant rpc_data)
    {
        auto json_result = rpc_data.toJsonObject();
        if (json_result.contains("reason"))
        {
            auto reason = json_result["reason"].toString();
            if (!reason.isEmpty())
            {
                if (reason.contains("Checksum verification failed"))
                {
                    reason                     = tr("Checksum verification failed for %1.").arg(get_current_ticker());
                    json_result["convertible"] = false;
                }
                else if (reason.contains("Invalid address checksum"))
                {
                    reason =
                        tr("Invalid checksum for %1. Click the button to convert to mixed case address.").arg(json_result["ticker"].toString());
                    json_result["convertible"]       = true;
                    json_result["to_address_format"] = QJsonObject{{"format", "mixedcase"}};
                }
                else if (reason.contains("Cashaddress address format activated for BCH, but legacy format used instead. Try to call 'convertaddress'"))
                {
                    reason =
                        tr("Legacy address used for %1. Click the button to convert to a Cashaddress.").arg(json_result["ticker"].toString());
                    json_result["to_address_format"] = QJsonObject{{"format", "cashaddress"}, {"network", "bitcoincash"}};
                    json_result["convertible"]       = true;
                }
                else if (reason.contains("Address must be prefixed with 0x"))
                {
                    reason                     = tr("%1 address must be prefixed with 0x").arg(json_result["ticker"].toString());
                    json_result["convertible"] = false;
                }
                else if (reason.contains("Invalid input length"))
                {
                    reason                     = tr("%1 address length is invalid, please use a valid address.").arg(json_result["ticker"].toString());
                    json_result["convertible"] = false;
                }
                else if (reason.toLower().contains("invalid address"))
                {
                    reason                     = tr("%1 address is invalid.").arg(json_result["ticker"].toString());
                    json_result["convertible"] = false;
                }
                else if (reason.contains("Invalid Checksum"))
                {
                    reason                     = tr("Invalid checksum.");
                    json_result["convertible"] = false;
                }
                else if (reason.contains("has invalid prefixes") or reason.contains("Expected a valid P2PKH or P2SH prefix"))
                {
                    reason = tr("%1 address has invalid prefixes.").arg(json_result["ticker"].toString());
                }
                else
                {
                    reason                     = tr("Backend error: %1").arg(reason);
                    json_result["convertible"] = false;
                }
                json_result["reason"] = reason;
            }
        }
        m_validate_address_result = json_result;
        emit validateAddressDataChanged();
    }

    QVariant
    wallet_page::get_coin_enabling_status() const
    {
        return m_coin_enabling_status.get();
    }

    void
    wallet_page::set_coin_enabling_status(QVariant rpc_data)
    {
        m_coin_enabling_status = rpc_data.toJsonObject();
        emit coinEnablingStatusChanged();
    }

    QVariant
    wallet_page::get_rpc_claiming_data() const
    {
        return m_claiming_rpc_result.get();
    }

    void
    wallet_page::set_rpc_claiming_data(QVariant rpc_data)
    {
        m_claiming_rpc_result = rpc_data.toJsonObject();
        emit claimingRpcDataChanged();
    }


    QVariant
    wallet_page::get_rpc_claiming_faucet_data() const
    {
        return m_claiming_rpc_faucet_result.get();
    }

    void
    wallet_page::set_rpc_claiming_faucet_data(QVariant rpc_data)
    {
        m_claiming_rpc_faucet_result = rpc_data.toJsonObject();
        emit claimingFaucetRpcDataChanged();
    }

    QString
    wallet_page::get_rpc_broadcast_data() const
    {
        return m_broadcast_rpc_result.get();
    }

    void
    wallet_page::set_rpc_broadcast_data(QString rpc_data)
    {
        m_broadcast_rpc_result = rpc_data;
        emit broadcastDataChanged();
    }

    QVariant
    wallet_page::get_rpc_send_data() const
    {
        return m_send_rpc_result.get();
    }

    void
    wallet_page::set_rpc_send_data(QVariant rpc_data)
    {
        m_send_rpc_result = rpc_data.toJsonObject();
        emit sendDataChanged();
    }

    bool
    wallet_page::has_auth_succeeded() const
    {
        return m_auth_succeeded;
    }

    bool
    wallet_page::is_send_available()
    {
        return m_send_available;
    }

    QString
    wallet_page::get_send_availability_state()
    {
        return m_send_availability_state;
    }

    bool
    wallet_page::is_current_ticker_fees_coin_enabled()
    {
        return m_current_ticker_fees_coin_enabled;
    }

    bool
    wallet_page::is_page_open() const
    {
        return m_page_open;
    }

    void
    wallet_page::set_page_open(bool value)
    {
        m_page_open = value;
        emit isPageOpenChanged();
    }
} // namespace atomic_dex

//! Public api
namespace atomic_dex
{
    void
    wallet_page::refresh_ticker_infos()
    {
        emit tickerInfosChanged();
    }

    void
    wallet_page::send(const QString& address, const QString& amount, bool max, bool with_fees, QVariantMap fees_data, const QString& memo)
    {
        //! Preparation
        this->set_send_busy(true);
        nlohmann::json     batch      = nlohmann::json::array();
        auto&              mm2_system = m_system_manager.get_system<mm2_service>();
        const auto&        ticker     = mm2_system.get_current_ticker();
        auto               coin_info = mm2_system.get_coin_info(ticker);

        if (coin_info.is_zhtlc_family)
        {
            t_withdraw_init_request withdraw_init_req{.coin = ticker, .to = address.toStdString(), .amount = max ? "0" : amount.toStdString(), .memo = memo.toStdString(), .max = max};

            if (with_fees)
            {
                qDebug() << fees_data;
                auto json_fees    = nlohmann::json::parse(QString(QJsonDocument(QVariant(fees_data).toJsonObject()).toJson()).toStdString());
                withdraw_init_req.fees = t_withdraw_init_fees{
                    .type      = "UtxoFixed",
                    .amount    = json_fees.at("fees_amount").get<std::string>()
                };
            }
            nlohmann::json json_data = mm2::template_request("task::withdraw::init", true);

            mm2::to_json(json_data, withdraw_init_req);

            batch.push_back(json_data);
            std::string amount_std = amount.toStdString();

            if (max)
            {
                std::error_code ec;
                amount_std = mm2_system.my_balance(ticker, ec);
            }

            auto answer_functor = [this, coin_info, ticker, amount_std](web::http::http_response resp)
            {
                const auto& settings_system     = m_system_manager.get_system<settings_page>();
                const auto& global_price_system = m_system_manager.get_system<global_price_service>();
                const auto& current_fiat        = settings_system.get_current_fiat().toStdString();
                auto            answers        = mm2::basic_batch_answer(resp);

                if (answers[0].contains("result"))
                {
                    if (answers[0]["result"].contains("task_id"))
                    {
                        auto task_id = answers[0].at("result").at("task_id").get<std::int8_t>();
                        {
                            SPDLOG_DEBUG("Task ID: {}", task_id);
                            using namespace std::chrono_literals;
                            auto&              mm2_system = m_system_manager.get_system<mm2_service>();
                            static std::size_t z_nb_try      = 1;
                            static std::size_t loop_limit    = 600;
                            nlohmann::json     z_error       = nlohmann::json::array();
                            nlohmann::json     z_batch_array = nlohmann::json::array();
                            QString            z_status;
                            t_withdraw_status_request z_request{.task_id = task_id};

                            nlohmann::json j = mm2::template_request("task::withdraw::status", true);
                            mm2::to_json(j, z_request);
                            z_batch_array.push_back(j);

                            do {
                                pplx::task<web::http::http_response> z_resp_task = mm2_system.get_mm2_client().async_rpc_batch_standalone(z_batch_array);
                                web::http::http_response             z_resp      = z_resp_task.get();
                                auto                                 z_answers   = mm2::basic_batch_answer(z_resp);
                                z_error = z_answers;
                                z_status = QString::fromStdString(z_answers[0].at("result").at("status").get<std::string>());

                                SPDLOG_DEBUG("[{}/{}] Waiting for {} withdraw status [{}]...", z_nb_try, loop_limit, ticker, z_status.toUtf8().constData());
                                if (z_status == "Ok")
                                {
                                    break;
                                }
                                else
                                {
                                    set_withdraw_status("Generating transaction");
                                }
                                std::this_thread::sleep_for(2s);
                                z_nb_try += 1;

                            } while (z_nb_try < loop_limit);

                            try {
                                if (z_error[0].at("result").at("details").contains("error"))
                                {
                                    SPDLOG_DEBUG("Error zhtlc withdraw_status {}: {} ", ticker, z_status.toUtf8().constData());
                                    z_status   = QString::fromStdString(z_error[0].at("result").at("details").at("error").get<std::string>());
                                    set_withdraw_status(z_status);
                                }
                                else if (z_nb_try == loop_limit)
                                {
                                    // TODO: Handle this case.
                                    // There could be no error message if scanning takes too long.
                                    // Either we force disable here, or schedule to check on it later
                                    SPDLOG_DEBUG("Exited zhtlc withdraw loop after 120 tries");
                                    SPDLOG_DEBUG("Bad answer for [{}] zhtlc withdraw_status: {}", ticker, z_error[0].dump(4));
                                    set_withdraw_status("Timed out");
                                }
                                else
                                {
                                    auto           withdraw_answer      = mm2::rpc_process_answer_batch<t_withdraw_status_answer>(z_error[0], "task::withdraw::status");
                                    nlohmann::json j_out                = nlohmann::json::object();
                                    j_out["withdraw_answer"]            = z_error[0]["result"]["details"];
                                    j_out.at("withdraw_answer")["date"] = withdraw_answer.result.value().timestamp_as_date;

                                    // Add total amount in fiat currency.
                                    if (coin_info.coinpaprika_id == "test-coin")
                                    {
                                        j_out["withdraw_answer"]["total_amount_fiat"] = "0";
                                    }
                                    else
                                    {
                                        j_out["withdraw_answer"]["total_amount_fiat"] = global_price_system.get_price_as_currency_from_amount(current_fiat, ticker, amount_std);
                                    }

                                    // Add fees amount.
                                    if (j_out.at("withdraw_answer").at("fee_details").contains("total_fee") && !j_out.at("withdraw_answer").at("fee_details").contains("amount"))
                                    {
                                        j_out["withdraw_answer"]["fee_details"]["amount"] = j_out["withdraw_answer"]["fee_details"]["total_fee"];
                                    }
                                    if (j_out.at("withdraw_answer").at("fee_details").contains("miner_fee") && !j_out.at("withdraw_answer").at("fee_details").contains("amount"))
                                    {
                                        j_out["withdraw_answer"]["fee_details"]["amount"] = j_out["withdraw_answer"]["fee_details"]["miner_fee"];
                                    }

                                    // Add fees amount in fiat currency.
                                    auto fee = j_out["withdraw_answer"]["fee_details"]["amount"].get<std::string>();
                                    if (coin_info.coinpaprika_id == "test-coin")
                                    {
                                        j_out["withdraw_answer"]["fee_details"]["amount_fiat"] = "0";
                                    }
                                    else
                                    {
                                        j_out["withdraw_answer"]["fee_details"]["amount_fiat"] =
                                            global_price_system.get_price_as_currency_from_amount(current_fiat, coin_info.fees_ticker, fee);
                                    }
                                    this->set_rpc_send_data(nlohmann_json_object_to_qt_json_object(j_out));
                                    set_withdraw_status("Complete");
                                }
                                z_nb_try = 0;
                            }
                            catch (const std::exception& error)
                            {
                                set_withdraw_status(QString::fromStdString(error.what()));
                                SPDLOG_ERROR("exception caught in zhtlc withdraw_status: {}", error.what());
                            }
                        }
                    }
                }
                else
                {
                    std::string body                = TO_STD_STR(resp.extract_string(true).get());
                    auto error_json = QJsonObject({{"error_code", resp.status_code()}, {"error_message", QString::fromStdString(body)}});
                    this->set_rpc_send_data(error_json);
                }
                this->set_send_busy(false);
            };

            auto error_functor = [this](pplx::task<void> previous_task)
            {
                try
                {
                    previous_task.wait();
                }
                catch (const std::exception& e)
                {
                    SPDLOG_ERROR("error caught in send: {}", e.what());
                    auto error_json = QJsonObject({{"error_code", 500}, {"error_message", QString::fromStdString(e.what())}});
                    this->set_rpc_send_data(error_json);
                    this->set_send_busy(false);
                }
            };

            //! Process
            mm2_system.get_mm2_client().async_rpc_batch_standalone(batch).then(answer_functor).then(error_functor);

        }
        else
        {
            t_withdraw_request withdraw_req{
                .coin = ticker,
                .to = address.toStdString(),
                .amount = max ? "0" : amount.toStdString(),
                .memo = memo.toStdString(),
                .max = max
            };

            if (with_fees)
            {
                qDebug() << fees_data;
                auto json_fees    = nlohmann::json::parse(QString(QJsonDocument(QVariant(fees_data).toJsonObject()).toJson()).toStdString());
                withdraw_req.fees = t_withdraw_fees{
                    .type      = "UtxoFixed",
                    .amount    = json_fees.at("fees_amount").get<std::string>(),
                    .gas_price = json_fees.at("gas_price").get<std::string>(),
                    .gas_limit = json_fees.at("gas_limit").get<int>()};
                if (coin_info.coin_type == CoinType::ERC20)
                {
                    withdraw_req.fees->type = "EthGas";
                }
                else if (coin_info.coin_type == CoinType::QRC20)
                {
                    withdraw_req.fees->type = "Qrc20Gas";
                }
                else if (coin_info.has_parent_fees_ticker)
                {
                    withdraw_req.fees->type = "otherGas";
                }
            }
            nlohmann::json json_data = mm2::template_request("withdraw", true);
            mm2::to_json(json_data, withdraw_req);
            // SPDLOG_DEBUG("final json: {}", json_data.dump(4));
            batch.push_back(json_data);

            std::string amount_std = amount.toStdString();
            if (max)
            {
                std::error_code ec;
                amount_std = mm2_system.my_balance(ticker, ec);
            }

            //! Answer
            auto answer_functor = [this, coin_info, ticker, amount_std](web::http::http_response resp)
            {
                const auto& settings_system     = m_system_manager.get_system<settings_page>();
                const auto& global_price_system = m_system_manager.get_system<global_price_service>();
                const auto& current_fiat        = settings_system.get_current_fiat().toStdString();
                std::string body                = TO_STD_STR(resp.extract_string(true).get());

                if (resp.status_code() == 200 && body.find("error") == std::string::npos)
                {
                    auto           answers              = nlohmann::json::parse(body);
                    auto           withdraw_answer      = mm2::rpc_process_answer_batch<t_withdraw_answer>(answers[0], "withdraw");
                    nlohmann::json j_out                = nlohmann::json::object();
                    j_out["withdraw_answer"]            = answers[0]["result"];
                    j_out.at("withdraw_answer")["date"] = withdraw_answer.result.value().timestamp_as_date;

                    // Add total amount in fiat currency.
                    if (coin_info.coinpaprika_id == "test-coin")
                    {
                        j_out["withdraw_answer"]["total_amount_fiat"] = "0";
                    }
                    else
                    {
                        j_out["withdraw_answer"]["total_amount_fiat"] = global_price_system.get_price_as_currency_from_amount(current_fiat, ticker, amount_std);
                    }

                    // Add fees amount.
                    if (j_out.at("withdraw_answer").at("fee_details").contains("total_fee") && !j_out.at("withdraw_answer").at("fee_details").contains("amount"))
                    {
                        j_out["withdraw_answer"]["fee_details"]["amount"] = j_out["withdraw_answer"]["fee_details"]["total_fee"];
                    }
                    if (j_out.at("withdraw_answer").at("fee_details").contains("miner_fee") && !j_out.at("withdraw_answer").at("fee_details").contains("amount"))
                    {
                        j_out["withdraw_answer"]["fee_details"]["amount"] = j_out["withdraw_answer"]["fee_details"]["miner_fee"];
                    }

                    // Add fees amount in fiat currency.
                    auto fee = j_out["withdraw_answer"]["fee_details"]["amount"].get<std::string>();
                    if (coin_info.coinpaprika_id == "test-coin")
                    {
                        j_out["withdraw_answer"]["fee_details"]["amount_fiat"] = "0";
                    }
                    else
                    {
                        j_out["withdraw_answer"]["fee_details"]["amount_fiat"] =
                            global_price_system.get_price_as_currency_from_amount(current_fiat, coin_info.fees_ticker, fee);
                    }

                    this->set_rpc_send_data(nlohmann_json_object_to_qt_json_object(j_out));
                }
                else
                {
                    auto error_json = QJsonObject({{"error_code", resp.status_code()}, {"error_message", QString::fromStdString(body)}});
                    this->set_rpc_send_data(error_json);
                }
                this->set_send_busy(false);
            };

            auto error_functor = [this](pplx::task<void> previous_task)
            {
                try
                {
                    previous_task.wait();
                }
                catch (const std::exception& e)
                {
                    SPDLOG_ERROR("error caught in send: {}", e.what());
                    auto error_json = QJsonObject({{"error_code", 500}, {"error_message", QString::fromStdString(e.what())}});
                    this->set_rpc_send_data(error_json);
                    this->set_send_busy(false);
                }
            };

            //! Process
            mm2_system.get_mm2_client().async_rpc_batch_standalone(batch).then(answer_functor).then(error_functor);
        }
    }

    void
    wallet_page::broadcast(const QString& tx_hex, bool is_claiming, bool is_max, const QString& amount)
    {
#if defined(__APPLE__) || defined(WIN32) || defined(_WIN32)
        QSettings& settings = this->entity_registry_.ctx<QSettings>();
        if (settings.value("2FA").toBool())
        {
            antara::gaming::core::evaluate_authentication(
                "Password to send funds is required", [=](bool is_auth) { broadcast_on_auth_finished(is_auth, tx_hex, is_claiming, is_max, amount); });
        }
        else
        {
            broadcast_on_auth_finished(true, tx_hex, is_claiming, is_max, amount);
        }
#else
        broadcast_on_auth_finished(true, tx_hex, is_claiming, is_max, amount);
#endif
    }

    void
    wallet_page::broadcast_on_auth_finished(bool is_auth, const QString& tx_hex, bool is_claiming, bool is_max, const QString& amount)
    {
        if (!is_auth)
        {
            m_auth_succeeded = false;
            emit auth_succeededChanged();
            return;
        }
        m_auth_succeeded = true;
        emit auth_succeededChanged();
        this->set_rpc_broadcast_data("");
        this->set_broadcast_busy(true);
        auto&               mm2_system = m_system_manager.get_system<mm2_service>();
        const auto&         ticker     = mm2_system.get_current_ticker();
        nlohmann::json      batch      = nlohmann::json::array();
        t_broadcast_request broadcast_request{.tx_hex = tx_hex.toStdString(), .coin = ticker};
        nlohmann::json      json_data = mm2::template_request("send_raw_transaction");
        mm2::to_json(json_data, broadcast_request);
        batch.push_back(json_data);

        //! Answer
        auto answer_functor = [this, is_claiming, is_max, amount](web::http::http_response resp)
        {
            std::string body = TO_STD_STR(resp.extract_string(true).get());
            if (resp.status_code() == 200)
            {
                auto&       mm2_system = m_system_manager.get_system<mm2_service>();
                const auto& ticker     = mm2_system.get_current_ticker();
                auto        answers    = nlohmann::json::parse(body);
                // SPDLOG_INFO("broadcast answer: {}", answers.dump(4));
                if (answers[0].contains("tx_hash"))
                {
                    this->set_rpc_broadcast_data(QString::fromStdString(answers[0].at("tx_hash").get<std::string>()));
                    if (mm2_system.is_pin_cfg_enabled() && (not is_claiming && is_max))
                    {
                        mm2_system.reset_fake_balance_to_zero(ticker);
                    }
                    else if (mm2_system.is_pin_cfg_enabled() && (not is_claiming && not is_max))
                    {
                        mm2_system.decrease_fake_balance(ticker, amount.toStdString());
                    }
                    mm2_system.fetch_infos_thread();
                }
                else
                {
                    this->set_rpc_broadcast_data(QString::fromStdString(body));
                }
            }
            else
            {
                this->set_rpc_broadcast_data(QString::fromStdString(body));
            }
            this->set_broadcast_busy(false);
        };

        auto error_functor = [this](pplx::task<void> previous_task)
        {
            try
            {
                previous_task.wait();
            }
            catch (const std::exception& e)
            {
                SPDLOG_ERROR("error caught in broadcast finished: {}", e.what());
                this->set_rpc_broadcast_data(QString::fromStdString(e.what()));
                this->set_broadcast_busy(false);
            }
        };

        mm2_system.get_mm2_client().async_rpc_batch_standalone(batch).then(answer_functor).then(error_functor);
    }

    void
    wallet_page::claim_rewards()
    {
        this->set_claiming_is_busy(true);
        nlohmann::json     batch      = nlohmann::json::array();
        auto&              mm2_system = m_system_manager.get_system<mm2_service>();
        std::error_code    ec;
        t_withdraw_request withdraw_req{.coin = "KMD", .to = mm2_system.address("KMD", ec), .amount = "0", .max = true};
        nlohmann::json     json_data = mm2::template_request("withdraw", true);
        mm2::to_json(json_data, withdraw_req);
        batch.push_back(json_data);
        json_data = mm2::template_request("kmd_rewards_info");
        batch.push_back(json_data);

        auto answer_functor = [this](web::http::http_response resp)
        {
            std::string body = TO_STD_STR(resp.extract_string(true).get());
            // SPDLOG_DEBUG("resp claiming: {}", body);
            if (resp.status_code() == static_cast<web::http::status_code>(antara::app::http_code::ok) && body.find("error") == std::string::npos)
            {
                auto           answers              = nlohmann::json::parse(body);
                auto           withdraw_answer      = mm2::rpc_process_answer_batch<t_withdraw_answer>(answers[0], "withdraw");
                nlohmann::json j_out                = nlohmann::json::object();
                j_out["withdraw_answer"]            = answers[0]["result"];
                j_out.at("withdraw_answer")["date"] = withdraw_answer.result.value().timestamp_as_date;
                auto kmd_rewards_answer             = mm2::process_kmd_rewards_answer(answers[1]);
                j_out["kmd_rewards_info"]           = kmd_rewards_answer.result;
                this->set_rpc_claiming_data(nlohmann_json_object_to_qt_json_object(j_out));
            }
            else
            {
                auto error_json = QJsonObject({{"error_code", resp.status_code()}, {"error_message", QString::fromStdString(body)}});
                this->set_rpc_claiming_data(error_json);
            }
            this->set_claiming_is_busy(false);
        };

        auto error_functor = [this](pplx::task<void> previous_task)
        {
            try
            {
                previous_task.wait();
            }
            catch (const std::exception& e)
            {
                SPDLOG_ERROR("error caught in claim_rewards: {}", e.what());
                auto error_json = QJsonObject({{"error_code", 500}, {"error_message", QString::fromStdString(e.what())}});
                this->set_rpc_claiming_data(error_json);
                this->set_claiming_is_busy(false);
            }
        };

        mm2_system.get_mm2_client().async_rpc_batch_standalone(batch).then(answer_functor).then(error_functor);
    }

    void
    wallet_page ::claim_faucet()
    {
        const auto&                mm2_system = m_system_manager.get_system<mm2_service>();
        const auto&                ticker     = mm2_system.get_current_ticker();
        const auto&                coin_info  = mm2_system.get_coin_info(ticker);
        std::error_code            ec;
        faucet::api::claim_request claim_request{.coin_name = coin_info.ticker, .wallet_address = mm2_system.address(ticker, ec)};

        this->set_claiming_faucet_is_busy(true);
        faucet::api::claim(claim_request)
            .then(
                [this](web::http::http_response resp)
                {
                    auto claim_result = faucet::api::get_claim_result(resp);
                    this->set_rpc_claiming_faucet_data(
                        QJsonObject({{"message", QString::fromStdString(claim_result.message)}, {"status", QString::fromStdString(claim_result.status)}}));
                    this->set_claiming_faucet_is_busy(false);
                })
            .then(&handle_exception_pplx_task);
    }

    transactions_model*
    wallet_page::get_transactions_mdl() const
    {
        return m_transactions_mdl;
    }

    void
    wallet_page::on_ticker_balance_updated(const ticker_balance_updated&)
    {
        refresh_ticker_infos();
    }

    void
    wallet_page::on_tx_fetch_finished(const tx_fetch_finished& evt)
    {
        if (!evt.with_error && QString::fromStdString(evt.ticker) == get_current_ticker())
        {
            std::error_code ec;
            const auto& settings         = m_system_manager.get_system<settings_page>();
            t_transactions  transactions = m_system_manager.get_system<mm2_service>().get_tx_history(ec);
            t_transactions  to_init;
            if (settings.is_spamfilter_enabled())
            {
                for (auto&& cur_tx: transactions)
                {
                    if (safe_float(cur_tx.total_amount) != 0)
                    {
                        to_init.push_back(cur_tx);
                    }
                }
            }
            else
            {
                to_init = transactions;
            }
            if (m_transactions_mdl->rowCount() == 0)
            {
                //! insert all transactions
                m_transactions_mdl->init_transactions(to_init);
            }
            else
            {
                //! Update tx (only unconfirmed) or insert (new tx)
                m_transactions_mdl->update_or_insert_transactions(to_init);
            }
            if (ec)
            {
                this->set_tx_fetching_failed(true);
            }
            else
            {
                this->set_tx_fetching_failed(false);
            }
        }
        else
        {
            this->m_transactions_mdl->reset();
        }
        this->set_tx_fetching_busy(false);
    }

    void
    wallet_page::validate_address(QString address)
    {
        auto& mm2_system = m_system_manager.get_system<mm2_service>();
        if (mm2_system.is_mm2_running())
        {
            const auto& ticker = mm2_system.get_current_ticker();
            validate_address(address, QString::fromStdString(ticker));
        }
    }

    void
    wallet_page::validate_address(QString address, QString ticker)
    {
        // SPDLOG_INFO("validate_address: {} - ticker: {}", address.toStdString(), ticker.toStdString());
        auto& mm2_system = m_system_manager.get_system<mm2_service>();
        if (mm2_system.is_mm2_running())
        {
            std::error_code            ec;
            t_validate_address_request req{.coin = ticker.toStdString(), .address = address.toStdString()};
            this->set_validate_address_busy(true);
            nlohmann::json batch     = nlohmann::json::array();
            nlohmann::json json_data = mm2::template_request("validateaddress");
            mm2::to_json(json_data, req);
            batch.push_back(json_data);
            auto answer_functor = [this, ticker](web::http::http_response resp)
            {
                std::string body = TO_STD_STR(resp.extract_string(true).get());
                // SPDLOG_DEBUG("resp validateaddress: {}", body);
                nlohmann::json j_out = nlohmann::json::object();
                j_out["ticker"]      = ticker.toStdString();
                if (resp.status_code() == static_cast<web::http::status_code>(antara::app::http_code::ok))
                {
                    auto answers         = nlohmann::json::parse(body);
                    auto validate_answer = mm2::rpc_process_answer_batch<t_validate_address_answer>(answers[0], "validateaddress");
                    if (validate_answer.result.has_value())
                    {
                        auto res          = validate_answer.result.value();
                        j_out["is_valid"] = res.is_valid;
                        j_out["reason"]   = res.reason.value_or("");
                    }
                    else
                    {
                        if (!m_system_manager.get_system<mm2_service>().is_zhtlc_coin_ready(ticker.toStdString()))
                        {
                            j_out["reason"]   = "Validation error: Coin not fully enabled";
                        }
                        else
                        {
                            j_out["reason"]   = "Validation error: Unknown";
                        }

                        j_out["is_valid"] = false;
                    }
                }
                else
                {
                    j_out["is_valid"] = false;
                    j_out["reason"]   = "Validation error: Problem with connection";
                }
                this->set_validate_address_data(nlohmann_json_object_to_qt_json_object(j_out));
                this->set_validate_address_busy(false);
            };
            mm2_system.get_mm2_client().async_rpc_batch_standalone(batch).then(answer_functor).then(&handle_exception_pplx_task);
        }
    }

    void
    wallet_page::convert_address(QString from, QVariant to_address_format)
    {
        auto& mm2_system = m_system_manager.get_system<mm2_service>();
        if (mm2_system.is_mm2_running())
        {
            const auto& ticker = mm2_system.get_current_ticker();
            convert_address(from, QString::fromStdString(ticker), to_address_format);
        }
    }

    void
    wallet_page::convert_address(QString from, QString ticker, QVariant to_address_format)
    {
        auto& mm2_system = m_system_manager.get_system<mm2_service>();
        if (mm2_system.is_mm2_running())
        {
            QVariantMap               out         = to_address_format.value<QVariantMap>();
            auto                      address_fmt = nlohmann::json::parse(QJsonDocument::fromVariant(out).toJson().toStdString());
            t_convert_address_request req{.coin = ticker.toStdString(), .from = from.toStdString(), .to_address_format = address_fmt};
            this->set_convert_address_busy(true);
            nlohmann::json batch     = nlohmann::json::array();
            nlohmann::json json_data = mm2::template_request("convertaddress");
            mm2::to_json(json_data, req);
            batch.push_back(json_data);
            auto answer_functor = [this](web::http::http_response resp)
            {
                std::string body = TO_STD_STR(resp.extract_string(true).get());
                SPDLOG_DEBUG("resp convertaddress: {}", body);
                if (resp.status_code() == static_cast<web::http::status_code>(antara::app::http_code::ok))
                {
                    auto answers        = nlohmann::json::parse(body);
                    auto convert_answer = mm2::rpc_process_answer_batch<t_convert_address_answer>(answers[0], "convertaddress");
                    if (convert_answer.result.has_value())
                    {
                        auto res = QString::fromStdString(convert_answer.result.value().address);
                        this->set_converted_address(res);
                    }
                }
                this->set_convert_address_busy(false);
            };
            mm2_system.get_mm2_client().async_rpc_batch_standalone(batch).then(answer_functor).then(&handle_exception_pplx_task);
        }
    }

    QString
    wallet_page::get_withdraw_status() const
    {
        return m_withdraw_status.get();
    }

    void
    wallet_page::set_withdraw_status(QString status)
    {
        m_withdraw_status = status;
        emit withdrawStatusChanged();
    }

    QString
    wallet_page::get_converted_address() const
    {
        return m_converted_address.get();
    }

    void
    wallet_page::set_converted_address(QString converted_address)
    {
        m_converted_address = converted_address;
        emit convertedAddressChanged();
    }
} // namespace atomic_dex